# Partner Site Health Check — Fix

## Problem

ACDA links partner content using external URLs stored in the `EDM.preview` metadata field. When a partner site goes down, the previous implementation made **live HTTP requests to the partner server on every page render** to check if the URL was active (`is_active_url?` in `application_helper.rb`).

Each failed request triggered 3 retries with timeouts and sleeps between attempts, blocking a Rails thread for up to 33–45 seconds per request. On a search results page with multiple Hawaii records, this caused simultaneous thread exhaustion, taking the entire ACDA site down.

**Root cause confirmed via logs:**
```
E [2026-03-17T20:00:10] Attempt 1/3 failed for URL https://digital.library.manoa.hawaii.edu/iiif-img/74276/...: SSL_connect returned=1 errno=0 peeraddr=172.17.0.1:443 state=error: certificate verify failed
E [2026-03-17T20:00:11] Attempt 2/3 failed ...
E [2026-03-17T20:00:12] Attempt 3/3 failed ...
```

The request ID (`ae8c6c88-...`) confirmed this was happening **inside a web request**, blocking the Rails thread the entire time.

---

## Solution Overview

Replace synchronous server-side URL checking with a three-component system:

1. **Browser-side failure detection** — `onerror` on `<img>` tags detects when a partner image fails to load
2. **Domain health cache** — Redis stores which domains are currently down; render path only reads from Redis (~0.1ms), never makes HTTP calls
3. **Background recovery job** — `DomainRecoveryJob` monitors downed domains every 10 minutes and clears the Redis key when the domain recovers

### Design Principles

- **Optimistic default** — all domains assumed UP unless explicitly marked DOWN in Redis
- **Zero blocking on render** — `is_active_url?` is now a single Redis read, never an HTTP call
- **Browser handles detection** — partner image failures are detected client-side, not server-side
- **Self-healing** — recovery job runs only when needed, stops itself when domain recovers

---

## Architecture

```
RENDER PATH (always fast)
─────────────────────────────────────────────────────
Request comes in
  → is_active_url?(preview) → DomainHealthService.up?(url)
  → Sidekiq.redis { r.get("domain_down:hawaii.edu") }
      nil?   → domain UP   → render <img src="hawaii.edu/..." onerror="...">
      value? → domain DOWN → render local thumbnail or fallback icon

DETECTION PATH (browser, not Rails)
─────────────────────────────────────────────────────
Browser fails to load <img src="hawaii.edu/...">
  → onerror fires
  → this.onerror = null                          (prevent infinite loop)
  → fetch('/url_health/report_down?url=...', POST) (non-blocking)
  → this.src = '/thumb/record-id.jpg'            (instant fallback)

RECOVERY PATH (background job, self-terminating)
─────────────────────────────────────────────────────
DomainRecoveryJob runs every 10 minutes
  → ping domain root
  → still down? → reschedule self for 10 mins
  → back up?    → Redis.del("domain_down:hawaii.edu") → stop
```

---

## Flap Detection

To handle the edge case where a specific URL is broken on an otherwise healthy domain, a flap detection mechanism tracks unique URL failures per domain within a 15-minute window.

**Without flap detection:**
```
Broken URL → onerror → domain marked DOWN
→ recovery job pings root → root responds → domain marked UP
→ next render → broken URL rendered again → onerror again
→ infinite loop ♻️
```

**With flap detection:**
```
15 different URLs from same domain fail within 15 mins
→ domain locked for 1 hour (Redis TTL)
→ no recovery job enqueued
→ lock expires automatically after 1 hour
→ cycle resets
```

Same URL failing multiple times counts as **1 unique failure** (Redis set ignores duplicates).

---

## Files Changed

### New Files

| File | Purpose |
|---|---|
| `app/services/domain_health_service.rb` | Owns all domain health logic — reads/writes Redis |
| `app/jobs/domain_recovery_job.rb` | Background job that monitors downed domains and clears Redis on recovery |
| `app/controllers/url_health_controller.rb` | Receives browser `onerror` POST reports |

### Modified Files

| File | Change |
|---|---|
| `app/helpers/application_helper.rb` | Replaced blocking `is_active_url?` with Redis-only version; added `onerror_handler` |
| `config/routes.rb` | Added `POST /url_health/report_down` route |
| Image show partial | Added `onerror` handler to image tag |
| PDF show partial | Added `onerror` handler to image tag |

### Deleted Files

| File | Reason |
|---|---|
| `app/helpers/inactive_check_urls.txt` | Temporary workaround — replaced by this solution |

---

## Key Components

### `DomainHealthService`

```ruby
REDIS_KEY_PREFIX = 'domain_down:'.freeze
FLAP_THRESHOLD   = 15       # unique URL failures before locking
FLAP_WINDOW_TTL  = 15.minutes  # window for counting unique failures
FLAP_LOCK_TTL    = 1.hour      # how long domain stays locked after flap threshold
```

**Redis keys used:**

| Key | Type | Purpose |
|---|---|---|
| `domain_down:{domain}` | String | Marks domain as down; has TTL when flap-locked |
| `domain_failed_urls:{domain}` | Set | Tracks unique failed URLs per domain within window |

### `DomainRecoveryJob`

```ruby
RETRY_INTERVAL = 10.minutes  # how often to ping downed domain
CHECK_TIMEOUT  = 10          # seconds before HTTP check times out
```

- Pings domain root (`HEAD /`) to check recovery
- Self-reschedules if domain still down
- Stops itself when domain recovers
- Uses `sidekiq-unique-jobs` to prevent duplicate jobs per domain

### `onerror_handler`

```ruby
def onerror_handler(preview_url, fallback_path)
  report_url = "/url_health/report_down?url=#{CGI.escape(preview_url)}"
  "this.onerror=null; fetch('#{report_url}', {method:'POST'}); this.src='#{fallback_path}';"
end
```

Three steps execute in the browser when an image fails:
1. Remove `onerror` handler (prevents loop if fallback also fails)
2. Fire non-blocking POST to report the failure
3. Swap `src` to local fallback immediately

---

## Behavior Matrix

| Scenario | Before | After |
|---|---|---|
| Partner site fully down | Rails threads blocked 33–45s per record, site crashes | Browser detects failure, local thumbnail served, site unaffected |
| Partner site up, image loads | Live HTTP check on every render | One Redis read (~0.1ms), browser fetches image directly |
| Partner site recovers | Manual intervention required | `DomainRecoveryJob` detects recovery automatically within 10 mins |
| Single broken URL on healthy domain | Infinite retry loop | Flap detection — domain locked for 1hr after 15 unique failures |
| No local thumbnail available | Broken image icon | `no-image.png` served by `ImageViewerController` fallback |

---

## Testing

### Console verification

```ruby
# Mark domain as down
Sidekiq.redis { |r| r.set("domain_down:digital.library.manoa.hawaii.edu", Time.current.to_s) }

# Verify
DomainHealthService.up?("https://digital.library.manoa.hawaii.edu/test.jpg")
# => false

DomainHealthService.all_down_domains
# => ["digital.library.manoa.hawaii.edu"]

# Clear
DomainHealthService.mark_up!("digital.library.manoa.hawaii.edu")
```

### Flap detection verification

```ruby
# Seed 14 unique failures
domain = "digital.library.manoa.hawaii.edu"
flap_key = "domain_failed_urls:#{domain}"
14.times { |i| Sidekiq.redis { |r| r.sadd(flap_key, ["https://#{domain}/record-#{i}"]) } }
Sidekiq.redis { |r| r.expire(flap_key, 900) }

# Trigger 15th — should lock
DomainHealthService.mark_down!("https://#{domain}/record-15")

# Verify locked with TTL (no recovery job)
Sidekiq.redis { |r| r.ttl("domain_down:#{domain}") }
# => ~3600
```

### Browser testing

1. Block `digital.library.manoa.hawaii.edu` in DevTools → Network → Request Blocking
2. Load a search results page with Hawaii records
3. Observe in Network tab: `POST /url_health/report_down` fires
4. Observe: fallback thumbnail shown immediately
5. Reload page: local thumbnail served without attempting external URL

---

## Tradeoffs

| Tradeoff | Detail |
|---|---|
| First user sees broken image | One user, one time sees a brief broken image before `onerror` fires and fallback appears. Every subsequent user sees local thumbnail immediately. |
| Domain-level granularity | One broken URL marks entire domain as down. Flap detection mitigates infinite loops but records from healthy URLs on the same domain will show local thumbnails during lock period. |
| Recovery lag | Domain recovers but ACDA continues serving local thumbnails until `DomainRecoveryJob` runs (up to 10 mins). |

---

## Infrastructure Dependencies

- **Redis** — already present (required by Sidekiq). Accessed via `Sidekiq.redis` using `REDIS_URL_SIDEKIQ` env var.
- **Sidekiq** — already present. `DomainRecoveryJob` queued in `default` queue.
- **`sidekiq-unique-jobs`** — already present. Prevents duplicate recovery jobs per domain.
