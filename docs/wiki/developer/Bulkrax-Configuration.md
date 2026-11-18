# Bulkrax Configuration Guide

## Overview

Bulkrax provides a web-based interface for configuring and managing bulk imports of Congressional Records via OAI-PMH feeds.

## Current Configuration

### Initializer Location

```
hydra/config/initializers/bulkrax.rb
```

### Basic Setup

```ruby
Bulkrax.setup do |config|
  # Default work type for imports
  config.default_work_type = 'CongressionalRecord'
  
  # Job queue settings
  config.import_job_class = 'Bulkrax::ImportJob'
  config.export_job_class = 'Bulkrax::ExportJob'
  
  # Field mappings for OAI-PMH Dublin Core
  config.field_mappings = {
    "Bulkrax::OaiDcParser" => {
      "title" => { from: ["dc:title"] },
      "creator" => { from: ["dc:creator"] },
      "subject" => { from: ["dc:subject"] },
      "description" => { from: ["dc:description"] },
      "date_created" => { from: ["dc:date"] },
      "identifier" => { from: ["dc:identifier"] },
      "rights" => { from: ["dc:rights"] },
    }
  }
  
  # Parsers available in this application
  config.parsers = [
    "Bulkrax::OaiDcParser",
    "Bulkrax::OaiQdcParser", 
    "Bulkrax::CsvParser",
    "Bulkrax::BagitParser"
  ]
end
```

## OAI-PMH Importer Setup

### Configuration Steps

1. **Navigate to Bulkrax Admin**:
   ```
   http://localhost:3000/bulkrax/importers
   ```

2. **Create New Importer**:
   - Click "New Importer"
   - Select Parser: `OAI-PMH Dublin Core`
   - Name: "Congressional Records"

3. **Set OAI-PMH Parameters**:
   ```
   OAI-PMH URL: https://acda.wvu.edu/oai
   Metadata Prefix: oai_dc (or oai_qdc for qualified Dublin Core)
   Set: congressional-records (optional, filters to specific subset)
   From Date: (blank or YYYY-MM-DD)
   Until Date: (blank or YYYY-MM-DD)
   ```

4. **Field Mappings**:
   Map OAI metadata fields to CongressionalRecord model attributes:
   ```
   oai_dc:title → title
   oai_dc:creator → creator
   oai_dc:subject → subject
   oai_dc:description → description
   oai_dc:date → date_created
   oai_dc:identifier → identifier
   oai_dc:type → resource_type
   ```

5. **Import Settings**:
   - Frequency: One-time, Hourly, Daily, Weekly, Monthly
   - User: Select importer owner
   - File Path (if uploading): (not used for OAI-PMH)

### Testing the Configuration

```bash
# Start console
rails console

# Create OAI importer programmatically
require 'bulkrax/importer'

importer = Bulkrax::Importer.create(
  name: "Test OAI Import",
  user_id: User.admin.first.id,
  parser_klass: "Bulkrax::OaiDcParser",
  parser_fields: {
    "oai_url" => "https://acda.wvu.edu/oai",
    "oai_set" => "congressional-records",
    "metadata_prefix" => "oai_dc"
  }
)

# Queue the import job
importer.start!
```

## Field Mappings

### Congressional Records Mapping

**OAI-PMH Dublin Core → CongressionalRecord**:

| OAI Field | CongressionalRecord Field | Type | Example |
|-----------|---------------------------|------|---------|
| dc:title | title | String | "H.R. 123 - Education Reform Act" |
| dc:creator | creator | String | "Congress, U.S." |
| dc:subject | subject | String | "Education", "Legislation" |
| dc:description | description | Text | "Full text of the bill..." |
| dc:date | date_created | Date | "2024-01-15" |
| dc:identifier | identifier | String | "hr-123-118congress" |
| dc:type | resource_type | String | "Bill", "Resolution" |
| dc:coverage | coverage | String | "United States" |
| dc:source | source | String | "Congress.gov" |
| dc:language | language | String | "en" |

### Advanced Mapping Features

**Multiple Source Fields**:
```ruby
"creator" => { 
  from: ["dc:creator", "dc:contributor"],
  source_identifier: true  # Use as unique identifier
}
```

**Conditional Mappings**:
```ruby
"resource_type" => {
  from: ["dc:type"],
  parsed: "CongressionalResourceTypeService"  # Use authority lookup
}
```

**Transform Functions**:
```ruby
"date_created" => {
  from: ["dc:date"],
  parsed: "CongressionalDateParser"  # Custom transformation
}
```

## Import Job Processing

### Background Job Status

Bulkrax uses `good_job` for background processing:

```bash
# Check job status
http://localhost:3000/bulkrax/importers/:id

# Manual job triggering
rails console
importer = Bulkrax::Importer.find(1)
importer.update(import_type: :start, # or :delete, :update
                override_errors: true)
importer.start! # Queue the job
```

### Job Queue Configuration

```yaml
# config/good_job.yml
---
max_threads: 4
max_cache: 0
poll_interval_seconds: 30
queues:
  - name: default
    threads: 2
  - name: import
    threads: 2
  - name: export
    threads: 2
```

## Troubleshooting

### Import Fails to Start

**Symptoms**: Import stuck on "Scheduled" status

**Solutions**:
```bash
# Check good_job logs
GoodJob::Job.where(queue_name: 'import').recent.limit(10)

# Manually retry
GoodJob::Job.where(active_job_id: 'xxx').first.retry

# Check database
rails console
Bulkrax::Importer.find(1).entries.failed
```

### Field Mapping Issues

**Symptoms**: Fields not populating correctly

**Check**:
1. OAI feed actually contains the field
2. Field name in mapping is exact (case-sensitive)
3. CongressionalRecord model has the attribute
4. No validation errors preventing save

```ruby
rails console
entry = Bulkrax::Entry.find(1)
entry.parsed_metadata  # View raw parsed values
entry.attributes       # View saved attributes
entry.errors.messages  # Check validation errors
```

### Large Import Performance

**Optimization Tips**:

```ruby
# Bulkrax config
config.import_visibility = 'restricted'  # Avoid Fedora updates
config.ingest_queue = 'import'
config.max_import_size = 50 # Records per job

# Solr
config.index_visibility_level = false  # Index after import complete
```

## Monitoring Imports

### Admin Dashboard

Access at: `/bulkrax/importers`

Shows:
- Import status (Scheduled, Running, Complete)
- Number of records processed
- Error count & types
- Estimated completion time
- Last run timestamp

### Metrics & Logging

```ruby
# In logs, look for:
# - "Bulkrax::ImportJob perform"
# - "Bulkrax::ImporterRun created"
# - Timing info: "Completed in XXms"

# Check import runs
Bulkrax::ImporterRun.where(importer_id: 1).recent
  .select(:id, :importer_id, :total_records, :processed_records, :failed_records, :created_at)
```

## Security Considerations

### Access Control

```ruby
# In ability.rb
can :manage, [Bulkrax::Importer, Bulkrax::Exporter] if user.admin?
```

### File Upload Safety

For CSV/BagIt uploads:
- Validate file type
- Scan for malicious content
- Limit file size
- Use temporary directories

```ruby
Bulkrax.setup do |config|
  config.uploads_path = 'tmp/bulkrax_uploads'
  config.maximum_file_size = 1.gigabyte
  config.allowed_file_types = ['csv', 'zip', 'tar', 'gz']
end
```

## Related Documentation

- [[Field Mappings]] - Detailed field mapping reference
- [[Bulk Import Strategy]] - Version upgrade planning
- [[Import Troubleshooting]] - Common issues & solutions

---

**Last Updated**: November 18, 2026  
**Status**: Current for Bulkrax v8.3.0  
**Note**: Will require updates for v10.0.1 upgrade
