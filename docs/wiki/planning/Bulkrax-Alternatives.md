# Bulkrax Alternatives Analysis

## Context

This document evaluates alternatives to Bulkrax for bulk import of Congressional Records, given the current version gap (v8.3.0 vs v10.0.1) and Rails 8 migration challenges.

**TL;DR**: Bulkrax v10 upgrade is still the best option. See [[Bulk Import Strategy]] for decision framework.

---

## Alternative 1: Hyrax Native Bulk Import

### Overview

Hyrax/Hydra may have built-in bulk import capabilities not requiring Bulkrax.

### Pros
- ✅ No external dependencies
- ✅ Integrated with Hydra stack
- ✅ May have Rails 8 support

### Cons
- ❌ Limited functionality
- ❌ No OAI-PMH support (need custom parser)
- ❌ Minimal admin UI
- ❌ No field mapping
- ❌ No scheduling/retries
- ❌ Would still need 40+ hours customization

### Investigation Status

**Question**: What bulk import does Hydra provide?

**To Research**:
- Hyrax version and capabilities
- OAI-PMH importer availability
- Effort to build missing features

### Verdict

⚠️ **Unlikely to be better than Bulkrax** - would still require significant development to match feature parity.

---

## Alternative 2: Custom OAI-PMH Harvester

### Overview

Build a custom importer from scratch using raw OAI-PMH library.

```ruby
# Example architecture
app/jobs/oai_import_job.rb
app/services/oai_harvester.rb
app/services/congressional_record_mapper.rb
lib/oai/dc_parser.rb
```

### Pros
- ✅ Full control over implementation
- ✅ No dependency on external gem versions
- ✅ Could use any background job system
- ✅ Minimal dependencies

### Cons
- ❌ **160+ hours initial development**
- ❌ Reinvent everything Bulkrax handles:
  - OAI-PMH protocol implementation
  - Incremental/scheduled imports
  - Retry logic & error handling
  - CSV import capability
  - BagIt format support
  - Export functionality
  - Admin UI for managing imports
  - Field mapping/transformation
  - File upload handling
- ❌ **20 hours/month ongoing maintenance**
- ❌ Security considerations (URL validation, file handling)
- ❌ Performance optimization needed
- ❌ No community support
- ❌ Difficult to maintain/hand off
- ❌ Testing burden

### Effort Breakdown

| Task | Hours | Notes |
|------|-------|-------|
| OAI-PMH client library | 20 | Parse XML, handle pagination |
| Field mapping engine | 30 | Support transformations, validators |
| Background job processing | 20 | Queue, retry, error handling |
| Admin UI (web interface) | 40 | CRUD for importers, status display |
| Testing | 30 | Unit, integration, end-to-end |
| Documentation | 10 | Setup, troubleshooting guides |
| Deployment/DevOps | 10 | Docker, Kubernetes support |
| **Total** | **160+** | Plus 20h/month maintenance |

### Verdict

❌ **Not Recommended** - Cost/benefit heavily favors Bulkrax upgrade

---

## Alternative 3: Spotlight (Curator Focus)

### Overview

Spotlight is a curation & exhibition platform, not a bulk import tool.

```
Bulkrax v10 (Import)
       ↓
  Fedora + Solr
       ↓
Spotlight (Curation & Discovery)
```

### Capability Comparison

| Feature | Bulkrax | Spotlight |
|---------|---------|-----------|
| OAI-PMH Import | ✅ | ❌ |
| Bulk Ingest | ✅ | ❌ |
| Field Mapping | ✅ | ❌ |
| Automated Harvesting | ✅ | ❌ |
| Exhibits/Curation | ⚠️ Limited | ✅ |
| Discovery UI | ⚠️ Basic | ✅ |
| Featured Collections | ❌ | ✅ |
| Multi-exhibit support | ❌ | ✅ |

### Use Case

**Spotlight complements Bulkrax** but doesn't replace it.

**Recommended Architecture**:
```
OAI Feed → Bulkrax v10 → Fedora/Solr
                           ↓
                      Spotlight (optional)
```

For more details, see [[Spotlight Integration Guide]] (future doc).

### Verdict

✅ **Complementary tool, not replacement** - Consider after Bulkrax v10 is stable

---

## Alternative 4: API-Based Direct Import

### Overview

Upload CongressionalRecords via REST API calls instead of Bulkrax.

```ruby
# Example
while (oai_records = harvest_oai_feed)
  oai_records.each do |record|
    POST /api/congressional_records
    { title: "...", creator: "...", ... }
  end
end
```

### Pros
- ✅ Simple concept
- ✅ Direct integration with app

### Cons
- ❌ **Still 80+ hours development** (similar to custom harvester)
- ❌ No field mapping
- ❌ No retry/error handling
- ❌ No scheduling
- ❌ No admin UI
- ❌ Reinvent features Bulkrax provides
- ❌ Not RESTful (bulk operations shouldn't be API calls)
- ❌ Performance issues (one record at a time)

### Verdict

❌ **Not Recommended** - Worse than custom harvester, essentially same work

---

## Alternative 5: Bagit-Based Import (via Bulkrax)

### Overview

Export OAI-PMH to BagIt format, import via Bulkrax's BagIt parser.

```
OAI Feed → BagIt Export → Bulkrax BagIt Importer → Fedora
```

### Pros
- ✅ Uses existing Bulkrax v8.3.0 (no upgrade needed)
- ✅ Bagit standard, transferable format
- ✅ Preserves metadata integrity

### Cons
- ❌ Two-step process (harvest + import)
- ❌ Not real-time
- ❌ Requires separate harvesting tool
- ❌ Still stuck on v8.3.0 (doesn't solve Rails 8 problem)
- ❌ Adds complexity vs direct OAI import
- ⚠️ May be slower than direct import

### Verdict

⚠️ **Short-term stopgap only** - Doesn't solve version/Rails 8 issues

---

## Alternative 6: Use Hyku (Knapsack Alternative)

### Overview

Migrate to Hyku/Knapsack as a full alternative platform.

**wvu_knapsack** (sister project) uses Hyrax with similar metadata stack.

### Pros
- ✅ Modern Rails (likely already on 7+)
- ✅ Community maintained
- ✅ Bulkrax already integrated
- ✅ Would avoid ACDA fork maintenance

### Cons
- ❌ **Complete platform replacement**
- ❌ 300+ hours migration work
- ❌ Training & knowledge transfer
- ❌ Risk of data loss/corruption
- ❌ User interface completely changes
- ❌ May require policy/workflow redesign
- ❌ Not viable unless ACDA already planning Hyku move

### Verdict

❌ **Not Recommended** - Too drastic; only if organization already committed to Hyku migration

---

## Summary Decision Table

| Option | Effort | Rails 8 Ready | OAI Support | Verdict |
|--------|--------|---|---|---------|
| **Bulkrax v10 Upgrade** | 40-80h | ✅ | ✅ | 🌟 **BEST** |
| Maintain v8 Fork | 60-100h | ⚠️ | ✅ | ⚠️ Risky |
| Custom Harvester | 160h | ✅ | ✅ | ❌ Too costly |
| Hyrax Native | 40h+ | ✅ | ❌ | ❌ Insufficient |
| Spotlight | - | ✅ | ❌ | ✅ Complement |
| API-Based Import | 80h+ | ✅ | ✅ | ❌ Too costly |
| BagIt Workaround | 10h | ❌ | ⚠️ | ⚠️ Temporary |
| Migrate to Hyku | 300h | ✅ | ✅ | ❌ Overkill |

---

## Recommendation

✅ **Pursue Bulkrax v10 Upgrade** (Option A from [[Bulk Import Strategy]])

**Why**:
1. **Lowest risk**: Upgrade path is well-defined
2. **Rails 8 ready**: v10 has tested smoke tests
3. **Most cost-effective**: 40-80 hours vs 160+ for alternatives
4. **Community supported**: Official Samvera maintenance
5. **Proven solution**: OAI-PMH, field mapping, scheduling all battle-tested
6. **Security**: Automatic updates, no fork burden
7. **Future-proof**: Clear upgrade path for Rails 9+

**Next Steps**:
1. Schedule [[Bulk Import Strategy]] decision meeting
2. Create POC branch to test v10 compatibility
3. If successful, begin v10 upgrade implementation
4. After v10 stable, begin Rails 8 migration

---

**Document Status**: 📚 Reference Material  
**Last Updated**: November 18, 2026  
**See Also**: [[Bulk Import Strategy]]
