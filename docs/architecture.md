# Architecture Overview

This document describes the technical architecture of the American Congress Digital Archives Portal.

## System Overview

The ACDA Portal is built on the Samvera Hydra framework, providing a digital repository for congressional archives with advanced search and discovery capabilities.

## Technology Stack

### Core Framework
- **Ruby on Rails 7.0.8** - Web application framework
- **Ruby 3.3.5** - Runtime environment
- **Samvera Hydra 11** - Digital repository framework

### Data Storage
- **Fedora Commons 6.5.1** - Digital object repository
- **PostgreSQL 16** - Metadata and application database
- **Solr 9.8.0** - Search and indexing engine

### Infrastructure
- **Redis** - Caching and background job queue
- **Memcached** - Additional caching layer
- **Sidekiq** - Background job processing
- **Docker** - Containerization

### Key Libraries
- **ActiveFedora** - Fedora object mapping
- **Blacklight** - Search interface
- **Bulkrax** - Batch import framework
- **Devise** - Authentication
- **MiniMagick** - Image processing

## Application Architecture

### MVC Structure

```
hydra/
├── app/
│   ├── controllers/     # Request handling
│   ├── models/         # Data models and business logic
│   ├── views/          # Presentation templates
│   ├── helpers/        # View helpers
│   └── services/       # Business logic services
├── config/             # Application configuration
├── lib/               # Shared libraries
├── db/                # Database migrations and seeds
└── spec/              # Test suite
```

### Key Components

#### Models
- **Main Model** - Core collection metadata
- **ImageFile** - File object management
- **SearchBuilder** - Search scope limitations

#### Controllers
- **CatalogController** - Search and discovery interface
- **ApplicationController** - Base controller with auth

#### Services
- Background processing with Sidekiq
- Import/export operations
- Image processing and thumbnails

## Data Architecture

### Repository Structure

```
Fedora Repository (fcrepo)
├── Collections
│   ├── Metadata (DC, MODS, etc.)
│   └── Files (PDF, images, etc.)
└── Administrative metadata
```

### Search Index

```
Solr Core (hydra_dev)
├── Documents (indexed metadata)
├── Facets (collection, subject, date, etc.)
└── Search configurations
```

### Database Schema

```
PostgreSQL
├── Users and permissions
├── Import jobs (Bulkrax)
├── Application metadata
└── Audit logs
```

## Service Architecture

### Docker Services

```
┌─────────────────┐    ┌─────────────────┐
│   Web (Rails)   │────│   Sidekiq       │
│   Port: 3000    │    │   Workers       │
└─────────────────┘    └─────────────────┘
         │                       │
         ├───────────────────────┼───────────────────────┐
         │                       │                       │
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   PostgreSQL    │    │     Redis       │    │   Memcached     │
│   Port: 5432    │    │   Port: 6379    │    │   Port: 11211   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐    ┌─────────────────┐
                    │     Fedora      │    │      Solr       │
                    │   Port: 8080    │    │   Port: 8983    │
                    └─────────────────┘    └─────────────────┘
```

### Network Architecture

- **Bridge Network**: `br-hydra-ca` for service isolation
- **Service Discovery**: Docker internal DNS
- **External Access**: Port mapping for web interface

## Data Flow

### Content Ingestion

1. **Upload** → Bulkrax importer
2. **Validation** → Metadata processing
3. **Storage** → Fedora repository
4. **Indexing** → Solr search engine
5. **Caching** → Redis/Memcached

### Search and Discovery

1. **Query** → Blacklight interface
2. **Search** → Solr query
3. **Results** → Faceted results
4. **Display** → Rails views
5. **Caching** → Redis for performance

### File Access

1. **Request** → Rails controller
2. **Authorization** → Permission checks
3. **Retrieval** → Fedora API
4. **Processing** → Image/thumbnail generation
5. **Delivery** → HTTP response

## Security Architecture

### Authentication
- **Devise** for user management
- **LDAP/SSO** integration (configurable)
- **Role-based access control**

### Authorization
- **Controller-level permissions**
- **Model-level access controls**
- **File-level restrictions**

### Network Security
- **VPN required** for data access
- **Container isolation** via Docker
- **Encrypted connections** (SSL/TLS)

## Performance Considerations

### Caching Strategy
- **Redis** for session and fragment caching
- **Memcached** for object caching
- **CDN** for static assets (production)

### Optimization
- **Database indexing** on search fields
- **Lazy loading** for large result sets
- **Background processing** for intensive tasks

### Monitoring
- **Health checks** for all services
- **Log aggregation** and analysis
- **Performance metrics** collection

## Scalability

### Horizontal Scaling
- **Load balancer** for web containers
- **Database read replicas**
- **Search index sharding**

### Vertical Scaling
- **Resource limits** per container
- **JVM tuning** for performance
- **Connection pooling** optimization

## Backup and Recovery

### Data Persistence
- **Docker volumes** for data durability
- **Regular backups** of all volumes
- **Point-in-time recovery** capabilities

### Disaster Recovery
- **Multi-region deployment** option
- **Automated failover** procedures
- **Data replication** strategies

## Development Architecture

### Local Development
- **Docker Compose** for service orchestration
- **Volume mounting** for code changes
- **Hot reloading** for development

### Testing
- **RSpec** for unit and integration tests
- **Capybara** for feature tests
- **FactoryBot** for test data

### CI/CD
- **GitHub Actions** for automated testing
- **Docker Hub** for image building
- **Automated deployment** via releases