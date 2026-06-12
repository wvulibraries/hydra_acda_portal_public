# ActiveFedora Architectural Coupling & Decoupling Issues

**Status:** � STRATEGIC CHOICE (Fork stable, but modernization recommended)  
**Priority:** HIGH  
**Team Size:** 2 developers  
**Estimated Effort:** 8-12 weeks (Option A) / 16-20 weeks (Option B) / 20-28 weeks (Option C)  
**Owner:** TBD

---

## Problem Statement

The ACDA Portal is a **harvested-data discovery aggregator** deeply coupled to ActiveFedora, making it unnecessarily complex:

- **What ACDA actually does:** Loads CSV data from partners → indexes to Solr → provides searchable discovery → links back to partner sources + displays cached thumbnails
- **What ACDA pretends to need:** Fedora's preservation features (versioning, RDF linked data, LDP protocol) — which it doesn't use
- **Result:** Maintaining a fork of a deprecated technology for zero value

**Current State:** Using temporary fork (`wvulibraries/active_fedora`) for Fedora 6 support. This is **stable now**, but maintains a long-term burden.

**Strategic Decision:** Rather than perpetually chase upstream compatibility, **simplify to PostgreSQL + ActiveRecord** (standard Blacklight stack). This eliminates the fork dependency and unnecessary complexity.

---

## Context: Why the Fork Exists

### Root Cause of Dec 2025 Breakage

- Upstream branch `fedora6-cjcolvar-rebase` was deleted after merging to main (Dec 4, 2025)
- Git branches are ephemeral; commits are permanent
- Pinning to branch name = 404 when deleted
- **Lesson:** Pin to commit hashes, not branch names (now implemented)

### Current Temporary Solution

**What we did:**
- Created fork: `https://github.com/wvulibraries/active_fedora.git`
- Branch: `fedora6-cjcolvar-rebase` (Fedora 6 support)
- Pinned to commit: `9b5352009407a6254b9e3db408d2c9554efeaf55`
- Updated `Gemfile` and `Gemfile.lock` to reference fork + commit hash

**Why this works now:**
- Fork is under your control (no deletion risk)
- Pinning to commit hash is resilient (commits never disappear)
- Gives 2-3 month window to plan permanent solution

**Why this isn't long-term:**
- Maintaining a fork adds 3-5 hours/month overhead
- Fedora is legacy tech (< 5% of Samvera community uses it)
- Hyrax/Hyku prove PostgreSQL + ActiveRecord is the modern standard
- Small 2-person team can't afford perpetual fork maintenance

---

## Permanent Solution: Modernize to PostgreSQL + ActiveRecord

### Why Modernization Over Upstream Compatibility?

**Path 1: Return to upstream (Phase 0 option)**
- Pro: No fork to maintain
- Con: Still chasing ActiveFedora versions, still dependent on Fedora
- Con: 2-dev team can't debug upstream incompatibilities
- Con: Doesn't solve "Fedora is legacy" problem

**Path 2: Modernize to PostgreSQL (RECOMMENDED)**
- Pro: Aligns with Hyrax/Hyku/Samvera community standard
- Pro: Eliminates fork entirely
- Pro: Simpler architecture (PostgreSQL vs. LDP/RDF)
- Pro: Better hiring pool (Rails devs abundant, Fedora experts rare)
- Pro: Lower ops burden (60+ hours/year saved)
- Timeline: 8-12 weeks full-time (1 dev) + 1 dev supporting production

### Implementation

**See:** [MODERNIZATION.md](MODERNIZATION.md) - Full 6-phase plan  
**See:** [ARCHITECTURE.md](ARCHITECTURE.md) - Decision rationale  
**See:** [HYRAX_ALIGNMENT.md](HYRAX_ALIGNMENT.md) - Code patterns & examples  
**See:** [QUICKSTART.md](QUICKSTART.md) - Executive summary & timeline options

---

## Optional: Phase 0 - Investigate Upstream Compatibility (Skip if Choosing Modernization)

**ONLY IF:** You want to try returning to `samvera/active_fedora` main before committing to modernization  
**Duration:** 2-4 weeks  
**Risk:** May still find incompatibilities, wasting time  
**Recommendation:** Skip this; go straight to modernization

**If proceeding:**
1. Check ActiveFedora v15.0+ Fedora 6 support
2. Test with Rails 7.0.8
3. Run full test suite
4. If compatible: update Gemfile to use `samvera/active_fedora` main
5. If not compatible: confirms modernization is the right path

---

## Go/No-Go Decision Framework

### Choose Modernization Path IF:
- ✅ Long-term project (2+ years)
- ✅ Can spare 1 developer for 8-12 weeks
- ✅ Want to align with Samvera community standards
- ✅ Willing to pause new features during migration
- ✅ Have staging environment for testing

### Choose Phase 0 (Upstream Compat) IF:
- ✅ Must ship features in next 4 weeks
- ✅ Stakeholders won't approve 2-3 month pause
- ✅ Quick stabilization is higher priority than long-term architecture

### Stay on Fork IF:
- ✅ Just need 2-3 months to decide
- ✅ Current fork is working fine
- ✅ Team needs time to plan next steps

---

## Decision Checklist for 2-Developer Team

- [ ] Leadership approves 8-12 week modernization timeline (or 16-20 weeks for split work)
- [ ] One developer can focus on modernization
- [ ] One developer can handle production support
- [ ] PostgreSQL/good_job skills sufficient (or team willing to learn)
- [ ] Have staging environment for validation before cutover

---

## ⚠️ DEPRECATED: Architectural Decoupling Strategy

**Status:** SUPERSEDED by MODERNIZATION.md  
**Reason:** Decoupling without migration still leaves you on ActiveFedora/Fedora. Modernization is more efficient.

The detailed decoupling work below (Phase 1-3) is **kept for reference only**. Implement only if you choose the Phase 0 path (try upstream compatibility first). If modernizing, skip this section entirely.

### Critical Coupling Points (For Reference Only)

| Layer | Risk | Impact | Effort |
|-------|------|--------|--------|
| **RDF Property System** | 🔴 CRITICAL | 38 properties + inline indexing | HIGH |
| **PCDM File Relationships** | 🔴 CRITICAL | directly_contains* methods | HIGH |
| **Custom Indexer** | 🔴 CRITICAL | Inherits ActiveFedora::IndexingService | MEDIUM |
| **Base Class** | 🔴 CRITICAL | Acda < ActiveFedora::Base everywhere | HIGH |
| **LDP Conflict Retry** | 🟠 HIGH | save_with_retry! / Ldp::Conflict | MEDIUM |
| **Query Patterns** | 🟡 MEDIUM | 16+ Acda.find/where calls | LOW |
| **File Building** | 🟡 MEDIUM | build_image_file, content= | MEDIUM |
| **Authorization** | 🟡 MEDIUM | Hydra::AccessControls::Permissions | MEDIUM |

---

### Phase 1: Create Service Abstraction Layer (2-3 weeks)

**Goal:** Decouple business logic from ActiveFedora ORM

#### Issue #1.1: Centralize Record Queries

**Affected Files:**
- `hydra/app/controllers/record_controller.rb` (5 queries)
- `hydra/app/controllers/admin_controller.rb` (2 queries)
- `hydra/app/jobs/automatic_import_job.rb` (3 queries)
- `hydra/app/jobs/delete_record_job.rb` (1 query)
- `hydra/app/services/automatic_import.rb` (2 queries)
- `hydra/app/models/acda.rb` (3 queries in `queue_pending_thumbnails`)
- Bulkrax integration points (4 queries)

**Work:**
1. Create `hydra/app/repositories/record_repository.rb`
   ```ruby
   class RecordRepository
     def self.find(id)
       Acda.find(id)  # Can be mocked in tests
     end
     
     def self.find_all_pending_thumbnails(batch_size: 1)
       Acda.find_each(batch_size: batch_size).select { |r| r.needs_thumbnail? }
     end
     
     def self.where(**criteria)
       # Centralize query logic
       Acda.where(criteria)
     end
   end
   ```

2. Replace all `Acda.find()` with `RecordRepository.find()`
3. Update controllers, jobs, services
4. Add repository tests with mock/stub implementations

**Benefit:** All queries in one place; easy to test without ActiveFedora

---

#### Issue #1.2: Extract File Attachment Service

**Affected Files:**
- `hydra/app/models/acda.rb` (lines 310-329: relationship definitions)
- `hydra/app/models/acda.rb` (lines 352-390: file building methods)
- `hydra/lib/import_library.rb` (file upload logic)
- `hydra/app/jobs/thumbnail_generation_job.rb` (file access)

**Work:**
1. Create `hydra/app/services/file_attachment_service.rb`
   ```ruby
   class FileAttachmentService
     def self.attach_file(record, file_type, file_path, mime_type)
       # Hide: record.build_image_file, content = File.open(...), save logic
     end
     
     def self.get_image_file(record)
       record.image_file
     end
     
     def self.has_file?(record, file_type)
       # Hide directly_contains introspection
     end
   end
   ```

2. Remove `build_image_file`, `build_thumbnail_file`, etc. from Acda model
3. Update ImportLibrary to use service
4. Update ThumbnailGenerationJob to use service

**Benefit:** File operations decoupled from PCDM/Fedora model

---

#### Issue #1.3: Create Custom Solr Indexing Service

**Affected Files:**
- `hydra/app/indexers/indexer.rb` (lines 1-17: inherits ActiveFedora::IndexingService)
- `hydra/app/models/acda.rb` (line 309: `self.indexer = ::Indexer`)

**Work:**
1. Create `hydra/app/services/solr_indexing_service.rb`
   ```ruby
   class SolrIndexingService
     def self.build_solr_document(record)
       doc = base_solr_document(record)
       doc['has_image_file_bsi'] = record.image_file.present?
       # ... other custom fields
       doc
     end
     
     private
     
     def self.base_solr_document(record)
       # RDF → Solr transformation logic (extracted from ActiveFedora::IndexingService.generate_solr_document)
     end
   end
   ```

2. Create property mapping registry (see Phase 2)
3. Rewrite Indexer to use SolrIndexingService instead of inheriting from ActiveFedora
4. Update Acda.indexer assignment

**Benefit:** Solr indexing logic is now standalone, testable, ActiveFedora-independent

---

### Phase 2: Property Registry & RDF Mapping (1-2 weeks)

**Goal:** Make property definitions explicit and decoupled from model DSL

#### Issue #2.1: Extract Property Definitions

**Current State:**
38 properties defined inline in `hydra/app/models/acda.rb` (lines 130-240) using ActiveFedora DSL:
```ruby
property :title, predicate: ::RDF::Vocab::DC.title,
  class_name: 'String', multiple: true do |index|
    index.as :stored_searchable, :stored_sortable, :facetable
end
```

**Work:**
1. Create `hydra/config/properties.yml`
   ```yaml
   properties:
     title:
       predicate: http://purl.org/dc/elements/1.1/title
       class_name: String
       multiple: true
       solr_index:
         - stored_searchable
         - stored_sortable
         - facetable
     creator:
       predicate: http://purl.org/dc/elements/1.1/creator
       # ... etc for all 38 properties
   ```

2. Create `hydra/lib/property_registry.rb`
   ```ruby
   class PropertyRegistry
     def self.all
       @properties ||= load_from_yml('config/properties.yml')
     end
     
     def self.get(property_name)
       all[property_name.to_sym]
     end
   end
   ```

3. Refactor `SolrIndexingService` to read from PropertyRegistry instead of property definitions
4. Remove inline property definitions from Acda model
5. Update tests

**Benefit:** Explicit property mappings; easier to maintain RDF URIs; decoupled from model

---

#### Issue #2.2: Create RDF Type Registry

**Current State:**
PCDM types hardcoded in relationship definitions:
```ruby
directly_contains :files, 
  has_member_relation: ::RDF::URI('http://pcdm.org/models#File'), 
  type: ::RDF::URI('http://pcdm.org/use#Image')
```

**Work:**
1. Create `hydra/config/file_types.yml`
   ```yaml
   file_types:
     image:
       rdf_type_uri: http://pcdm.org/use#Image
       mime_types:
         - image/jpeg
         - image/png
       solr_field: has_image_file_bsi
     thumbnail:
       rdf_type_uri: http://pcdm.org/use#ThumbnailImage
       # ...
   ```

2. Create `hydra/lib/file_type_registry.rb`
3. Update PCDM relationship definitions to reference registry
4. Update FileAttachmentService to use registry

**Benefit:** File type mappings centralized; easier to extend file type support

---

### Phase 3: Persistence Adapter Pattern (2-3 weeks)

**Goal:** Replace base class inheritance with composition; enable easy swapping

#### Issue #3.1: Create Persistence Adapter Interface

**Current State:**
```ruby
class Acda < ActiveFedora::Base
  # Everything coupled to ActiveFedora::Base
end
```

**Work:**
1. Create `hydra/app/adapters/persistence_adapter.rb` (interface)
   ```ruby
   class PersistenceAdapter
     def save(object)
       raise NotImplementedError
     end
     
     def find(id)
       raise NotImplementedError
     end
     
     def destroy(id)
       raise NotImplementedError
     end
     
     def persisted?(object)
       raise NotImplementedError
     end
   end
   ```

2. Create `hydra/app/adapters/fedora_persistence_adapter.rb` (Fedora implementation)
   ```ruby
   class FedoraPersistenceAdapter < PersistenceAdapter
     def save(object)
       object.save_with_retry!
     end
     
     def find(id)
       object = Acda.find(id)
       object
     end
     
     # ... etc
   end
   ```

3. Refactor Acda model
   ```ruby
   class Acda
     # Remove: < ActiveFedora::Base
     
     @persistence_adapter = FedoraPersistenceAdapter.new
     
     def self.find(id)
       @persistence_adapter.find(id)
     end
     
     def save
       @persistence_adapter.save(self)
     end
   end
   ```

4. Update all persistence calls to go through adapter

**Benefit:** Acda becomes independent of ActiveFedora base class; enables testing with mocks; allows alternative implementations

---

#### Issue #3.2: Create Test Double Persistence Adapter

**Work:**
1. Create `hydra/spec/support/memory_persistence_adapter.rb`
   ```ruby
   class MemoryPersistenceAdapter < PersistenceAdapter
     @@store = {}
     
     def save(object)
       @@store[object.id] = object.dup
     end
     
     def find(id)
       @@store[id] || raise ActiveFedora::ObjectNotFoundError
     end
   end
   ```

2. Update test suite to use MemoryPersistenceAdapter
3. Remove fcrepo/Fedora from test dependencies
4. Reduce test suite runtime by ~60% (no repository startup)

**Benefit:** Fast, isolated unit tests; no Docker/repository needed for most tests

---

## Implementation Roadmap

```
Week 1-2:   Phase 0 - Upstream Reconciliation
            ├─ Verify ActiveFedora main Fedora 6 support
            ├─ Test with current app code
            └─ Return to samvera/active_fedora main if compatible

Week 3-4:   Phase 1.1 - RecordRepository Service
            ├─ Create service
            ├─ Update controllers (5 locations)
            ├─ Update jobs (4 locations)
            └─ Update services (2 locations)

Week 5-6:   Phase 1.2 - FileAttachmentService
            ├─ Extract file building logic
            ├─ Update ImportLibrary
            └─ Update ThumbnailGenerationJob

Week 7:     Phase 1.3 - SolrIndexingService
            ├─ Create custom indexer
            └─ Decouple from ActiveFedora::IndexingService

Week 8-9:   Phase 2.1 - Property Registry
            ├─ Extract 38 properties to YAML
            ├─ Create PropertyRegistry
            └─ Update SolrIndexingService

Week 10:    Phase 2.2 - File Type Registry
            ├─ Extract PCDM types to YAML
            └─ Update FileAttachmentService

Week 11-12: Phase 3.1 & 3.2 - Persistence Adapter
            ├─ Create adapter interface
            ├─ Implement FedoraPersistenceAdapter
            ├─ Create MemoryPersistenceAdapter
            ├─ Refactor Acda model
            └─ Update test suite

Week 13-14: Integration & Testing
            ├─ Full regression test
            ├─ Performance benchmarks
            └─ Documentation
```

---

## Success Criteria

- [ ] All queries routed through RecordRepository
- [ ] All file operations use FileAttachmentService
- [ ] Indexer does not inherit from ActiveFedora
- [ ] All 38 properties in explicit registry
- [ ] Acda model composition-based, not inheritance-based
- [ ] 80%+ test coverage without Fedora running
- [ ] Can swap persistence adapter (test proof-of-concept with MemoryAdapter)
- [ ] App still works on Fedora 6 after all changes

---

## Dependencies & Blockers

**External:**
- [ ] Samvera community confirms ActiveFedora 15.x + Rails 7.0.8 compatibility
- [ ] Bulkrax updates if needed

**Internal:**
- [ ] Hydra-head gem constraints (permissions system)
- [ ] Solrizer/RSolr API stability

---

## References

- Active-Fedora GitHub: https://github.com/samvera/active_fedora
- PR #1504 (Fedora 6 support): https://github.com/samvera/active_fedora/pull/1504
- Current fork (temporary): https://github.com/wvulibraries/active_fedora

---

## Notes

- This decoupling makes the app **significantly more resilient** to external dependency breaks
- Enables easier testing (no repository startup)
- Opens door to multi-storage backends (S3, PostgreSQL, etc.) in future
- Does NOT reduce functionality; purely architectural improvement
