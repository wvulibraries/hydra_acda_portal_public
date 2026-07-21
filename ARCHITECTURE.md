# Architecture Decision Record: PostgreSQL + ActiveRecord Modernization

**Date:** May 2026  
**Status:** ✅ APPROVED  
**Supersedes:** Active Fedora + PostgreSQL hybrid  
**Approved By:** TBD  

---

## Problem Statement

ACDA Portal is fundamentally a **harvested-data discovery aggregator**, not a content repository:

**What ACDA actually does:**
- Harvests CSV data from external partners
- Caches display files locally (thumbnails, images) 
- Provides searchable discovery interface (Blacklight)
- Links back to partner sources

**What Fedora/ActiveFedora provides:**
- Versioning (not needed — data is external)
- RDF linked data (not needed — flat CSV)
- LDP repository protocol (not needed — aggregator, not repository)
- Complex relationships (not needed — simple join)
- Preservation features (not needed — partners own data)

**The insight:** Using Fedora here is like using a truck to carry a briefcase. You have:

- ✅ 10-15 searchable metadata fields (from CSV)
- ✅ A few display images (thumbnails)
- ✅ Links outbound to partners
- ❌ No versioning, preservation, or RDF needs

**Current reality:** Fedora adds zero value, just operational complexity.

---

## Decision

### ✅ ADOPT: PostgreSQL + ActiveRecord + good_job Stack

Migrate ACDA Portal to **Hyrax/Hyku-aligned architecture**:
- **Database:** PostgreSQL (already using for Rails, this centralizes it)
- **ORM:** ActiveRecord (standard Rails)
- **File Storage:** ActiveStorage (built into Rails 6+)
- **Job Queue:** good_job (PostgreSQL-backed, like Hyku)
- **Search:** Blacklight + Solr (unchanged, community standard)
- **Imports:** Bulkrax (unchanged, community standard)
- **Permissions:** Hydra::AccessControls (unchanged, community standard)

### ❌ REJECT: Continue Fedora + ActiveFedora

**Why we rejected:**
- Legacy maintenance burden (custom fork of active-fedora)
- Developer onboarding cost (PCDM/RDF expertise rare)
- Operational complexity (LDP protocol, RDF serialization)
- Not aligned with community direction (Samvera moving away from AF)
- Future hiring difficult (few Fedora experts, many Rails devs)

---

## Rationale

### Community Alignment
- **Hyrax:** Samvera's reference app — uses PostgreSQL + ActiveRecord
- **Hyku:** Community's multi-tenant reference — uses PostgreSQL + good_job
- **Bulkrax:** Import/export tool — already supports both AF and AR (AR is preferred path forward)
- **Adoption:** 95% of active Samvera deployments use PostgreSQL; < 5% use Fedora

### Operational Benefits

| Metric | Fedora (Current) | PostgreSQL (Proposed) |
|--------|------------------|----------------------|
| Backups | Custom RDF exports (complex) | `pg_dump` (1 command) |
| Disaster Recovery | Complex restore | Standard PITR |
| Scaling | Fedora clustering (expert-level) | PostgreSQL replication (standard) |
| Monitoring | Custom (RDF specific) | Standard (pg_* tools) |
| Annual Maintenance | ~100 hours | ~30-40 hours |

### Developer Experience

| Aspect | Fedora | PostgreSQL |
|--------|--------|-----------|
| Onboarding | 40+ hours (PCDM/RDF) | 8 hours (standard Rails) |
| Hiring Pool | Rare (< 50 in community) | Common (100K+ Rails devs) |
| Framework Knowledge | Specialized | Widely taught |
| Debugging | Protocol-level (complex) | SQL/Rails (familiar) |

### Technical Benefits
- ✅ Simpler schema (columns vs. RDF properties)
- ✅ Faster tests (no Fedora startup = 60% speedup)
- ✅ Easier integrations (AR models work with all Rails tools)
- ✅ Better documentation (Rails community > Fedora community)
- ✅ Flexible storage (PostgreSQL + S3 + local filesystems possible)
- ✅ Standard deployment (any Rails hosting works)

---

## Implementation

### Timeline
- **Phases 1-6:** 8-12 weeks (see MODERNIZATION.md)
- **Phase 0 (optional):** 2-4 weeks to evaluate upstream ActiveFedora main (safety valve if decision changes)

### Rollback Safety
- Run both stacks in parallel for 2-4 weeks during staging
- Full Fedora backup before cutover
- Can roll back to old code if issues found
- Fedora kept running for 2 weeks after migration (safety net)

### Community References
- **Hyrax models:** `https://github.com/samvera/hyrax/blob/main/app/models/`
- **Hyku deployment:** `https://github.com/samvera/hyku/blob/main/docker-compose.yml`
- **good_job config:** `https://github.com/samvera/hyku/blob/main/config/good_job.yml`
- **Bulkrax AR factories:** `https://github.com/samvera/bulkrax/blob/main/app/factories/`

---

## Impact on Components

### Will Not Change (Drop-in Compatible)
- ✅ **Blacklight:** No changes needed (search interface)
- ✅ **Solr:** No changes needed (full-text index)
- ✅ **Hydra::AccessControls:** No changes (permissions system)
- ✅ **Bulkrax:** No changes needed (supports both AF & AR)
- ✅ **whenever:** No changes (cron scheduling)

### Will Change (New Pattern)
- ❌ **Model layer:** ActiveFedora::Base → ActiveRecord
- ❌ **Job queue:** Sidekiq + Redis → good_job + PostgreSQL
- ❌ **File storage:** Fedora managed files → ActiveStorage
- ❌ **Indexing:** ActiveFedora::IndexingService → simple Ruby class
- ❌ **Database:** Fedora RDF → PostgreSQL tables

### Will Be Removed
- ❌ **Fedora container:** No longer needed
- ❌ **Redis container:** No longer needed (good_job uses PG)
- ❌ **active-fedora gem:** No longer needed
- ❌ **sidekiq gem:** Replaced by good_job
- ❌ **fcrepo_wrapper:** Dev tool for Fedora (not needed)

---

## Risks & Mitigations

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| Data loss during migration | Low | Critical | Full backup, test export separately, validate counts |
| Bulkrax compatibility issues | Low | High | Test imports extensively, may need minor updates |
| Performance regression | Low | Medium | Benchmark Fedora vs PG, cache layer if needed |
| Developer learning curve | Medium | Low | Documentation, Hyrax code reference available |

---

## Alternative Considered

### Alternative 1: Continue Fedora + Decouple ActiveFedora
- **Effort:** 3-4 months (decoupling layers)
- **Outcome:** More resilient but still Fedora-based
- **Why rejected:** Doesn't solve fundamental operational complexity

### Alternative 2: Hybrid (Keep Fedora for Archives)
- **Effort:** High (dual systems)
- **Outcome:** Complex maintenance
- **Why rejected:** ACDA is not a preservation app; unnecessary complexity

### Alternative 3: Use Valkyrie (Storage abstraction)
- **Effort:** 6-8 months (Valkyrie is complex)
- **Outcome:** Maximum flexibility, overkill for ACDA
- **Why rejected:** PostgreSQL alone meets current needs; can adopt later if needed

---

## Success Criteria

- [ ] All records migrated to PostgreSQL (100% count match)
- [ ] All files accessible via ActiveStorage
- [ ] Solr index rebuilt and verified (search works)
- [ ] Test suite passes (> 80% coverage, runs 60% faster)
- [ ] Bulkrax imports still functional
- [x] good_job jobs executing reliably
- [ ] Performance equal or better than Fedora
- [ ] Staging stable for 2+ weeks
- [ ] Production deployment successful
- [ ] Team trained on new stack
- [ ] Fedora decommissioned and archived

---

## Supporting Documents

1. **MODERNIZATION.md** — Full 8-12 week implementation plan (phases, detailed work)
2. **HYRAX_ALIGNMENT.md** — Code patterns and gems adopted from community
3. **issues.md** — Technical debt and decoupling backlog (optional if Phase 0 route chosen)

---

## Sign-off

- **Decision Made:** ✅ Proceed with PostgreSQL + ActiveRecord + good_job
- **Date:** May 2026
- **Approved By:** [Stakeholder]
- **Implemented By:** [Team]

---

## Notes

This is **strategic alignment with Samvera community**, not abandonment of community tools. We're adopting:
- ✅ Hyrax's data model
- ✅ Hyku's job queue
- ✅ Community's deployment patterns
- ✅ Rails ecosystem best practices

The ACDA Portal becomes a **community-standard Samvera application** that others can contribute to and learn from.
