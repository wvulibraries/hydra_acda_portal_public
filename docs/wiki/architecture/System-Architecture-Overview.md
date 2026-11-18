# System Architecture Overview

Technical architecture and component overview of the ACDA Portal.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    USER INTERFACE LAYER                         │
│  Web Browser → Blacklight Discovery + Customizations           │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                   APPLICATION LAYER (Rails 7)                  │
│  ├─ Controllers (Catalog, Authentication)                      │
│  ├─ Models (CongressionalRecord, ImageFile)                    │
│  ├─ Views (ERB templates with custom CSS/JS)                   │
│  └─ Background Jobs (good_job for async processing)            │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                      DATA LAYER                                 │
│  ├─ PostgreSQL (Primary data store)                             │
│  ├─ Fedora 6 (File preservation)                               │
│  ├─ Solr 9 (Search index)                                       │
│  ├─ Redis (Caching & job queue)                                │
│  └─ Memcached (HTTP caching)                                   │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                   DATA INGESTION (Bulkrax)                      │
│  OAI-PMH Feeds → CSV → Field Mapping → PostgreSQL/Fedora       │
└─────────────────────────────────────────────────────────────────┘
```

## Technology Stack

### Core Framework
- **Ruby**: 3.3.5
- **Rails**: 7.0.8 (planning Rails 8 upgrade)
- **Framework**: Samvera Hydra with Blacklight

### Storage & Indexing
- **Database**: PostgreSQL 16
- **File Storage**: Fedora Commons 6.5.1
- **Search Index**: Solr 9.8.0
- **Cache**: Redis (Alpine) + Memcached 1.6.22

### Bulk Import
- **Bulkrax**: v8.3.0 (custom Rails 7 support branch)
- **OAI-PMH Support**: Via blacklight_oai_provider
- **Job Processing**: good_job (PostgreSQL-backed)

### Frontend
- **Discovery UI**: Blacklight 7.40.0
- **UI Framework**: Bootstrap 5.1
- **Frontend Libraries**: jQuery, TypeScript

## Docker Services

### Production Docker Compose Architecture

| Service | Image | Port | Purpose |
|---------|-------|------|---------|
| **web** | Rails app | 3000 | Main application server |
| **workers** | Rails app | - | Background job processor (good_job) |
| **fcrepo** | fcrepo/fcrepo:6.5.1 | 8080 | Fedora repository |
| **solr** | solr:9.8.0 | 8983 | Solr search index |
| **db** | postgres:16 | 5432 | PostgreSQL database |
| **redis** | redis:alpine | 6379 | Cache & job queue |
| **memcached** | memcached:1.6.22 | 11211 | HTTP cache layer |

### Service Dependencies

```
web service
  ├─ depends_on: db, redis, fcrepo, solr
  ├─ connects to: PostgreSQL (5432)
  ├─ connects to: Fedora (8080)
  ├─ connects to: Solr (8983)
  ├─ connects to: Redis (6379)
  └─ connects to: Memcached (11211)

workers service
  ├─ depends_on: db, redis, fcrepo, solr
  └─ processes: good_job background jobs

fcrepo service
  ├─ depends_on: nothing
  └─ http://fcrepo:8080/fcrepo/

solr service
  ├─ depends_on: nothing
  └─ http://solr:8983/solr/

db service
  ├─ depends_on: nothing
  └─ postgres://db:5432

redis service
  ├─ depends_on: nothing
  └─ redis://redis:6379
```

## Data Persistence

Persistent data is stored in `./data/` directory:

```
data/
├── fcrepo/          # Fedora repository storage
├── solr/            # Solr index & configuration
├── postgres/        # PostgreSQL database files
├── redis/           # Redis persistence
├── logs/            # Application and service logs
├── imports/         # Import staging area
├── exports/         # Export output
├── thumbnails/      # Generated thumbnails
├── images/          # Processed images
└── pdf/             # PDF processing cache
```

## Application Structure

### Key Directories

```
hydra/                           # Rails application root
├── app/
│   ├── controllers/             # Request handlers
│   │   └── catalog_controller.rb # Main search controller
│   ├── models/                  # Data models
│   │   ├── congressional_record.rb
│   │   └── image_file.rb
│   ├── views/                   # ERB templates
│   │   └── catalog/             # Search results, detail views
│   ├── jobs/                    # Background jobs
│   │   └── import_job.rb
│   └── services/                # Business logic
│       └── search_builder.rb
├── config/
│   ├── initializers/
│   │   └── bulkrax.rb          # Bulkrax configuration
│   ├── routes.rb               # URL routing
│   └── database.yml            # Database configuration
├── db/
│   ├── migrate/                # Database migrations
│   └── seeds.rb                # Initial data
└── spec/                       # RSpec tests

solr9-setup/                     # Solr configuration
├── conf/
│   ├── solrconfig.xml          # Solr core configuration
│   └── schema.xml              # Field definitions

fcrepo/                          # Fedora configuration
├── Dockerfile
└── config/

scripts/                         # Utility scripts
├── deploy.sh
└── health-check.sh

docs/                            # Documentation
└── wiki/                        # This wiki
    ├── README.md
    ├── Quick-Start-Guide.md
    ├── Development-Guide.md
    └── ... (other guides)
```

### Core Models

#### CongressionalRecord (Primary Model)
```ruby
# Main metadata model for Congressional Records
CongressionalRecord < ApplicationRecord
  # Key fields:
  - title: String
  - creator: String
  - subject: String (array)
  - description: Text
  - date_created: Date
  - identifier: String (unique)
  - resource_type: String
  - rights: String
  - language: String
  - source: String
  
  # Relationships:
  - has_many :image_files
  - has_many_attached :thumbnails
  - has_many_attached :derived_files
  
  # Fedora integration:
  - stored in: Fedora (via active-fedora)
  - indexed in: Solr (via solrizer)
```

#### ImageFile (File Model)
```ruby
# Manages file objects in Fedora
ImageFile < ApplicationRecord
  - belongs_to :congressional_record
  - has_one_attached :file
  - has_one_attached :thumbnail
  
  # File metadata:
  - original_filename: String
  - mime_type: String
  - file_size: Integer
```

## Data Flow

### Import Flow (Bulkrax)
```
OAI-PMH Feed
    ↓ (harvest)
Bulkrax Parser (OAI-PMH DC)
    ↓ (field mapping)
CongressionalRecord Model
    ↓ (save)
PostgreSQL + Fedora
    ↓ (index)
Solr
    ↓ (discover)
Blacklight UI
    ↓ (display)
User Browser
```

### Search Flow
```
User Query
    ↓ (input)
Blacklight Controller
    ↓ (build query)
Solr Query Builder
    ↓ (search)
Solr 9
    ↓ (results)
Solr Response
    ↓ (render)
Blacklight View
    ↓ (display)
User Browser
```

## Health Checks & Monitoring

All services include health checks configured in docker-compose:

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8080/fcrepo/"]
  interval: 5s
  timeout: 3s
  retries: 20
  start_period: 10s
```

Health check endpoints:
- **Fedora**: `http://fcrepo:8080/fcrepo/`
- **Solr**: `http://solr:8983/solr/`
- **PostgreSQL**: `pg_isready -h db -U postgres`
- **Redis**: Redis PING command

## Database Schema Overview

### Key Tables

- **congressional_records** - Primary record metadata
- **image_files** - File references
- **users** - Authentication & authorization
- **bulkrax_importers** - Import configurations
- **bulkrax_entries** - Individual import records
- **solr_documents** - Search index metadata
- **active_storage_blobs** - File storage
- **active_storage_attachments** - File associations

## Security Architecture

### Authentication
- **Devise**: User authentication with email/password
- **Roles**: Admin, Editor, User

### Authorization
- **Hydra::AccessControls**: Object-level permissions
- **Ability.rb**: Cancancan permission rules

### File Access
- **Fedora ACLs**: Repository-level access control
- **Rails Policies**: Application-level authorization

## Performance Considerations

### Caching
- **Redis**: Job queue & session storage
- **Memcached**: HTTP fragment caching
- **Rails Cache**: Query result caching

### Indexing
- **Solr**: Full-text search index
- **Database Indexes**: PostgreSQL query optimization
- **Fedora**: File versioning (optional)

### Background Jobs
- **good_job**: PostgreSQL-backed job processing
- **Scheduled Tasks**: Cron-like scheduling
- **Priority Queue**: Job prioritization by queue

## Modernization Path

**Current**: Fedora + PostgreSQL hybrid (overengineered for a discovery aggregator)  
**Future**: PostgreSQL + ActiveRecord + Solr (simplification initiative)

See [[Architecture Decision Records]] for detailed rationale.

---

See [[README]] for full wiki index.
