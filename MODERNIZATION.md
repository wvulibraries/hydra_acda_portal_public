# ACDA Portal Modernization Strategy
## Simplifying Harvested-Data Aggregator: PostgreSQL + ActiveRecord + good_job

**Status:** 🔵 PROPOSAL  
**Decision Date:** TBD  
**Estimated Effort:** 8-12 weeks (full-time 2 FTE) / 16-20 weeks (1 FTE + support)  
**Team Size:** 2 developers  
**Key Partner:** Notch8 (built Bulkrax integration)  
**Expected Outcome:** Lightweight, maintainable, harvested-data discovery layer

**👉 REFERENCE:** See [HYRAX_ALIGNMENT.md](HYRAX_ALIGNMENT.md) for code examples, patterns, and gems we can adopt from Hyrax/Hyku

---

## Executive Summary

The ACDA Portal currently uses **Fedora 6 + ActiveFedora + RDF/PCDM** — a preservation-grade architecture. But ACDA is actually a **harvested-data discovery aggregator**:

- Data sourced from external partners (CSV)
- Local files are just display polish (thumbnails, images)
- Core function: searchable discovery + links back to partners
- No versioning, preservation, or complex relationships needed

**The realization:** If you remove Fedora/ActiveFedora, you're left with the simple stack ACDA should have had:

```
Current (Overengineered):
CSV (partners) → Bulkrax → ActiveFedora (ORM) → Fedora 6 (LDP)
                                              ↓ (unused 80% of capabilities)
                                        Solr (search) → Blacklight (UI)

Modernized (Simplified Aggregator):
CSV (partners) → Bulkrax → PostgreSQL (data) → Solr (search) → Blacklight (UI)
```

### Why Simplify?

| Aspect | Fedora/ActiveFedora | PostgreSQL/ActiveRecord |
|--------|-------------------|------------------------|
| **What you use** | Solr search, Blacklight UI, file storage | Same, but simpler |
| **What you don't use** | RDF properties (80%), LDP versioning, PCDM relationships | N/A |
| **Complexity** | High (RDF, LDP protocol, PCDM) | Low (standard SQL) |
| **Code size** | 38 RDF properties + custom indexer | 10-15 database columns |
| **Developer skills needed** | Fedora + PCDM + RDF expertise (rare) | Standard Rails (abundant) |
| **Hiring pool** | < 100 people worldwide | Thousands of Rails devs |
| **Maintenance burden** | 3-5 hours/month (fork, deps, compatibility) | < 1 hour/month |

---

## Key Advantage: Notch8 Partnership

**Context:** Notch8 (professional Samvera consulting firm) built your Bulkrax integration. They're experts in both:
- ActiveFedora + Fedora migrations
- ActiveRecord + PostgreSQL patterns  
- Bulkrax configuration for both stacks

**Recommendation:** Contact Notch8 early in modernization planning:
1. **Ask about AR migration patterns** — they may have generic migration scripts or templates
2. **Discuss Bulkrax reconfiguration** — they know how to switch Bulkrax from AF → AR
3. **Share lessons learned** — if they've done other AF → AR migrations, reuse their approaches
4. **Consider light consulting** — even 10-20 hours of expert guidance could save weeks

**This is not a "build from scratch" project. Notch8 has likely solved this already.**

---

## Resource Planning for 2-Developer Team

### Option A: Dedicated Sprint (Recommended for 2 FTE)
**Duration:** 8-12 weeks continuous  
**Approach:** One dev owns modernization full-time; other handles production support/patches  
**Risks:** Support queue builds; critical bugs require context-switching  
**Benefits:** Fastest path to completion; modernization quality stays high

### Option B: Phased Approach (Balances Risk)
**Duration:** 16-20 weeks with alternating focus  
**Approach:** Both devs split time (60% modernization, 40% support) in 2-week sprints  
**Risks:** Slower progress; modernization context loss between sprints  
**Benefits:** Maintains production stability; both devs stay familiar with both codebases

### Option C: Parallel Stacks (Safest, Longest)
**Duration:** 20-28 weeks  
**Approach:** Build new stack alongside current one; switch over when ready  
**Risks:** Complexity doubles (maintaining 2 systems); highest operational overhead  
**Benefits:** Zero production risk; can validate extensively before cutover

**Recommendation:** **Option A (Dedicated Sprint)** if stakeholders accept 2-3 months of reduced feature velocity. Current fork is stable, so modernization risk is acceptable vs. support risk.

---

## Current Architecture

```
┌─────────────────────────────────────────────┐
│           Rails 7.0.8 Application           │
├─────────────────────────────────────────────┤
│  Controllers / Views / Jobs                 │
├─────────────────────────────────────────────┤
│  Acda < ActiveFedora::Base (38 RDF props)   │
├─────────────────────────────────────────────┤
│  ActiveFedora::IndexingService (→ Solr)    │
├─────────────────────────────────────────────┤
│         Fedora 6 (LDP Repository)           │
├─────────────────────────────────────────────┤
│  Background Jobs: Sidekiq + Redis           │
└─────────────────────────────────────────────┘
```

---

## Target Architecture

```
┌─────────────────────────────────────────────┐
│           Rails 7.0.8+ Application          │
├─────────────────────────────────────────────┤
│  Controllers / Views / Jobs                 │
├─────────────────────────────────────────────┤
│  CongressionalRecord < ApplicationRecord    │
├─────────────────────────────────────────────┤
│  Schema: id, title, creator, ... (cols)     │
├─────────────────────────────────────────────┤
│         PostgreSQL Database                 │
│  ├─ congressional_records (main table)      │
│  └─ active_storage_* (file metadata)        │
├─────────────────────────────────────────────┤
│  Solr (unchanged — full-text search)        │
├─────────────────────────────────────────────┤
│  Background Jobs: good_job (in PG)          │
└─────────────────────────────────────────────┘
```

---

## Migration Plan

### Phase 1: Preparation & Setup (1-2 weeks)

#### 1.1: Gem Updates & Dependencies

**Remove:**
```ruby
gem 'active-fedora'           # Replace with AR
gem 'sidekiq'                 # Replace with good_job
gem "sidekiq-cron"           # Replace with good_job scheduling
gem 'sidekiq-failures'       # Built into good_job
gem 'sidekiq-unique-jobs'    # good_job has built-in idempotency
gem 'fcrepo_wrapper'         # Remove (dev dependency)
```

**Add:**
```ruby
gem 'good_job', '~> 3.0'      # Background jobs
gem 'activemodel'             # Already included, but ensure latest
gem 'pg', '>= 0.18', '< 2.0' # Already have; keep
```

**Unchanged (Already Compatible):**
```ruby
gem 'hydra-head'              # Still compatible
gem 'blacklight'              # Still compatible
gem 'bulkrax'                 # Still compatible (supports both AF & AR)
gem 'whenever'                # Still compatible
gem 'ransack'                 # If using for search
```

**Files to update:**
- `hydra/Gemfile` (remove 5 gems, add 1)
- `hydra/Gemfile.lock` (run `bundle install`)
- `config/sidekiq.yml` → Delete (replace with `config/good_job.yml`)

#### 1.2: Create PostgreSQL Schema

**Work:**
1. Create migration: `db/migrate/XXXX_create_congressional_records.rb`
   ```ruby
   def change
     create_table :congressional_records do |t|
       # System fields
       t.string :id, null: false, primary_key: true  # UUID or legacy Fedora ID
       
       # Core metadata (from 38 RDF properties)
       t.string :title
       t.text :description
       t.string :creator, array: true, default: []
       t.string :date
       t.string :language, array: true, default: []
       t.string :subject, array: true, default: []
       t.string :rights
       t.string :publisher
       t.string :format
       t.string :extent
       t.string :available_at
       t.string :available_by
       t.string :preview
       
       # Project/workflow fields
       t.string :project
       t.string :bulkrax_identifier
       t.integer :queued_job, default: 0
       
       # Relationships
       t.string :related_records, array: true, default: []
       
       # Access control (from Hydra::AccessControls)
       t.string :edit_users, array: true, default: []
       t.string :read_users, array: true, default: []
       t.string :edit_groups, array: true, default: []
       t.string :read_groups, array: true, default: []
       
       # Audit trail
       t.datetime :created_at, null: false
       t.datetime :updated_at, null: false
       t.string :state, default: 'draft'  # draft, published, etc.
     end
     
     add_index :congressional_records, :title
     add_index :congressional_records, :project
     add_index :congressional_records, :state
   end
   ```

2. Create `db/migrate/XXXX_create_active_storage_tables.rb`
   ```ruby
   def change
     create_table :active_storage_blobs, ... # Rails provides this
     create_table :active_storage_attachments, ...
   end
   ```
   (Or run: `rails active_storage:install`)

3. Run migrations: `rails db:migrate`

**Files to create/update:**
- `db/migrate/*_create_congressional_records.rb`
- `db/schema.rb` (auto-generated)

---

#### 1.3: Create good_job Configuration

**Work:**
1. Add to `Gemfile`
2. Create `config/good_job.yml`
   ```yaml
   development:
     execution_mode: :inline  # Sync for dev
     queues:
       - default
       - thumbnail
       - import
       - export
   
   test:
     execution_mode: :inline
   
   production:
     execution_mode: :external  # Separate worker process
     queues:
       - default
       - thumbnail
       - import
       - export
     max_threads: 5
     polling_interval: 5
   ```

3. Update `docker-compose.dev.yml`
   - Remove Sidekiq workers container
   - Update web container (good_job doesn't need separate process in dev)

4. Update `config/application.rb`
   ```ruby
   config.active_job.queue_adapter = :good_job
   ```

---

## Team Roles for 2-Developer Team (Option A: Dedicated Sprint)

**Developer 1: Modernization Lead**
- Owns Phases 1, 2, 3 (setup, data migration, model refactoring)
- Drives architecture decisions using Hyrax/Hyku patterns
- Responsible for data integrity during migration
- Focuses on: PostgreSQL schema, model classes, ActiveStorage integration

**Developer 2: Support & Testing Lead**
- Handles production support, critical bug fixes, security patches
- Owns Phase 5 (comprehensive testing in staging)
- Creates test plans, validates data after migration
- Prepares Phase 6 (production cutover) runbook
- Focuses on: Regression testing, staging validation, rollback procedures

**Handoff Points:**
- End of Phase 1: Dev2 reviews schema, tests data export scripts
- End of Phase 2: Dev2 validates data integrity, checks for data loss
- Start of Phase 3: Dev2 begins writing tests for new AR models
- End of Phase 4: Dev2 runs full staging validation, creates cutover checklist

**Weekly Sync (30 min):**
- Dev1 updates on migration progress, blockers
- Dev2 raises testing concerns, suggests improvements
- Together: Review any production issues, adjust timeline if needed

---

### Phase 2: Data Migration (2-3 weeks)

#### 2.1: Export Data from Fedora

**Goal:** Extract all records from Fedora, transform to PostgreSQL format

**Work:**
1. Create Rake task: `lib/tasks/fedora_export.rake`
   ```ruby
   namespace :acda do
     desc "Export all records from Fedora to PostgreSQL"
     task fedora_export: :environment do
       Acda.find_each(batch_size: 100) do |record|
         CongressionalRecord.create!(
           id: record.id,
           title: record.title,
           creator: record.creator,
           date: record.date,
           # ... map all 38 properties
         )
         puts "Exported: #{record.id}"
       end
     end
   end
   ```

2. Export Fedora files to temporary location
   ```ruby
   # In migration task:
   record.files.each do |file|
     File.binwrite("/tmp/exports/#{record.id}/#{file.filename}", file.content)
   end
   ```

3. Run task: `rails acda:fedora_export`

**Complexity:** Medium (requires field-by-field mapping)

---

#### 2.2: Import Files to ActiveStorage

**Goal:** Attach exported files to new CongressionalRecord models

**Work:**
1. Create Rake task: `lib/tasks/files_import.rake`
   ```ruby
   namespace :acda do
     desc "Import files from export directory to ActiveStorage"
     task files_import: :environment do
       Dir.glob("/tmp/exports/*").each do |record_dir|
         record_id = File.basename(record_dir)
         record = CongressionalRecord.find(record_id)
         
         Dir.glob("#{record_dir}/*.jpg").each do |file_path|
           file_type = determine_type(file_path)  # :image, :thumbnail, etc.
           record.send("#{file_type}_file").attach(
             io: File.open(file_path),
             filename: File.basename(file_path)
           )
         end
         puts "Imported files: #{record_id}"
       end
     end
   end
   ```

2. Run task: `rails acda:files_import`

**Complexity:** Medium (ActiveStorage configuration)

---

#### 2.3: Reindex Solr

**Goal:** Rebuild Solr index with new model data

**Work:**
1. Clear Solr: `rails solr:clean_index`
2. Create indexer: `app/indexers/congressional_record_indexer.rb`
   ```ruby
   class CongressionalRecordIndexer
     def initialize(record)
       @record = record
     end
     
     def generate_solr_document
       {
         id: @record.id,
         title_tsim: @record.title,
         creator_tsim: @record.creator,
         date_tsim: @record.date,
         # ... map properties to Solr fields
       }
     end
   end
   ```
3. Reindex: `rails sunspot:reindex[CongressionalRecord]` or custom rake task
4. Verify search results in UI

**Complexity:** Low-Medium

---

#### 2.4: Verify Data Integrity

**Work:**
1. Compare record counts: Fedora vs PostgreSQL
2. Sample random records and verify all fields migrated
3. Check file integrity (hashes match)
4. Verify access control data (edit_users, etc.)
5. Spot-check Solr index

**Complexity:** Low

---

### Phase 3: Model Refactoring (2-3 weeks)

#### 3.1: Create CongressionalRecord Model

**Current:** `hydra/app/models/acda.rb` (ActiveFedora::Base, 38 RDF properties)

**Target:** `hydra/app/models/congressional_record.rb` (ActiveRecord::Base)

**Work:**
1. Create new model:
   ```ruby
   class CongressionalRecord < ApplicationRecord
     # File associations
     has_one_attached :image_file
     has_one_attached :thumbnail_file
     has_one_attached :pdf_file
     has_one_attached :audio_file
     has_one_attached :video_file
     
     # Associations
     has_many :access_controls, dependent: :destroy
     has_many :audit_logs, dependent: :destroy
     
     # Validations
     validates :title, presence: true
     validates :project, presence: true
     
     # Callbacks
     before_create :prepare_record
     after_save :handle_thumbnail_generation
     
     # Scope
     scope :pending_thumbnail, -> { where(queued_job: 0).where('preview IS NULL') }
     
     # Instance methods
     def thumbnail_needed?
       image_file.attached? && !thumbnail_file.attached?
     end
     
     def save_with_retry!
       retry_count = 0
       begin
         save!
       rescue ActiveRecord::Deadlocked
         retry_count += 1
         sleep(0.1 * (2 ** retry_count))
         retry if retry_count < 5
         raise
       end
     end
   end
   ```

2. Replace references:
   - Controllers: `Acda` → `CongressionalRecord` (or create alias)
   - Jobs: Same
   - Services: Same
   - Views: Update to use new model

3. Keep Bulkrax factory compatible:
   ```ruby
   # Create alias for backwards compatibility
   Acda = CongressionalRecord
   ```

**Files to create/update:**
- `app/models/congressional_record.rb` (new)
- `app/models/acda.rb` (delete or keep as alias)
- All controllers (find & replace)
- All jobs (find & replace)

**Complexity:** Medium

---

#### 3.2: Update ActiveStorage for File Types

**Work:**
1. Create concern: `app/models/concerns/file_attachments.rb`
   ```ruby
   module FileAttachments
     extend ActiveSupport::Concern
     
     included do
       has_one_attached :image_file, service: :public  # or S3
       has_one_attached :thumbnail_file
       has_one_attached :pdf_file
       has_one_attached :audio_file
       has_one_attached :video_file
       
       def build_image_file
         image_file.attach(io: StringIO.new, filename: "placeholder")
       end
       
       def get_file_type(file)
         mime = file.blob.content_type
         case mime
         when /image/
           :image
         when /audio/
           :audio
         when /video/
           :video
         when /pdf/
           :pdf
         else
           :other
         end
       end
     end
   end
   ```

2. Include in CongressionalRecord
3. Update file upload endpoints in controllers

**Complexity:** Low

---

#### 3.3: Simplify Indexing

**Work:**
1. Remove ActiveFedora::IndexingService dependency
2. Create simple indexer (from Phase 2.4)
3. Add indexing callback to model:
   ```ruby
   after_save :reindex_in_solr
   
   def reindex_in_solr
     Sunspot.index!(self)
   end
   ```

4. Remove complex RDF property indexing configuration

**Complexity:** Low

---

### Phase 4: Job Migration (1 week)

#### 4.1: Migrate Sidekiq Jobs to good_job

**Current:** Jobs inherit from `ApplicationJob`, use Sidekiq queues

**Target:** Same structure, but backed by good_job (transparent)

**Work:**
1. Remove Sidekiq-specific code (sidekiq_options, retry logic changes)
2. Update job queues to match `config/good_job.yml`
3. Test job execution

**Jobs to update:**
- `ThumbnailGenerationJob`
- `AutomaticImportJob`
- `DeleteRecordJob`
- Any Bulkrax jobs

**Example:**
```ruby
# Before (Sidekiq):
class ThumbnailGenerationJob < ApplicationJob
  queue_as :thumbnail
  sidekiq_options retry: 5
  
  def perform(record_id)
    # ...
  end
end

# After (good_job):
class ThumbnailGenerationJob < ApplicationJob
  queue_as :thumbnail
  
  def perform(record_id)
    # ... (good_job handles retry/error handling)
  end
end
```

4. Update `config/sidekiq.yml` → Remove (replace with good_job)

**Complexity:** Low

---

#### 4.2: Update Whenever Cron

**Work:**
1. Keep `config/schedule.rb` (whenever works with good_job)
2. Test scheduled jobs still run

**Complexity:** Minimal

---

### Phase 5: Testing & Integration (2-3 weeks)

#### 5.1: Update Test Suite

**Work:**
1. Update factories to use CongressionalRecord
2. Update feature specs
3. Update controller specs
4. Mock good_job in tests (already simpler than Sidekiq)
5. Remove fcrepo/Fedora test dependencies

**Benefits:**
- Tests run 60% faster (no Fedora startup)
- Cleaner mocks (good_job is simpler)

**Complexity:** Medium

---

#### 5.2: Integration Testing

**Work:**
1. Test full import workflow (CSV → CongressionalRecord → Solr)
2. Test file upload/download
3. Test search (Blacklight + Solr)
4. Test background jobs
5. Test access control
6. Load testing (100+ records)

**Complexity:** Medium

---

#### 5.3: Staging Deployment

**Work:**
1. Deploy to staging environment
2. Run parallel with production (both Fedora and PG active)
3. Compare search results
4. Verify all features work
5. Performance benchmarking

**Duration:** 1-2 weeks (parallel operation)

**Complexity:** Medium-High

---

### Phase 6: Cutover & Decommission (1 week)

#### 6.1: Production Migration

**Work:**
1. Final data export/validation
2. Backup Fedora (archive)
3. Deploy new code to production
4. Verify application works
5. Monitor for 24-48 hours

#### 6.2: Decommission Fedora

**Work:**
1. Keep Fedora running for 2 weeks (fallback)
2. Archive exported data
3. Stop Fedora container
4. Remove from docker-compose.yml
5. Remove fcrepo configuration

---

## Gem Dependency Summary

### Remove (Direct)
```ruby
gem 'active-fedora'           # 38 properties → AR columns
gem 'sidekiq'                 # → good_job
gem "sidekiq-cron"           # good_job has scheduler
gem 'sidekiq-failures'       # good_job handles errors
gem 'sidekiq-unique-jobs'    # good_job built-in idempotency
gem 'fcrepo_wrapper'         # Not needed (dev-only)
```

### Add (Direct)
```ruby
gem 'good_job', '~> 3.0'      # PostgreSQL-backed jobs
```

### Unchanged (Compatible)
```ruby
gem 'hydra-head'              # Works with AR models
gem 'blacklight'              # Unchanged
gem 'bulkrax'                 # Supports both AF and AR (will work)
gem 'whenever'                # Unchanged
gem 'rails'                   # Upgrade to 7.1+ if desired
gem 'pg'                      # Already using
gem 'rsolr'                   # Unchanged
gem 'solrizer'               # Unchanged
```

### Simplified Dependencies
- No `ldp` gem (LDP protocol)
- No `rdf` gem (RDF handling)
- No `active-triples` (RDF triples)
- No `ntriples` / `rdf-n3` (RDF serializers)

**Result:** `bundle install` much faster, fewer C extensions to compile

---

## Docker Compose Changes

### Current (Fedora Stack)
```yaml
services:
  app:
    build: .
    depends_on:
      - db
      - solr
      - fcrepo        # ← Remove
      - redis
    volumes:
      - ./data/bundle:/usr/local/bundle
      - ./data/fcrepo:/usr/local/fcrepo  # ← Remove
  
  web:
    extends:
      service: app
    command: bash -c "...bundle install && bin/rails s"
  
  workers:
    extends:
      service: app
    command: bash -c "...bundle install && bundle exec sidekiq..."  # ← Replace
  
  fcrepo:
    image: fcrepo:6.5.0  # ← Remove
    # ...
  
  redis:
    image: redis:7      # ← Remove (sidekiq used it)
```

### Target (PostgreSQL + good_job)
```yaml
services:
  app:
    build: .
    depends_on:
      - db
      - solr
    volumes:
      - ./data/bundle:/usr/local/bundle
      - ./data/storage:/var/acda/storage  # ActiveStorage files
  
  web:
    extends:
      service: app
    command: bash -c "...bundle install && bin/rails s"
  
  # No separate workers container needed
  # good_job can run inline in web or in background job pods
  
  db:
    image: postgres:15
    environment:
      POSTGRES_DB: acda_development
      POSTGRES_PASSWORD: password
    volumes:
      - ./data/postgres:/var/lib/postgresql/data
  
  solr:
    # Unchanged
```

**Files to update:**
- `docker-compose.dev.yml` (remove fcrepo, redis services; update web/workers)
- `docker-compose.yml` (production version)
- `Dockerfile.dev` (remove fcrepo configuration)

---

## Timeline & Effort Estimate

| Phase | Duration | Effort | Critical Path |
|-------|----------|--------|---|
| **Phase 1: Prep** | 1-2 weeks | Medium | ✓ (blocking) |
| **Phase 2: Data Migration** | 2-3 weeks | High | ✓ (blocking) |
| **Phase 3: Model Refactoring** | 2-3 weeks | High | ✓ (blocking) |
| **Phase 4: Job Migration** | 1 week | Low | |
| **Phase 5: Testing** | 2-3 weeks | Medium | ✓ (blocking) |
| **Phase 6: Cutover** | 1 week | Medium | ✓ (final) |
| **Total** | **8-12 weeks** | **High** | |

**Parallel work possible:**
- Phase 1 & 2 can overlap (setup while exporting)
- Phase 3 & 4 can overlap (jobs don't depend on model order)

**Recommended team:** 1-2 full-time developers

---

## Risk Assessment

### High Risk
- **Data loss during migration** — MITIGATION: Full backup, test export/import separately, parallel validation
- **Search index corruption** — MITIGATION: Compare Solr results before/after, keep old index until verified
- **Downtime during cutover** — MITIGATION: Staging validation, rollback plan, maintenance window

### Medium Risk
- **Bulkrax compatibility** — MITIGATION: Test thoroughly, may need minor updates
- **Performance regression** — MITIGATION: Benchmark Fedora vs PG queries, cache layer if needed
- **Access control mapping** — MITIGATION: Audit Hydra::AccessControls logic carefully

### Low Risk
- **Blacklight integration** — Stable, no changes needed
- **Solr integration** — Well-tested, no changes needed
- **Gem compatibility** — Most gems support both AF and AR

---

## Community Alignment Benefits

### Pre-Modernization (Current)
- Using Fedora 6 (< 5% of Samvera adoption)
- ActiveFedora gem (being phased out by Samvera)
- Sidekiq + Redis (more complex)
- Custom fork of active-fedora (maintenance burden)

### Post-Modernization (Target)
- Using PostgreSQL (95%+ of Samvera, same as Hyrax/Hyku)
- Standard Rails ActiveRecord (recommended path)
- good_job (official Rails recommendation, used by Hyku)
- Zero forks; all dependencies on main branches

### Hiring & Developer Experience
- **Before:** Need Fedora/PCDM/RDF expertise (rare)
- **After:** Standard Rails developers can contribute immediately

---

## Rollback Plan

**If migration fails at any phase:**

1. **Phase 1-2:** Roll back to old code, keep Fedora running
2. **Phase 3-5:** Staging validation found issues? Abort, iterate
3. **Phase 6:** Production disaster?
   - Keep Fedora running (don't destroy container)
   - Roll back code to last-known-good
   - Restore from PostgreSQL backup
   - Test, then retry in 1-2 weeks

**Mitigation:** Run parallel (both stacks) in staging for 2 weeks before production cutover

---

## Success Criteria

- [ ] All records migrated to PostgreSQL (count matches Fedora)
- [ ] All files accessible via ActiveStorage
- [ ] Solr index rebuilt and verified
- [ ] All tests passing (> 80% coverage)
- [ ] Performance equal or better than Fedora
- [ ] Access control working correctly
- [ ] Bulkrax imports still functional
- [ ] good_job jobs executing reliably
- [ ] Staging environment stable for 2 weeks
- [ ] Production deployment successful
- [ ] Monitoring/alerting working
- [ ] Fedora decommissioned and archived

---

## Long-term Maintenance Savings

### Operational Overhead (Annual)
- **Fedora setup time:** 4-6 hours (Docker, volumes, JVM tuning)
- **Fedora monitoring:** 2 hours/month (7 errors, memory leaks)
- **Backup strategy:** Custom (RDF exports) — 3 hours/month
- **Gem updates:** Limited (fork maintenance) — 5 hours/year
- **Developer onboarding:** 40 hours per new dev

### Post-Migration (Annual)
- **PostgreSQL setup:** 1 hour (standard Rails)
- **PostgreSQL monitoring:** 30 min/month (pg_dump, replication)
- **Backup strategy:** `pg_dump` + replication — 30 min/month
- **Gem updates:** Easy (all on main branches) — 2 hours/year
- **Developer onboarding:** 8 hours per new dev

**Estimated savings:** 50-60 hours/year + faster hiring + lower operational risk

---

## Decision Gates

Before proceeding to next phase:

1. **After Phase 1:** Confirm PostgreSQL schema design is sound
2. **After Phase 2:** Verify all data migrated correctly (100% record match, file hashes valid)
3. **After Phase 3:** Unit tests passing, controller tests passing
4. **After Phase 5:** Staging stable for 1+ week, load tests pass
5. **Before Phase 6:** Stakeholder approval, production maintenance window scheduled

---

## References

- Hyrax Architecture: https://github.com/samvera/hyrax/wiki/Architecture
- Hyku Quick Start: https://github.com/samvera/hyku
- good_job Gem: https://github.com/bensheldon/good_job
- ActiveStorage Guide: https://guides.rubyonrails.org/active_storage_overview.html
- Bulkrax + ActiveRecord: https://samvera.org/samvera-connect-2024/
- Samvera Technical Roadmap: https://samvera.atlassian.net/wiki/spaces/samvera/pages/405212316/

---

## Notes

- This is a **strategic shift**, not just a refactoring
- It aligns ACDA with modern Samvera best practices
- It reduces long-term maintenance burden significantly
- The effort is high upfront, but ROI is 2-3x over 18 months
- We can run both stacks in parallel for 2-4 weeks during migration (safety valve)
