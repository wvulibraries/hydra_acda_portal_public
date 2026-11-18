# Architecture Decision Records

Strategic decisions about the technical direction and design of ACDA Portal.

## ADR-001: PostgreSQL + ActiveRecord Modernization

**Status**: ✅ APPROVED  
**Date**: May 2026  
**Supersedes**: Active Fedora + PostgreSQL hybrid  

### Problem Statement

ACDA Portal is fundamentally a **harvested-data discovery aggregator**, not a content repository.

**What ACDA Actually Does**:
- Harvests CSV data from external partner institutions
- Caches display images locally (thumbnails, processed images)
- Provides searchable discovery interface (Blacklight)
- Links back to partner source materials

**What Fedora Provides** (Unused):
- Versioning (data is external, owned by partners)
- RDF linked data (not needed, flat CSV structure)
- LDP repository protocol (not needed, aggregator not repository)
- Complex relationships (not needed, simple joins sufficient)
- Preservation features (not needed, partners own originals)

### Current Architecture (Overengineered)
```
CSV from Partners
    ↓
Bulkrax → Fedora 6 (preservation features unused)
    ↓
PostgreSQL (already using)
    ↓
Redis (just for Sidekiq)
    ↓
Solr → Blacklight
```

### Proposed Architecture (Simplified)
```
CSV from Partners
    ↓
Bulkrax → PostgreSQL (unified database)
    ↓
good_job (PostgreSQL-backed jobs)
    ↓
Solr → Blacklight
```

### Decision

**ADOPT**: PostgreSQL + ActiveRecord + good_job Stack

Migrate ACDA Portal to Hyrax/Hyku-aligned architecture:
- **Database**: PostgreSQL (standardize on single DB)
- **ORM**: ActiveRecord (standard Rails)
- **File Storage**: ActiveStorage (Rails 6+ standard)
- **Job Queue**: good_job (PostgreSQL-backed, like Hyku)
- **Search**: Blacklight + Solr (unchanged, community standard)
- **Imports**: Bulkrax (unchanged, community standard)
- **Permissions**: Hydra::AccessControls (unchanged, community standard)

### Benefits

1. **Simplicity**: Remove unnecessary technology (Fedora)
2. **Maintainability**: Align with community standards (Hyrax/Hyku)
3. **Cost**: Lower infrastructure requirements
4. **Developer Velocity**: Rails developers don't need RDF/LDP expertise
5. **Future-Proof**: Clear upgrade path (Rails 8+)
6. **Team Sustainability**: Easy to hire & onboard Rails developers

### Implementation

**Phase 1**: PostgreSQL schema design (2 weeks)  
**Phase 2**: ActiveRecord model migration (3 weeks)  
**Phase 3**: Testing & validation (2 weeks)  
**Phase 4**: Deploy to staging (1 week)  
**Phase 5**: Production rollout (1 week)  

**Timeline**: 8-12 weeks (Option A: 1 dev full-time)

See [[Hyrax Alignment]] for detailed architectural mapping.

---

## ADR-002: Bulkrax v10 Upgrade Strategy

**Status**: ⏳ DECISION REQUIRED  
**Date**: November 2026  
**Context**: Rails 8 migration planning  

### Problem Statement

ACDA uses **Bulkrax v8.3.0 on unofficial `hydra-rails-7-support` branch**, which is 2 versions behind latest (v10.0.1).

**Current State**:
- v8.3.0: Released ~2021, Rails 5-6 compatible
- Custom branch: Not official Samvera release
- Rails 8 Upgrade: BLOCKED without upgrading Bulkrax

**Latest Release**:
- v10.0.1: Released Nov 2026
- Rails 8.1: Smoke tests pass
- Official Samvera support & security

### Options

**Option A**: Upgrade to v10.0.1 (Recommended)
- Effort: 40-80h
- Risk: Medium (testing-dependent)
- Rails 8: ✅ Unblocked
- Support: Official Samvera

**Option B**: Maintain fork (High Risk)
- Effort: 60-100h initial + 10h/month
- Risk: High (sustainability)
- Rails 8: ⚠️ Backporting required
- Support: Team responsible

**Option C**: Build custom importer (Too Costly)
- Effort: 160h+ initial + 20h/month
- Risk: Very High (reinventing wheel)
- Rails 8: ✅ Full control
- Support: Team responsible

### Recommendation

**Execute Option A: Upgrade to Bulkrax v10.0.1**

This is the best cost/risk balance and unblocks Rails 8 migration.

See [[Bulk Import Strategy]] for detailed analysis and implementation roadmap.

---

## ADR-003: Hyrax/Hyku Community Alignment

**Status**: ✅ APPROVED  
**Date**: May 2026  
**Related**: ADR-001 (PostgreSQL modernization)  

### Problem Statement

ACDA Portal was built as a custom Hydra application and has diverged from Samvera community standards.

### Current State

ACDA uses:
- Active Fedora (deprecated, only WVU maintaining fork)
- Custom implementations of common patterns
- Specialized setup (not community-standard)
- Difficult to find developers

### Community Standards

Hyku represents the modern Samvera stack:
- PostgreSQL + ActiveRecord (not Fedora)
- Hyrax as application framework
- Community-maintained & documented
- Easier to hire developers for

### Decision

**ADOPT Hyrax/Hyku Patterns** (not necessarily use Hyku itself):
- Use PostgreSQL + ActiveRecord (ADR-001)
- Use good_job (instead of Sidekiq/Redis)
- Use standard Blacklight configuration
- Use standard file storage (ActiveStorage)
- Participate in Samvera community

### Benefits

- Align with community standards & practices
- Easier knowledge transfer & developer hiring
- Clear upgrade paths (Rails 8+, Ruby 3.4+)
- Community support & shared solutions

---

## Related Documents

- [[System Architecture Overview]] - Current technical stack
- [[Hyrax Alignment]] - Detailed pattern mapping
- [[Bulk Import Strategy]] - Bulkrax version decision
- [[Rails 8 Migration Planning]] - Framework upgrade planning

---

**Last Updated**: November 18, 2026  
**Status**: 🟢 Active Development  
**Next Review**: End of Q4 2026
