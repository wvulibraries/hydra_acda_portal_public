# Rails 8 Migration Planning

## Status

🚨 **Decision Required**: Rails 8 upgrade path depends on Bulkrax version choice  
See [[Bulk Import Strategy]] for context

## Overview

ACDA Portal is currently on **Rails 7.0.8** and must plan for upgrade to **Rails 8.0+** (expected 2026-2027).

### Timeline

| Phase | Date | Status |
|-------|------|--------|
| **Analysis & Planning** | Nov 2026 | 🔵 In Progress |
| **Bulkrax Decision** | Dec 2026 | ⏳ Pending |
| **Proof of Concept** | Jan 2027 | ⏳ Scheduled |
| **Development** | Q1 2027 | ⏳ Planned |
| **Testing & Staging** | Q2 2027 | ⏳ Planned |
| **Production Deployment** | Q2-Q3 2027 | ⏳ Planned |

## Current State

**Ruby**: 3.3.5  
**Rails**: 7.0.8  
**Bundler**: Latest

### Known Dependencies Requiring Updates

| Gem | Current | Rails 8 Target | Status |
|-----|---------|---|--------|
| **rails** | 7.0.8 | 8.0+ | ⏳ Pending |
| **puma** | 6.4.0 | 6.5+ | ✅ Compatible |
| **pg** | <2.0 | 2.0+ | ⏳ Test needed |
| **bulkrax** | 8.3.0 (custom) | 10.0.1+ | ⚠️ **Blockers** |
| **hydra-head** | (current) | Hyrax equiv | ⏳ Unknown |
| **active-fedora** | custom fork | TBD | ⚠️ **May block** |
| **blacklight** | 7.40.0 | 8.0+ | ✅ Compatible |

## Critical Blockers

### 1. Bulkrax Version ⚠️ CRITICAL

**Issue**: Current Bulkrax v8.3.0 on custom branch may not upgrade to Rails 8

**Resolution**: Complete [[Bulk Import Strategy]] decision:
- **Option A**: Upgrade to Bulkrax v10.0.1 (Recommended)
  - v10 has tested Rails 8.1 smoke tests
  - Requires 40-80 hours testing
  - Clears path to Rails 8

- **Option B**: Maintain fork with Rails 8 patches (Risky)
  - Backport Rails 8 compatibility to v8.3.0
  - High maintenance burden
  - Not recommended

- **Option C**: Build custom importer (Too costly)
  - Would take 160+ hours
  - Not recommended

**Recommendation**: **Execute Option A ASAP** to unblock Rails 8 migration

### 2. Active-Fedora Compatibility ⚠️ MEDIUM

**Issue**: ACDA uses custom WVU fork of active-fedora for Fedora 6 support

```ruby
gem 'active-fedora', 
    git: 'https://github.com/wvulibraries/active_fedora.git', 
    ref: '9b5352009407a6254b9e3db408d2c9554efeaf55'
```

**Status**: Unknown Rails 8 compatibility

**Action**:
1. Test custom fork with Rails 8
2. If incompatible, coordinate with Samvera community
3. Consider Valkyrie migration as long-term alternative

### 3. Hydra/Hyrax Stack ⚠️ MEDIUM

**Question**: What's the upgrade path for hydra-head?

**Investigation Needed**:
- Hyrax vs Hydra - which is ACDA using?
- Hyrax v4+ Rails 8 support status
- Valkyrie migration implications

## Migration Process

### Phase 1: Dependency Analysis (1 week)

**Tasks**:
- [ ] Run `rails upgrade:check`
- [ ] Identify all breaking changes
- [ ] Create upgrade checklist
- [ ] Document gem compatibility matrix
- [ ] Review custom code for Rails 8 issues

**Output**: Detailed migration plan with risk assessment

### Phase 2: Bulkrax Resolution (2-3 weeks)

**Prerequisite**: Complete [[Bulk Import Strategy]]

**Tasks (if Option A selected)**:
- [ ] Create feature branch: `feature/bulkrax-v10-upgrade`
- [ ] Update to Bulkrax v10.0.1
- [ ] Run full test suite
- [ ] Test OAI-PMH import end-to-end
- [ ] Merge to main when complete

**Output**: Bulkrax v10 tested and stable

### Phase 3: Proof of Concept (2 weeks)

**Tasks**:
- [ ] Create feature branch: `feature/rails-8-poc`
- [ ] Update Gemfile:
  ```ruby
  gem 'rails', '~> 8.0.0'
  gem 'ruby', '~> 3.3.0'  # Ruby 3.2+ required
  ```
- [ ] Run `bundle update`
- [ ] Run `bundle exec rails upgrade:check`
- [ ] Execute suggested migrations
- [ ] Run test suite
- [ ] Document any breaking changes

**Output**: POC branch showing Rails 8 readiness

### Phase 4: Development (4-6 weeks)

**Tasks**:
- [ ] Fix failing tests in POC
- [ ] Update custom code for Rails 8 patterns
- [ ] Update configuration files
- [ ] Review deprecation warnings
- [ ] Update dependencies (Webpack, ViewComponent, etc.)
- [ ] Run full test suite (should have >95% pass rate)

**Output**: Rails 8 upgrade branch ready for testing

### Phase 5: Testing & QA (2-3 weeks)

**Tasks**:
- [ ] Deploy to staging environment
- [ ] Smoke test all major features
- [ ] Test OAI-PMH imports
- [ ] Load testing (1000+ records)
- [ ] Security scanning
- [ ] 1-2 week observation period
- [ ] Get stakeholder approval

**Output**: Rails 8 staging environment validated

### Phase 6: Production Deployment (1 week)

**Tasks**:
- [ ] Create deployment plan with rollback
- [ ] Schedule maintenance window
- [ ] Backup production database
- [ ] Deploy to production
- [ ] Monitor for 24+ hours
- [ ] Alert team on completion

**Output**: Rails 8 in production

---

## Ruby Version Considerations

### Current vs Required

| Version | Support Until | Rails 7 | Rails 8 | Notes |
|---------|---|---|---|-------|
| Ruby 3.1 | 2025-12 | ✅ | ❌ | Rails 8 requires 3.2+ |
| Ruby 3.2 | 2026-12 | ✅ | ✅ | Minimum for Rails 8 |
| **Ruby 3.3** | 2027-12 | ✅ | ✅ | **Current in ACDA** |
| Ruby 3.4 | 2028-12 | ✅ | ✅ | Latest (Nov 2026) |

**Recommendation**: Keep Ruby 3.3.5 for now, plan for 3.4+ by 2028

### Breaking Changes to Expect

```ruby
# Rails 7 → Rails 8 Notable Changes

# 1. Active Job now uses json serializer by default (not yaml)
# - May affect scheduled jobs
# - Run bin/rails upgrade:check to see errors

# 2. Rack version changes
# - Cookie handling may differ
# - Test session management

# 3. Asset compilation changes
# - Importmap vs Sprockets
# - Webpack vs Esbuild

# 4. Database migrations
# - New migration format recommended
# - Existing migrations still work

# 5. Gem updates (may have breaking changes)
# - Check CHANGELOG for each major gem
```

## Specific ACDA Concerns

### OAI-PMH Import Stability

**Risk**: Will imports continue to work?

**Testing Procedure**:
```bash
# After Rails 8 upgrade POC:
rails console

importer = Bulkrax::Importer.find(1)
importer.start!  # Queue test import

# Monitor:
# - Job processing (good_job)
# - Record creation
# - Field population
# - Performance vs Rails 7
```

### Fedora 6 Interaction

**Risk**: Custom active-fedora fork compatibility

**Testing Procedure**:
```bash
# Test Fedora read/write operations
# - Create CongressionalRecord
# - Save to Fedora
# - Retrieve from Fedora
# - Index in Solr
# - Search & retrieve
```

### Database Schema

**Expected Changes**: Minimal (Rails 8 is relatively stable)

**Check**:
```bash
rails db:migrate --check  # Verify no pending migrations
```

## Rollback Plan

If Rails 8 migration encounters critical issues:

```bash
# Rollback steps
git checkout rails-7-stable
bundle install
rails db:migrate:down VERSION=xxxxx
# Deploy previous version to production
```

**Estimated Downtime**: 30-60 minutes

**Data Safety**: Database changes should be minimal; data-safe rollback expected

## Communication Plan

### Stakeholder Notification

**Announcement** (1 month before):
- Rails 8 migration planned for Q2 2027
- Expected maintenance window
- Estimated downtime
- No user-facing changes expected

**During Migration**:
- Real-time status updates
- Alert if maintenance window extends

**Post-Migration**:
- Completion notice
- Performance improvements/issues
- Lessons learned documentation

## Success Criteria

✅ Upgrade considered successful when:

1. All tests pass with Rails 8
2. OAI-PMH imports work end-to-end
3. Bulkrax v10+ is stable
4. No regression in search/discovery
5. Performance is equal or better than Rails 7
6. 1 week production uptime without critical issues

## Appendix: Useful Commands

```bash
# Check upgrade readiness
rails upgrade:check

# View all deprecation warnings
RUBYOPT="-W:deprecated" bin/rails test

# Check bundler gems for issues
bundle audit

# View Ruby version compatibility
ruby -v

# Test migration in isolation
rails db:migrate
rails db:rollback
```

---

**Document Status**: 📋 Planning Phase  
**Last Updated**: November 18, 2026  
**Decision Needed**: [[Bulk Import Strategy]] ASAP
