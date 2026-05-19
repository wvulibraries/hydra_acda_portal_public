# Modernization Initiative: Quick Start Guide

**Core Insight:** ACDA is a harvested-data discovery aggregator. Removing Fedora leaves a simple Blacklight + CSV app.

**TL;DR:** Simplify from Fedora/ActiveFedora → PostgreSQL/ActiveRecord (search + discovery layer)  
**Timeline:** 8-12 weeks (Option A: 1 dev full-time) / 16-20 weeks (Option B: split time) / 20-28 weeks (Option C: parallel stacks)  
**Team:** 2 developers  
**Effort:** High upfront, significant long-term savings  
**Partner:** Notch8 (built Bulkrax integration, can advise on AR migration)  

---

## The Decision

We're **simplifying ACDA Portal** by removing Fedora to become what it actually is: a harvested-data discovery layer.

### What Is ACDA?
```
Harvests CSV from partners
Caches display images locally (for UI polish)
Provides searchable discovery (Blacklight + Solr)
Links back to partner content sources

= Search engine for external data + pretty display
≠ Content repository
≠ Preservation system
```

### Current (Way Overengineered)
```
Bulkrax → Fedora 6 (preservation features unused)
       → PostgreSQL (already have)
       → Redis (just for Sidekiq)
       → Solr → Blacklight
```

### Simplified (What You Need)
```
Bulkrax → PostgreSQL (one DB)
       → good_job (in DB)
       → Solr → Blacklight
```

**Removed:** Fedora, Redis, fork maintenance, RDF/LDP complexity

---

## Resource Options (Pick One)

| Option | Timeline | Approach | Production Risk | Dev Velocity |
|--------|----------|----------|-----------------|---------------|
| **A: Dedicated** | 8-12 weeks | 1 dev full-time modernization, 1 dev support | Low | Paused |
| **B: Phased** | 16-20 weeks | Both devs 60% modernization, 40% support | Medium | Reduced |
| **C: Parallel** | 20-28 weeks | Build new stack alongside current | Very Low | Reduced |

**Recommendation:** Option A if stakeholders accept feature pause. Option B if you need steady feature delivery. Option C only if very high risk tolerance.

---

## Why Simplify?

**ACDA is a Blacklight app, not a preservation repository.**

The current stack (Fedora/ActiveFedora/RDF) is designed for scenarios ACDA doesn't have:
- ❌ Don't need RDF linked data
- ❌ Don't need LDP versioning
- ❌ Don't need PCDM complex relationships
- ✅ Need: Database → Search → UI (Blacklight does this)

**Simplifying solves:**
1. **Operational Burden:** Remove LDP protocol, RDF serialization complexity
2. **Hiring:** Standard Rails developers instead of Fedora experts
3. **Maintenance:** Fork-free — use community standards (Hyrax/Hyku patterns)
4. **Code:** 30-40% less code in models (38 RDF properties → 10 database columns)
5. **Backups:** Simple `pg_dump` instead of RDF exports
6. **Predictability:** Standard Rails architecture, not custom

---

## What Stays the Same? (The Core Blacklight Stack)

✅ **Blacklight** (search interface — THE CORE, unchanged)  
✅ **Solr** (full-text indexing — unchanged)  
✅ **Bulkrax** (imports/exports — works with both AF & AR)  
✅ **Hydra::AccessControls** (permissions — unchanged)  
✅ **Rails 7** (can upgrade to 7.1+ after simplification)  

---

## What Simplifies? (The Unnecessary Parts)

| Component | Current | New | Why |
|-----------|---------|-----|-----|
| **Data Storage** | Fedora RDF (complex) | PostgreSQL (simple) | Don't need RDF |
| **ORM** | ActiveFedora (RDF-based) | ActiveRecord (SQL-based) | Standard Rails |
| **File Storage** | Fedora-managed (tied to LDP) | ActiveStorage (standard Rails) | Decouples from Fedora |
| **Job Queue** | Sidekiq + Redis (separate service) | good_job (in database) | One less service |
| **Models** | `Acda < AF::Base` (38 RDF props) | `CongressionalRecord < AR` (10 columns) | Simple domain model |

---

## Six-Phase Plan

| Phase | Duration | What | Effort |
|-------|----------|------|--------|
| **Phase 1** | 1-2w | Setup PostgreSQL schema, good_job config | Medium |
| **Phase 2** | 2-3w | Export Fedora → PG, migrate files → ActiveStorage | High |
| **Phase 3** | 2-3w | Refactor models, update controllers | High |
| **Phase 4** | 1w | Migrate jobs (Sidekiq → good_job) | Low |
| **Phase 5** | 2-3w | Update tests, staging validation | Medium |
| **Phase 6** | 1w | Production cutover, Fedora decommission | Medium |
| **TOTAL** | **8-12w** | | **High** |

---

## Code Patterns (From Hyrax)

### Before (ActiveFedora)
```ruby
class Acda < ActiveFedora::Base
  property :title, predicate: ::RDF::Vocab::DC.title
  property :creator, predicate: ::RDF::Vocab::DC.creator
  # ... 36 more properties as RDF URIs
  directly_contains :files, class_name: 'AcdaFile'
end
```

### After (ActiveRecord)
```ruby
class CongressionalRecord < ApplicationRecord
  include Hydra::AccessControls::Permissions
  has_many_attached :files
  
  validates :title, presence: true
  after_save :reindex_solr
end
```

**Much simpler.** Standard Rails patterns. Easy to understand.

---

## Community Reference

**Want to see real examples?**

- **Hyrax model:** https://github.com/samvera/hyrax/blob/main/app/models/hyrax/work.rb
- **Hyku good_job config:** https://github.com/samvera/hyku/blob/main/config/good_job.yml
- **Hyrax indexer:** https://github.com/samvera/hyrax/blob/main/app/indexers/hyrax/indexer.rb

We're basically **copying what Hyrax already did.**

---

## Benefits

### For Operations
- ✅ Simple backups (`pg_dump` instead of RDF exports)
- ✅ Disaster recovery (PITR instead of manual restores)
- ✅ Easier scaling (PostgreSQL + caching vs. Fedora clustering)
- ✅ Lower monitoring overhead (standard tools, not custom)
- **Time savings:** ~60 hours/year in maintenance

### For Developers
- ✅ Standard Rails patterns (no PCDM/RDF needed)
- ✅ Faster tests (no Fedora startup = 60% speedup)
- ✅ Easier onboarding (Rails skills, not Fedora expertise)
- ✅ Better hiring pool (Rails devs abundant, Fedora experts rare)
- ✅ Familiar debugging tools (SQL, Rails console, standard logs)

### For the Community
- ✅ Aligned with Hyrax/Hyku patterns
- ✅ Can reference community code, not maintain custom solution
- ✅ Future contributions from Rails/Samvera developers
- ✅ Reproducible deployment (any Rails host works, not Fedora-specific)

---

## Risk Management

**What could go wrong?**

| Risk | Probability | Safety Net |
|------|-------------|-----------|
| Data loss | Low | Full backup, validate before cutover |
| Search breaks | Low | Test Solr reindex in staging |
| Bulkrax fails | Low | Test imports extensively |
| Performance worse | Low | Benchmark before cutover |

**Mitigation:** Run both stacks in parallel for 2-4 weeks (safety valve)

---

## Timeline Options

### Option A: Fast Track (Start Now)
- Weeks 1-2: Phase 1 (setup)
- Weeks 3-5: Phase 2 (data migration)
- Weeks 6-8: Phase 3 (code refactor)
- Weeks 9-10: Phase 4-5 (jobs, tests)
- Week 11: Phase 6 (cutover)
- **Total:** 11 weeks, 2 people, continuous work

### Option B: Phased (Start in June)
- June: Phase 1 (setup)
- July: Phase 2 (migration)
- August: Phase 3 (refactor)
- September: Phase 4-5 (jobs, tests, staging)
- Early October: Phase 6 (cutover)
- **Total:** 4 months, distributed team

### Option C: Conservative (Stabilize First)
- This week: Phase 0 (evaluate upstream ActiveFedora main, 2-4 weeks)
- If compatible, return to upstream
- Plan modernization for Q3/Q4

---

## Documents to Read

1. **ARCHITECTURE.md** ← Start here (this decision)
2. **MODERNIZATION.md** ← Full implementation plan (all 6 phases)
3. **HYRAX_ALIGNMENT.md** ← Code examples, patterns, gems to adopt
4. **issues.md** ← Technical debt (optional, if Phase 0 route chosen)

---

## Next Steps

### This Week
- [ ] Team review of ARCHITECTURE.md
- [ ] Discuss timeline preference (Option A/B/C)
- [ ] Stakeholder approval

### Next Week (If Approved)
- [ ] Create feature branch: `modernize/postgres-activerecord`
- [ ] Start Phase 1 (PostgreSQL schema design review)
- [ ] Reference Hyrax code patterns

### Architecture
- [ ] Assign Phase leads
- [ ] Kick off Phase 1
- [ ] Weekly check-ins on migration progress

---

## Questions?

- **How long exactly?** 8-12 weeks, depends on team size and parallel work
- **Can we do it gradually?** Yes, but recommended as single effort (cleaner cutover)
- **What if it breaks?** Rollback plan in MODERNIZATION.md; both stacks run in parallel
- **Will old code break?** Controllers/jobs updated, views mostly syntax changes
- **Do we need Fedora experts?** Not after migration; standard Rails skills enough
- **What about Bulkrax compatibility?** Already supports AR; may need minor testing

---

## Checklist: Go/No-Go Decision (For 2-Dev Team)

**CRITICAL (Go only if all checked):**
- [ ] Stakeholders accept feature velocity reduction during modernization
- [ ] One developer can dedicate 8-12 weeks to modernization (Option A) **OR** both split time 60/40 for 16-20 weeks (Option B)
- [ ] Production support can be handled by 1 developer for 8-12 weeks
- [ ] Current Fedora fork is stable enough to leave as-is during modernization
- [ ] Team has or can quickly learn: PostgreSQL basics, good_job, ActiveStorage

**STRONGLY RECOMMENDED (Go if 4/5 checked):**
- [ ] Have a senior Rails developer who can lead architecture decisions
- [ ] PostgreSQL experience exists on team (even if just Rails defaults)
- [ ] Staging environment available for testing before production cutover
- [ ] Team comfortable with Git workflow (feature branches, rebasing for long-lived PRs)
- [ ] Clear business driver: "Reduce fork maintenance burden" or "Improve hiring pool"

**RED FLAGS (Reconsider if any apply):**
- ❌ Both developers needed for active feature development in next 3 months
- ❌ Zero PostgreSQL knowledge on team (adds 2-3 weeks learning curve)
- ❌ Production is very fragile (can't spare 1 dev for support)
- ❌ Stakeholders expect zero feature pause
- ❌ No staging/testing environment available

---

## Resources

**Your Team:**
- **Notch8:** Professional Samvera consulting (built your Bulkrax integration)
  - Contact early about AR migration patterns
  - May have generic migration scripts from other clients
  - Can advise on Bulkrax reconfiguration for ActiveRecord

**Community Examples:**
- Hyrax: https://github.com/samvera/hyrax
- Hyku: https://github.com/samvera/hyku
- Bulkrax: https://github.com/samvera/bulkrax

**Tools We'll Use:**
- PostgreSQL (already using)
- good_job (PostgreSQL-backed jobs)
- ActiveStorage (Rails 6+)
- Blacklight (already using)
- Solr (already using)

**Learning:**
- Rails guides: https://guides.rubyonrails.org/
- Hyrax wiki: https://github.com/samvera/hyrax/wiki
- good_job docs: https://github.com/bensheldon/good_job

---

## Decision Record

**Status:** ✅ APPROVED  
**Date:** May 2026  
**By:** [Name]  
**Effective:** [Date of decision]

This initiative is the **strategic modernization of ACDA Portal** to align with Samvera community standards and reduce long-term operational burden.

See ARCHITECTURE.md for full rationale.
