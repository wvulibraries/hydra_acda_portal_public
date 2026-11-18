# Bulk Import Strategy: Bulkrax vs Spotlight

## Executive Summary

**Current Status**: ACDA Portal uses Bulkrax v8.3.0 on a custom Rails 7 support branch  
**Issue**: Version is 2 releases behind (v10.0.1 current), requires forking for Rails 8 migration  
**Decision Required**: Continue with Bulkrax (maintain fork), upgrade to v10 (may require rework), or evaluate alternatives

---

## Current Implementation

### What We're Using

```
Bulkrax v8.3.0
├── Rails Support: 5-6 (via community hydra-rails-7-support branch)
├── OAI-PMH Importer: ✅ CongressionalRecords harvesting
├── Field Mappings: ✅ Custom metadata transformation
├── Job Processing: ✅ good_job (async background jobs)
└── Fedora Integration: ✅ Via custom active-fedora fork
```

**Gem Reference**:
```ruby
gem 'bulkrax', github: 'samvera/bulkrax', 
              ref: '1960bacc48fbb48c5d6f697a9849ddb1a823f867'
```

### Key Features in Use

1. **OAI-PMH Harvesting**: Congressional Records from external OAI feeds
2. **Bulk Ingestion**: Thousands of records with metadata mapping
3. **Admin Interface**: Web UI for managing imports, retries, monitoring
4. **Background Processing**: good_job queues for async imports
5. **Field Transformation**: Complex metadata mapping & normalization

---

## Version Timeline & Rails Compatibility

| Version | Released | Rails Support | Status | Notes |
|---------|----------|--------------|--------|-------|
| **v8.3.0** | ~2021 | Rails 5-6 | 🔴 Obsolete | Current ACDA (via custom branch) |
| v9.0-9.5 | 2022-2024 | Rails 6-7 | 🟡 Old | Requires significant rework |
| **v10.0.1** | Nov 2026 | Rails 7, 8.1 tested | 🟢 Current | Latest release |

### The Problem

**ACDA Current State**:
- Rails 7.0.8 (need to upgrade to 8.0+ for future)
- Bulkrax v8.3.0 (requires custom hydra-rails-7-support branch)
- Branch is **not** an official Samvera release

**Why This Matters**:
1. ⚠️ The branch is community-maintained, not officially supported
2. ⚠️ Security updates must be manually backported
3. ⚠️ Rails 8 migration will likely require forking v8.3.0 OR upgrading to v10
4. ⚠️ v10 requires testing for OAI-PMH and field mapping compatibility

---

## Three Strategic Options

### Option A: Upgrade to Bulkrax v10.0.1 ✅ Recommended

**Strategy**: Update to latest Bulkrax version, test compatibility

**Advantages**:
- ✅ Official Samvera support & security updates
- ✅ Rails 8.1 tested (not guaranteed with Hyrax, but Bulkrax itself tested)
- ✅ Latest features & bug fixes
- ✅ No fork maintenance burden
- ✅ Better long-term sustainability

**Disadvantages**:
- ⚠️ 2-version jump requires testing
- ⚠️ May need to rework field mappings
- ⚠️ Could have breaking changes in API
- ⚠️ 40-80 hours development & testing

**Effort Estimate**: 40-80 hours  
**Timeline**: 2-3 sprints  
**Risk**: Medium (testing-dependent)

**Steps**:
1. Create feature branch: `feature/bulkrax-v10-upgrade`
2. Update Gemfile to v10.0.1
3. Run bundle update
4. Test OAI-PMH importer with real Congressional Records
5. Test field mappings match expected output
6. Update any configuration changes in initializers
7. Run full test suite
8. Deploy to staging
9. Monitor for 1-2 weeks
10. Deploy to production

---

### Option B: Maintain Custom Fork (High Maintenance) ⚠️

**Strategy**: Fork v8.3.0, backport Rails 8 support ourselves

**Advantages**:
- ✅ Minimal codebase changes
- ✅ Familiar configuration & setup
- ✅ Existing tests likely pass

**Disadvantages**:
- ❌ Ongoing maintenance burden (security patches, gem updates)
- ❌ No upstream support
- ❌ Security vulnerabilities stay unreported
- ❌ Team becomes responsible for Rails 8 compatibility
- ❌ 60-100 hours initial work, 10 hours/month ongoing
- ❌ Difficult to hire new developers (non-standard setup)

**Effort Estimate**: 60-100 initial + 10/month ongoing  
**Long-term Cost**: Highest  
**Risk**: High (sustainability risk)

**Not Recommended** unless v10 upgrade proves impossible

---

### Option C: Custom OAI-PMH Importer (Nuclear Option) ❌

**Strategy**: Build custom importer without Bulkrax

**Advantages**:
- ✅ Full control over implementation
- ✅ Could use Spotlight for curation UI
- ✅ Lighter dependencies

**Disadvantages**:
- ❌ 160+ hours initial development
- ❌ 20 hours/month maintenance
- ❌ Reinvent features Bulkrax handles (CSV, BagIt, retries, job queues)
- ❌ No export functionality
- ❌ No admin UI for imports
- ❌ High risk of bugs
- ❌ Not recommended unless Bulkrax proves completely incompatible

**Effort Estimate**: 160+ initial + 20/month ongoing  
**Risk**: Very High  
**Timeline**: 3-4 months

---

## Recommended Path Forward

### Phase 1: Proof of Concept (2 weeks)

**Goal**: Determine if v10 upgrade is feasible

```bash
# 1. Create test branch
git checkout -b feature/bulkrax-v10-poc

# 2. Test v10 with Rails 7
gem 'bulkrax', '~> 10.0.1'  # or latest release
bundle update bulkrax

# 3. Run existing tests
bundle exec rspec spec/

# 4. Test OAI-PMH import manually
# - Import sample Congressional Records
# - Verify field mappings
# - Check job processing

# 5. Document any breaking changes
```

**Decision Point**: Go/no-go for Option A

---

### Phase 2: Implementation (If Option A Chosen)

**Timeline**: 2-3 sprints

1. **Bundle & Dependency Updates** (1 sprint)
   - Update Bulkrax to v10.0.1
   - Resolve gem conflicts
   - Update initializer configuration
   - Run test suite

2. **Testing & Validation** (1 sprint)
   - Import real Congressional Records sample
   - Verify field mapping accuracy
   - Stress test with large import (1000+ records)
   - Check performance vs. v8.3.0

3. **Staging & Production Rollout** (1 sprint)
   - Deploy to staging environment
   - 1-2 week observation period
   - Monitor for errors/warnings
   - Deploy to production with rollback plan

---

### Phase 3: Rails 8 Readiness

Once v10 is stable:

```ruby
# Update in Gemfile
gem 'rails', '~> 8.0.0'
gem 'ruby', '~> 3.3.0'  # Ruby 3.2+ required for Rails 8

# Then follow standard Rails upgrade process
bundle update
rails upgrade:check
```

Bulkrax v10 has tested Rails 8.1 smoke tests, though full Hyrax integration testing is pending.

---

## Comparison Table

| Aspect | Option A (v10) | Option B (Fork) | Option C (Custom) |
|--------|---|---|---|
| **Initial Effort** | 40-80h | 60-100h | 160h+ |
| **Monthly Maintenance** | 2-5h | 10h | 20h |
| **Security Updates** | ✅ Automatic | ❌ Manual | ❌ Manual |
| **Community Support** | ✅ Yes | ❌ No | ❌ No |
| **Rails 8 Ready** | ✅ Tested | ⚠️ Unknown | ⚠️ Unknown |
| **Feature Parity** | ✅ Full | ✅ Full | ⚠️ Partial |
| **Team Sustainability** | ✅ High | ❌ Low | ❌ Low |
| **Recommended** | 🌟 **YES** | ⚠️ Maybe | ❌ No |

---

## Spotlight Integration (Complementary)

Regardless of Bulkrax choice, Spotlight could enhance the curator experience:

```
OAI Feed
   ↓
[Bulkrax v10]  ← Bulk import & automation
   ↓
Fedora + Solr
   ↓
[Spotlight]    ← Enhanced UI & curation
```

This is **orthogonal** to the Bulkrax upgrade decision. See [[Spotlight Integration Guide]].

---

## Action Items

### This Week
- [ ] Review this strategy document with team
- [ ] Get stakeholder buy-in on Option A
- [ ] Create POC branch for v10 testing

### Next Sprint
- [ ] Execute Phase 1 (POC)
- [ ] Document any breaking changes
- [ ] Make final go/no-go decision

### Following Sprint
- [ ] Execute Phase 2 if go-decision made
- [ ] Deploy to staging
- [ ] Begin observation period

---

## References

- **Bulkrax v10 Release**: https://github.com/samvera/bulkrax/releases/tag/v10.0.1
- **Current Branch**: https://github.com/samvera/bulkrax/tree/hydra-rails-7-support
- **Configuration Wiki**: https://github.com/samvera/bulkrax/wiki/Configuring-Bulkrax
- **Rails 8 Support Testing**: See Bulkrax README Rails Compatibility section

---

**Document Status**: 📋 Review Required  
**Last Updated**: November 18, 2026  
**Owner**: Development Team
