# Rake Tasks Implementation

## Overview

Two comprehensive rake tasks have been implemented to support bulk identifier repair and thumbnail regeneration workflows. These tasks are part of the maintenance and data integrity tooling for the ACDA Portal.

## Completed Tasks

### 1. Fix Broken Identifiers (`fix_broken_identifiers.rake`)

**Location:** `hydra/lib/tasks/fix_broken_identifiers.rake` (252 lines)  
**Status:** ✅ Fully Implemented

#### Available Tasks:

- **`identifiers:diagnose`** - Scan database for ID/identifier mismatches and report problematic records
- **`identifiers:export_mismatches[output_file]`** - Export mismatched records to CSV for review
- **`identifiers:fix_single[current_id,new_identifier]`** - Test fix on a single record with DRY RUN support
- **`identifiers:fix_from_csv[csv_file]`** - Bulk repair from CSV mapping file
- **`identifiers:delete_bulkrax_entries[csv_file]`** - Delete Bulkrax entries associated with specific identifiers
- **`identifiers:list_wvul`** - List all records with wvul_ prefix

#### Key Features:

- **DRY RUN mode** via `APPLY=true` environment variable (default is preview)
- **File path migration** - Automatically moves thumbnail/image/PDF files from old ID paths to new ID paths
- **Per-record error handling** - Continues processing on individual failures
- **CSV import/export** - Standard formats for integration with spreadsheets

#### Usage Examples:

```bash
# Diagnose issues
bundle exec rake identifiers:diagnose

# Export for review
bundle exec rake identifiers:export_mismatches[review.csv]

# Test fix on single record (preview mode)
bundle exec rake identifiers:fix_single[old_id,new_identifier]

# Apply fix to single record
bundle exec rake identifiers:fix_single[old_id,new_identifier] APPLY=true

# Bulk fix from CSV (preview)
bundle exec rake identifiers:fix_from_csv[fixes.csv]

# Bulk fix from CSV (apply)
bundle exec rake identifiers:fix_from_csv[fixes.csv] APPLY=true
```

### 2. Regenerate Thumbnails (`regenerate_thumbnails.rake`)

**Location:** `hydra/lib/tasks/regenerate_thumbnails.rake` (213 lines)  
**Status:** ✅ Fully Implemented

#### Available Tasks:

- **`thumbnails:diagnose`** - Report which records are missing thumbnails
- **`thumbnails:regenerate`** - Bulk regenerate all missing thumbnails from PDF sources
- **`thumbnails:regenerate_batch[id1,id2,id3]`** - Regenerate specific record thumbnails

#### Key Features:

- **PDF download** - Fetches PDFs from `available_by` URLs
- **Image generation** - Converts first PDF page to JPG using MiniMagick
- **Fedora attachment** - Properly attaches generated thumbnail to record
- **Automatic cleanup** - Removes temporary files after processing
- **DRY RUN mode** - Preview changes with `APPLY=true` to execute

#### Usage Examples:

```bash
# Diagnose missing thumbnails
bundle exec rake thumbnails:diagnose

# Preview thumbnail regeneration
bundle exec rake thumbnails:regenerate

# Regenerate thumbnails (apply)
bundle exec rake thumbnails:regenerate APPLY=true

# Regenerate specific records
bundle exec rake thumbnails:regenerate_batch[record_id_1,record_id_2]
```

## Testing

Both tasks were developed using test-driven approach with:

- **Sample data:** `data/imports/1_20260812203120/Test4tracy.csv`
- **Test records:** Records prefixed with `am1414_b01_f01_*`
- **Local validation:** Tested with local dev environment before deployment

## Implementation Details

### Database Models Used

- **Acda** - Main record model with identifier and thumbnail_file properties
- **Bulkrax::Entry** - For tracking bulk import entries

### File Locations

- **Thumbnails:** `/home/hydra/tmp/thumbnails/{id}.jpg`
- **Images:** `/home/hydra/tmp/images/{id}.jpg`
- **PDFs:** `/home/hydra/tmp/pdf/{id}.pdf`

### Key Dependencies

- **MiniMagick** - Image conversion (PDF → JPG)
- **ImportLibrary** - Fedora file attachment utility
- **Rails environment** - Standard rake tasks with Rails context

## Error Handling

Both tasks include comprehensive error handling:

- Record-level error catching to allow batch processing to continue
- Detailed logging of success/failure per record
- File operation safety checks (verify existence before overwrite)
- Retry logic for temporary failures

## Related Documentation

- [Fixing Broken Identifiers](/docs/wiki/Fixing-Broken-Identifiers.md) - User guide for identifier repair workflows
- [Bulk Import Strategy](/docs/wiki/Bulk-Import-Strategy.md) - Overview of import processes
- [System Architecture Overview](/docs/wiki/System-Architecture-Overview.md) - System design and components

## Task Tracking

**Agent Task Reference:** `projects/hydra_acda_portal_public/tasks/completed/QWEN_TASK_RAKE_IMPLEMENTATION.md`

This work was completed as part of the ACDA Portal maintenance tooling initiative.
