# ACDA Portal: Hyrax/Hyku Alignment Reference

**Strategic Goal:** Align ACDA Portal with Samvera community standards (Hyrax, Hyku)  
**Current Status:** Harvested-data aggregator with Fedora backend (overengineered)  
**Target Status:** Community-standard Blacklight app with PostgreSQL backend

**Important Note:** ACDA is simpler than Hyrax (it's a discovery aggregator, not a repository). We're adopting Hyrax's **patterns**, not all of Hyrax's **features**. The alignment is for architecture simplicity and community consistency, not feature parity.

---

## Architecture Mapping: ACDA → Hyrax Pattern

### Current (Fedora-Based, Overengineered)
```
ACDA Record (ActiveFedora::Base)
├─ 38 RDF properties (most unused)
├─ PCDM file relationships (unnecessary complexity)
├─ Fedora LDP backend (preservation features not needed)
└─ Custom ActiveFedora::IndexingService
```

### Target (Simple Blacklight App, Hyrax-Inspired Patterns)
```
CongressionalRecord (ApplicationRecord)
├─ AR columns (10-15 fields: title, creator, date, links, etc.)
├─ has_many_attached :files (ActiveStorage for thumbnails/display images)
├─ PostgreSQL backend
└─ Standard AR → Solr indexing
```

---

## Gem Alignment with Hyrax

### Gems ACDA Already Has (Keep)
✅ **Active Search & Discovery**
- `blacklight` — Full-text search interface (same as Hyrax)
- `rsolr` — Solr client (same as Hyrax)
- `solrizer` — Schema configuration (same as Hyrax)

✅ **Import/Export**
- `bulkrax` — Metadata import/export (same as Hyrax, supports both AF & AR)

✅ **Authorization**
- `hydra-head` — Role/permission system (used by both Hyrax & ACDA)

✅ **Background Jobs**
- `whenever` — Cron scheduler (same as Hyrax/Hyku)

### Gems ACDA Should Add (From Hyrax)
📦 **`good_job`** (instead of Sidekiq)
- Used by Hyku (official Samvera multi-tenant reference implementation)
- PostgreSQL-backed (no Redis needed)
- Better Rails integration
- Simpler monitoring

📦 **`valkyrie`** (optional, for polymorphic storage)
- Hyrax abstraction layer for works
- Allows future storage swaps
- Not required for ACDA (AR is fine), but good long-term

### Gems ACDA Should Remove
❌ **`active-fedora`** → Use standard Rails AR
❌ **`sidekiq`** → Use good_job
❌ **`redis`** → Not needed (good_job uses PG)
❌ **`fcrepo_wrapper`** → No Fedora in dev

---

## Reference Implementations

### 1. Hyrax Core Models
**File:** `https://github.com/samvera/hyrax/blob/main/app/models/hyrax/work.rb`

**ACDA Equivalent:**
```ruby
# app/models/congressional_record.rb
class CongressionalRecord < ApplicationRecord
  include Hydra::AccessControls::Permissions  # Same as Hyrax
  
  # Files (like Hyrax works)
  has_many_attached :uploaded_files
  
  # Metadata (stored as AR columns)
  # title, creator, date, etc. as simple columns
  
  # Indexing callback (like Hyrax)
  after_save :reindex_solr
  after_destroy :remove_from_solr
end
```

**Key difference:** Hyrax uses Valkyrie abstraction; ACDA can use simple AR directly

---

### 2. Hyrax Indexer Pattern
**File:** `https://github.com/samvera/hyrax/blob/main/app/indexers/hyrax/indexer.rb`

**ACDA Equivalent:**
```ruby
# app/indexers/congressional_record_indexer.rb
class CongressionalRecordIndexer
  attr_reader :record
  
  def initialize(record)
    @record = record
  end
  
  def generate_solr_document
    {
      id: record.id,
      title_tesim: [record.title],
      creator_tesim: record.creator,  # array
      date_tesim: [record.date],
      # ... other fields
    }
  end
end
```

**Reference:** Hyrax's indexer pattern (simple mapper, no inheritance from framework)

---

### 3. Hyku Background Jobs
**File:** `https://github.com/samvera/hyku/tree/main/app/jobs`

**ACDA Equivalent:**
```ruby
# app/jobs/thumbnail_generation_job.rb
class ThumbnailGenerationJob < ApplicationJob
  queue_as :thumbnail
  
  def perform(record_id)
    record = CongressionalRecord.find(record_id)
    # Generate thumbnail
  end
end

# config/good_job.yml
# Same structure as Sidekiq, but backed by PG
```

**Note:** Job structure identical; only backend changes

---

### 4. Bulkrax + ActiveRecord Integration
**File:** `https://github.com/samvera/bulkrax/blob/main/app/factories/bulkrax/factory.rb`

**ACDA Factory:**
```ruby
# app/factories/bulkrax/congressional_record_factory.rb
class Bulkrax::CongressionalRecordFactory < Bulkrax::Factory
  def self.model_class
    CongressionalRecord
  end
  
  def create_attributes
    {
      title: parser.fetch_field_value(field: 'title'),
      creator: parser.fetch_field_value(field: 'creator'),
      # ... etc
    }
  end
end
```

**Key:** Bulkrax already supports AR models (not just AF)

---

## Migration Path: Step by Step

### Step 1: Study Hyrax Architecture
**Time: 2-3 days**
- Read Hyrax architecture wiki: https://github.com/samvera/hyrax/wiki/Architecture
- Clone Hyrax locally, run it
- Compare `app/models/hyrax/work.rb` with our `Acda` model
- Note indexer, job, and permission patterns

### Step 2: Study Hyku Good_job Integration
**Time: 1 day**
- Review Hyku's `config/good_job.yml`: https://github.com/samvera/hyku/blob/main/config/good_job.yml
- Review Hyku's job implementations
- Compare to our Sidekiq setup

### Step 3: Create AR Model Based on Hyrax Pattern
**Time: 2-3 days**
```ruby
# Follow Hyrax structure exactly:
class CongressionalRecord < ApplicationRecord
  # Permissions (from hydra-head, same as Hyrax)
  include Hydra::AccessControls::Permissions
  
  # Files (AR pattern, simple)
  has_many_attached :uploaded_files
  
  # Metadata (columns, simple)
  # ... (no RDF properties)
  
  # Callbacks
  before_create :prepare_record
  after_save :reindex_solr
  
  # Indexer
  def self.indexer
    CongressionalRecordIndexer
  end
end
```

### Step 4: Create Indexer Based on Hyrax Pattern
**Time: 1-2 days**
- Copy Hyrax's indexer approach
- No inheritance from framework
- Simple Ruby class with `generate_solr_document` method

### Step 5: Setup good_job (From Hyku)
**Time: 1 day**
```ruby
# Gemfile: add good_job
# config/good_job.yml: copy Hyku's structure
# config/application.rb: config.active_job.queue_adapter = :good_job
```

### Step 6: Create Database Schema (PostgreSQL)
**Time: 2-3 days**
```ruby
# db/migrate/create_congressional_records.rb
# Follow standard Rails patterns (columns, not properties)
```

### Step 7: Migrate Data (Fedora → PostgreSQL)
**Time: 3-5 days**
- Export from Fedora using custom Rake task
- Import to PostgreSQL
- Migrate files to ActiveStorage

### Step 8: Update Controllers/Views
**Time: 2-3 days**
- Replace `Acda` with `CongressionalRecord`
- Update views (mostly syntax changes)

### Step 9: Update Tests
**Time: 2-3 days**
- Simplify factories (no Fedora mocks needed)
- Update specs (standard Rails patterns)
- Tests now run 60% faster

### Step 10: Deploy to Staging & Test
**Time: 3-5 days**
- Parallel run (both stacks active)
- Compare search results
- Verify file access
- Load testing

---

## Gem List: Current vs. Target

### Current Stack (Fedora)
```ruby
gem 'rails', '~> 7.0.8'
gem 'active-fedora'           # ← REMOVE
gem 'hydra-head'
gem 'blacklight'
gem 'bulkrax'
gem 'sidekiq'                 # ← REMOVE
gem 'redis', '~> 4.0'         # ← REMOVE
gem 'whenever'
gem 'rsolr'
gem 'solrizer'
```

### Target Stack (PostgreSQL, Hyrax-Aligned)
```ruby
gem 'rails', '~> 7.0.8'       # or 7.1+
gem 'pg', '>= 0.18', '< 2.0'
gem 'hydra-head'              # Keep (permissions)
gem 'blacklight'              # Keep (search)
gem 'bulkrax'                 # Keep (imports)
gem 'good_job', '~> 3.0'      # ← ADD (jobs, like Hyku)
gem 'whenever'                # Keep (scheduler)
gem 'rsolr'                   # Keep (Solr)
gem 'solrizer'                # Keep (schema)
```

**Removed:** 3 gems (active-fedora, sidekiq, redis)  
**Added:** 1 gem (good_job)  
**Net change:** -2 gems, simpler stack

---

## Docker Changes: Align with Hyku

### Current (Fedora Stack)
```yaml
services:
  app: (Rails)
  web: (Puma)
  workers: (Sidekiq)
  fcrepo: (Fedora 6)
  db: (PostgreSQL)
  redis: (Redis)
  solr: (Solr)
```

### Target (Hyrax/Hyku Pattern)
```yaml
services:
  app: (Rails + good_job)
  web: (Puma, good_job inline)
  db: (PostgreSQL, good_job backend)
  solr: (Solr)
```

**Removed:** fcrepo, redis, separate workers service  
**Simplified:** Web service can handle jobs inline in development

---

## Community Resources to Reference

### Hyrax
- **Repository:** https://github.com/samvera/hyrax
- **Wiki:** https://github.com/samvera/hyrax/wiki
- **Architecture:** https://github.com/samvera/hyrax/wiki/Architecture
- **Models:** `app/models/hyrax/work.rb` (our `CongressionalRecord`)
- **Indexer:** `app/indexers/hyrax/indexer.rb` (our pattern)

### Hyku (Reference Deployment)
- **Repository:** https://github.com/samvera/hyku
- **good_job config:** `config/good_job.yml`
- **Jobs:** `app/jobs/` directory
- **Models:** `app/models/` (AR-based)

### Bulkrax
- **ActiveRecord Support:** https://github.com/samvera/bulkrax/blob/main/app/factories/
- **Documentation:** https://github.com/samvera/bulkrax/wiki/

### Valkyrie (Optional Future Reference)
- **For polymorphic storage:** https://github.com/samvera/valkyrie
- **Not needed for ACDA initially**, but good to know exists for future flexibility

---

## Samvera Community Standards We'll Adopt

✅ **PostgreSQL** for data storage (95% of active Samvera apps)  
✅ **ActiveRecord** for ORM (standard Rails)  
✅ **Blacklight** for search interface (community standard)  
✅ **Solr** for full-text indexing (community standard)  
✅ **Bulkrax** for imports (community standard)  
✅ **good_job** for background jobs (Hyku's choice, official Rails recommendation)  
✅ **ActiveStorage** for file management (Rails 6+)  
✅ **Hydra::AccessControls** for permissions (community standard)  
✅ **whenever** for scheduling (community standard)

---

## Code Examples from Hyrax We Can Adapt

### Example 1: Simple Work Model
**Hyrax:** `https://github.com/samvera/hyrax/blob/main/app/models/hyrax/work.rb`

**ACDA Adaptation:**
```ruby
class CongressionalRecord < ApplicationRecord
  include Hydra::AccessControls::Permissions
  
  has_many_attached :files
  
  validates :title, presence: true
  
  after_save do
    Sunspot.index!(self)
  end
  
  def to_solr
    CongressionalRecordIndexer.new(self).generate_solr_document
  end
end
```

### Example 2: Indexer
**Hyrax:** `https://github.com/samvera/hyrax/blob/main/app/indexers/hyrax/indexer.rb`

**ACDA Adaptation:**
```ruby
class CongressionalRecordIndexer
  attr_reader :record
  
  def initialize(record)
    @record = record
  end
  
  def generate_solr_document
    base_solr_document.tap do |doc|
      doc['title_tesim'] = [record.title]
      doc['creator_tesim'] = record.creator
      doc['has_image_file_bsi'] = record.files.any?
    end
  end
  
  private
  
  def base_solr_document
    {
      id: record.id,
      has_model_ssim: ['CongressionalRecord'],
    }
  end
end
```

### Example 3: Background Job
**Hyku:** `https://github.com/samvera/hyku/blob/main/app/jobs/`

**ACDA Adaptation:**
```ruby
class ThumbnailGenerationJob < ApplicationJob
  queue_as :thumbnail
  
  def perform(record_id)
    record = CongressionalRecord.find(record_id)
    return unless record.image_file.attached?
    
    # Generate thumbnail
    # ... logic ...
    
    record.update(thumbnail_generated_at: Time.current)
  end
end
```

---

## Development Workflow Alignment

### Running the App (Current → Target)

**Current:**
```bash
# Start Fedora, Redis, Solr manually or via docker-compose
docker-compose up
# In separate terminal: bundle exec sidekiq
# In another: rails s
# Tests require fcrepo + Solr running
```

**Target (Hyrax Pattern):**
```bash
# Start via docker-compose (no Fedora/Redis)
docker-compose up
# Rails s (good_job runs inline in dev)
# Tests run without external services (80% faster)
```

### Testing Approach (Hyrax Pattern)
```bash
# No Fedora/Solr needed for unit tests
bundle exec rspec spec/models/congressional_record_spec.rb  # FAST

# Feature specs use test Solr (already in Hyrax pattern)
bundle exec rspec spec/features/                            # Slower, but clean

# Integration tests use staging deployment
```

---

## Success Metrics: Alignment with Community

After modernization, ACDA Portal should:

- [ ] Use same ORMs as Hyrax (ActiveRecord)
- [ ] Use same job queue as Hyku (good_job)
- [ ] Use same permissions system (Hydra::AccessControls)
- [ ] Use same search as Hyrax (Blacklight + Solr)
- [ ] Use same import tool as community (Bulkrax)
- [ ] Use same database as 95% of Samvera (PostgreSQL)
- [ ] Follow same model patterns as Hyrax
- [ ] Have deployable Docker config similar to Hyku
- [ ] Onboard new developers via standard Rails skills (not PCDM/RDF expertise)
- [ ] Receive bug fixes/patches from community work (no fork maintenance)

---

## Next Steps

1. **Fork/Branch:** Create `feature/modernize-to-postgres` branch
2. **Study Phase:** Spend 1 week reading Hyrax/Hyku code
3. **Prototype Phase:** Create test PR with new AR model + indexer
4. **Parallel Phase:** Run Phase 1 (gem updates, schema, good_job config)
5. **Migration Phase:** Phases 2-6 from MODERNIZATION.md

---

## Notes

- This is not "abandoning Samvera" — it's **adopting Samvera's current best practices**
- Hyrax/Hyku are the reference implementations the community rallies around
- By aligning, ACDA becomes easier to maintain and more likely to receive community contributions
- The architecture is more portable (can run on any Rails host, not just Fedora servers)
- Hiring becomes easier (Rails devs understand this, Fedora experts are rare)

---

## Resources to Bookmark

- **Hyrax Architecture:** https://github.com/samvera/hyrax/wiki/Architecture
- **Hyku Deployment:** https://github.com/samvera/hyku/blob/main/docker-compose.yml
- **Bulkrax AR Support:** https://github.com/samvera/bulkrax/issues?q=ActiveRecord
- **good_job Docs:** https://github.com/bensheldon/good_job
- **Samvera Tech Roadmap:** https://samvera.atlassian.net/wiki
