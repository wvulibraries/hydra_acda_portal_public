# Fixing Broken Identifiers and Thumbnails

Guide to identifying and fixing broken record identifiers and missing thumbnails.

## The Problem

During migrations and imports, some record identifiers may be changed or become misaligned with their internal IDs. This breaks:

1. **File path caching**: Thumbnails are cached with names derived from identifiers
2. **Bulkrax re-imports**: Uses identifier as the primary lookup key
3. **External links**: URLs to records break if identifiers change

### Example Issue

```
Original Record
├─ Identifier: wvul_am1500_b6_f01_0031
├─ Internal ID: wvul_am1500_b6_f01_0031
└─ Cached file: /tmp/thumbnails/wvul_am1500_b6_f01_0031.jpg ✅

After Migration
├─ Identifier: am1500_b6_f01_0033 (changed!)
├─ Internal ID: am1500_b6_f01_0033
└─ Cached file: /tmp/thumbnails/wvul_am1500_b6_f01_0031.jpg ❌ (points to old file)
```

Result: Image broken, record unfindable in re-imports

## Diagnosis

### Find Broken Records

```bash
# Access Rails console
docker compose exec web rails console

# Find records where identifier doesn't match ID
AcdaRecord.all.select { |r| r.identifier != r.id }

# Count affected records
AcdaRecord.where.not(identifier: AcdaRecord.pluck(:id)).count

# Export list to CSV
broken = AcdaRecord.where.not(identifier: AcdaRecord.pluck(:id))
CSV.open('broken_records.csv', 'w') do |csv|
  csv << ['ID', 'Current Identifier', 'Should Be']
  broken.each { |r| csv << [r.id, r.identifier, r.id] }
end
```

### Check Thumbnail Status

```bash
# In Rails console
record = AcdaRecord.find('am1500_b6_f01_0033')

# Check if thumbnail exists
record.thumbnail_path
# => "/tmp/thumbnails/wvul_am1500_b6_f01_0031.jpg"

# Check if file exists on disk
File.exist?(record.thumbnail_path)
# => false (broken!)

# Regenerate from PDF
record.generate_thumbnail_from_pdf!
```

## Solution: Two-Part Fix

### Part 1: Correct Identifiers

Use the provided rake task to fix identifier mismatches:

```bash
# View affected records
docker compose exec web rake identifiers:diagnose

# Export to CSV for review
docker compose exec web rake identifiers:export_mismatches[output/broken_records.csv]

# DRY RUN (don't apply changes)
docker compose exec web rake identifiers:fix_from_csv[broken_records.csv]

# APPLY CHANGES
docker compose exec web APPLY=true rake identifiers:fix_from_csv[broken_records.csv]
```

### Part 2: Regenerate Thumbnails

After fixing identifiers, regenerate thumbnails:

```bash
# Regenerate all thumbnails
docker compose exec web rake thumbnails:regenerate_all

# Regenerate from CSV list
docker compose exec web rake thumbnails:regenerate_from_csv[broken_records.csv]

# Monitor progress
docker compose exec web tail -f log/development.log | grep thumbnail
```

## Detailed Steps

### Step 1: Diagnose

Run diagnostic rake task to identify problems:

```bash
docker compose exec web rake identifiers:diagnose

# Output:
# Found 42 records with identifier mismatches
# Found 15 records with missing thumbnails
# Exported to: tmp/identifier_mismatches.csv
```

### Step 2: Review

Examine the CSV export:

```csv
id,current_identifier,should_be,has_thumbnail
wvul_am1500_001,am1500_001,wvul_am1500_001,false
wvul_am1500_002,am1500_002,wvul_am1500_002,false
```

Decide: should we fix these?

### Step 3: Backup

Before making changes, backup the database:

```bash
# PostgreSQL backup
docker compose exec db pg_dump -U postgres acda_portal_production > backup_$(date +%Y%m%d_%H%M%S).sql

# Fedora backup (if using Fedora)
docker compose exec fcrepo tar czf /tmp/fcrepo_backup.tar.gz /data/fcrepo/
```

### Step 4: Fix Identifiers

```bash
# DRY RUN first
docker compose exec web rake identifiers:fix_from_csv[broken_records.csv]

# Review output, then apply
docker compose exec web APPLY=true rake identifiers:fix_from_csv[broken_records.csv]

# Verify changes
docker compose exec web rails console
AcdaRecord.find('wvul_am1500_001').identifier
# => 'wvul_am1500_001' (now matches!)
```

### Step 5: Regenerate Thumbnails

```bash
# From CSV
docker compose exec web rake thumbnails:regenerate_from_csv[broken_records.csv]

# Or all thumbnails
docker compose exec web rake thumbnails:regenerate_all

# Verify
docker compose exec web rails console
AcdaRecord.find('wvul_am1500_001').thumbnail_path
# => '/data/thumbnails/wvul_am1500_001.jpg' ✅
```

### Step 6: Verify in UI

1. Go to http://localhost:3000
2. Search for record: "am1500_b6_f01_0031"
3. Verify image displays correctly
4. Check record detail page loads without errors

## Rake Tasks

### identifiers:diagnose
Scan database for identifier mismatches and missing thumbnails.

```bash
docker compose exec web rake identifiers:diagnose
```

### identifiers:export_mismatches[output_file]
Export list of broken records to CSV for review.

```bash
docker compose exec web rake identifiers:export_mismatches[broken_records.csv]
```

### identifiers:fix_single[current_id, new_identifier]
Test fix on a single record (DRY RUN by default).

```bash
# View what would change
docker compose exec web rake identifiers:fix_single[am1500_001,wvul_am1500_001]

# Apply change
docker compose exec web APPLY=true rake identifiers:fix_single[am1500_001,wvul_am1500_001]
```

### identifiers:fix_from_csv[csv_file]
Bulk fix from CSV file.

```bash
# DRY RUN
docker compose exec web rake identifiers:fix_from_csv[broken_records.csv]

# Apply
docker compose exec web APPLY=true rake identifiers:fix_from_csv[broken_records.csv]
```

### thumbnails:regenerate_from_csv[csv_file]
Regenerate thumbnails for records in CSV.

```bash
docker compose exec web rake thumbnails:regenerate_from_csv[broken_records.csv]
```

### thumbnails:regenerate_all
Regenerate all thumbnails (slow, only run on empty system).

```bash
docker compose exec web rake thumbnails:regenerate_all
```

## Important Notes

⚠️ **Backup First**: Always backup database before bulk changes

⚠️ **DRY RUN**: Always run without APPLY=true first

⚠️ **Review Changes**: Check CSV export before applying

⚠️ **Verify After**: Run diagnostic again to confirm fixes

## Preventing Future Issues

1. **Use stable identifiers**: Don't change identifiers after record creation
2. **Automated testing**: Include identifier validation in specs
3. **Bulkrax config**: Map field that never changes as identifier
4. **Regular audits**: Run `identifiers:diagnose` monthly

## Rollback Plan

If fixes cause problems:

```bash
# Restore from backup
docker compose down
mv data/postgres data/postgres.broken
# Restore from backup SQL
docker compose up

# Or revert Bulkrax entries
docker compose exec web rake identifiers:delete_bulkrax_entries[broken_records.csv]
```

---

See [[README]] for full wiki index.
