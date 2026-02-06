[![CircleCI](https://dl.circleci.com/status-badge/img/gh/wvulibraries/hydra_acda_portal_public/tree/main.svg?style=svg)](https://dl.circleci.com/status-badge/redirect/gh/wvulibraries/hydra_acda_portal_public/tree/main)

[![Maintainability](https://qlty.sh/gh/wvulibraries/projects/hydra_acda_portal_public/maintainability.svg)](https://qlty.sh/gh/wvulibraries/projects/hydra_acda_portal_public)

[![Code Coverage](https://qlty.sh/gh/wvulibraries/projects/hydra_acda_portal_public/coverage.svg)](https://qlty.sh/gh/wvulibraries/projects/hydra_acda_portal_public)

=======

# American Congress Digital Archives Portal (ACDA)

A collaborative, non-partisan digital repository that makes congressional archives available online, bringing the history of the People's Branch to the people.

## About

The American Congress Digital Archives Portal (ACDA) provides open access to the personal papers of Members of Congress from multiple institutions across the United States. Built on the Samvera Hydra framework with Rails 7 and Fedora 6, the portal aggregates geographically dispersed congressional collections into a single searchable platform, supporting scholarship about American democracy, civic education, and the legislative branch.

> **Repository Name**: This GitHub repository is named `hydra_acda_portal_public` where "acda" stands for American Congress Digital Archives.

**Production**: https://congressarchives.org  
**Development**: https://congressarchivesdev.lib.wvu.edu

### Project Background

This site is a prototype created with funding from the National Endowment for the Humanities (2021-2022). Unlike presidential papers which are centralized, congressional collections are geographically dispersed among institutions with varying resources. This portal addresses that challenge by:

- Aggregating materials from multiple archival institutions
- Providing easier, more equitable access to scholars, educators, and the public
- Supporting computational research and new methods of scholarly inquiry
- Serving as a resource for civic and history education

The project continues to expand partnerships, add archival collections, and improve functionality toward the nation's 250th anniversary in 2026 and beyond.

### Partner Institutions

- West Virginia University Libraries (Lead Institution)
- Robert J. Dole Institute of Politics, The University of Kansas
- Robert C. Byrd Center for Congressional History and Education

### What's In The Portal?

The portal features personal papers of Members of Congress, including:
- Correspondence and constituent communications
- Legislative files and policy materials
- Committee records and hearing documentation
- Campaign materials and political commercials
- Photographic and audiovisual collections

Collections span the twentieth and twenty-first centuries and document topics ranging from women's suffrage to foreign policy, civil rights to legislative processes.

### Featured Collections

- **Women's Suffrage and the 19th Amendment**: Constituent correspondence examining women's suffrage and Congress as a representative body
- **International Affairs and Foreign Policy**: Materials related to the Panama Canal Treaty, the 1982 Lebanon War, and efforts regarding Armenian genocide recognition
- **Vietnam War POW/MIA Efforts**: Congressional efforts to bring home American Prisoners of War and Missing in Action
- **Julian P. Kanter Political Commercial Collection**: The world's largest collection of political commercials, covering all levels of political campaigning from Presidential elections to ballot initiatives

## Documentation

For detailed documentation, see the [`docs/`](./docs/) directory:

- [Development Setup](./docs/development.md) - Detailed development environment setup
- [Deployment Guide](./docs/deployment.md) - Deployment procedures and configurations  
- [Architecture Overview](./docs/architecture.md) - Technical architecture and components
- [Troubleshooting](./docs/troubleshooting.md) - Common issues and solutions
- [API Reference](./docs/api.md) - API documentation

---

## Technical Overview

This application is built on Samvera Hydra 11 and serves as the technical infrastructure for the ACDA Portal (congressarchives.org).

## Quick Start

### Prerequisites

- Docker and Docker Compose
- VPN access to WVU network (required for Fedora/Solr connectivity)

### Running the Application

**Development:**
```bash
./up.sh
```

The application will be available at `http://localhost:3000`

**Stopping:**
```bash
./down.sh
```

### Default Credentials

Development admin access is configured via environment variables in the `env/` directory.

## Architecture

### Stack Components

- **Rails Application**: Ruby 3.3.5 with Rails 7.0.8
- **Samvera Hydra**: Hydra-head framework with Active Fedora
- **Fedora Commons**: 6.5.1 (fcrepo/fcrepo:6.5.1-tomcat9)
- **Solr**: 9.8.0
- **PostgreSQL**: 16 (Alpine)
- **Redis**: Alpine (latest)
- **Memcached**: 1.6.22 (Alpine)
- **Sidekiq**: Background job processing with cron scheduling
- **Bulkrax**: Batch import framework

### Key Dependencies

- **Blacklight**: Discovery interface framework
- **Active Fedora**: Object-relational mapping for Fedora repositories
- **Sidekiq**: Background job processing with cron scheduling
- **Bulkrax**: Batch metadata and file import capabilities
- **Blacklight OAI Provider**: OAI-PMH protocol support
- **Devise**: Authentication framework
- **MiniMagick**: Image processing for thumbnails

### Key Directories

- `hydra/` - Rails application root
- `fcrepo/` - Fedora repository configuration
- `solr9-setup/` - Solr core configuration
- `scripts/` - Utility scripts for deployment and maintenance
- `env/` - Environment configuration files

### Docker Services Architecture

The application runs as a multi-container Docker environment:

- **web** (`acda_portal`): Main Rails application server (port 3000)
- **workers** (`sidekiq`): Background job processor with Sidekiq
- **fcrepo**: Fedora Commons repository (port 8080)
- **solr**: Solr search engine (port 8983)
- **db**: PostgreSQL database (port 5432)
- **redis**: Redis cache and job queue (port 6379)
- **memcached**: Memory caching layer (port 11211)

All services communicate over a bridged Docker network (`br-hydra-ca`).

### Data Persistence

Persistent data is stored in the `./data/` directory and mounted as volumes:

- `data/fcrepo/` - Fedora repository storage
- `data/solr/` - Solr index data
- `data/postgres/` - PostgreSQL database
- `data/redis/` - Redis persistence
- `data/logs/` - Application and service logs
- `data/imports/` - Import staging area
- `data/exports/` - Export output
- `data/thumbnails/` - Generated thumbnails
- `data/images/` - Processed images
- `data/pdf/` - PDF processing cache

### Health Checks

All critical services include health checks:

- **Fedora**: HTTP check on port 8080/fcrepo (5s interval, 20 retries)
- **Solr**: HTTP check on port 8983 (5s interval, 20 retries)
- **PostgreSQL**: pg_isready check (30s interval, 80s start period)
- **Redis**: Redis PING command with authentication (30s interval)

## Development

See [DEVELOPMENT.md](DEVELOPMENT.md) for detailed development instructions.

### Database Setup

If you encounter database errors:

```bash
docker exec -it acda_portal rake db:create
docker exec -it acda_portal rake db:migrate
```

### Accessing the Container

```bash
# Access the main Rails application container
docker exec -it acda_portal sh

# Access the Sidekiq worker container
docker exec -it sidekiq sh
```

### Importing Content

Content import is managed through Bulkrax. Access the importer interface at:

```
http://localhost:3000/importers?locale=en
```

Use the credentials configured in your environment files.

### Clearing Development Data

**WARNING: Development only - never run in production**

```bash
docker exec -it acda_portal sh
RAILS_ENV=development ruby import/explode_fcrepo_solr.rb
```

## OAI-PMH

The repository supports OAI-PMH harvesting for metadata aggregation.

### Endpoint

**Production**: `https://congressarchives.org/catalog/oai`  
**Development**: `https://congressarchivesdev.lib.wvu.edu/catalog/oai`

### Supported Metadata Formats

- Dublin Core (oai_dc)

### DC Terms Mappings

- title
- creator
- subject
- publisher
- date
- type
- identifier
- language
- source
- rights
- format

### Provider Configuration

See `hydra/app/controllers/catalog_controller.rb` for OAI provider settings including:
- Repository name
- Repository URL
- Admin contact
- Record limits

## Deployment

### Automated Releases

This repository uses GitHub releases for automated deployment:

- **Development**: Create a pre-release tag. The dev server will automatically pull and deploy within ~5 minutes.
- **Production**: Edit your pre-release and mark it as "latest release" to trigger production deployment.

### Manual Deployment

Docker Compose configurations are provided for different environments:
- `docker-compose.yml` - Production
- `docker-compose.dev.yml` - Development
- `docker-compose.dev.debug.yml` - Development with debugging enabled

## Key Features

- **Multi-Institutional Aggregation**: Brings together congressional archives from geographically dispersed repositories
- **Advanced Search & Discovery**: Comprehensive search across multiple metadata fields including Creator, Congress, Policy Area, Location Represented, and more
- **Curated Content**: Featured collections highlighting significant topics in congressional history
- **Educational Resources**: Materials supporting civic education and scholarly research
- **OAI-PMH Support**: Metadata harvesting for aggregators and research tools
- **Flexible Faceting**: Browse by contributing institution, collection, subject, record type, date range, and congressional session
- **Open Access**: Free public access to archival materials and descriptive metadata

## Project Structure

### Models

Key models in the application:

- **Main Model** (`app/models/`) - Contains collection-specific metadata properties
- **ImageFile** (`image_file.rb`) - Manages file objects in Fedora
- **SearchBuilder** (`search_builder.rb`) - Limits search scope to specific collections

### Controllers

- **CatalogController** - Configures search, facets, and OAI-PMH
- **ApplicationController** - Base controller with authentication and authorization

### Views & Customization

- Custom styling in `hydra/app/assets/stylesheets/`
- JavaScript customizations in `hydra/app/assets/javascripts/`
- Collection-specific banner images and branding

## Configuration

### Required Environment Variables

Configuration is managed through files in the `env/` directory. Key variables include:
- Database credentials
- Fedora connection details
- Solr endpoints
- Admin user credentials
- Application secrets

## Network Requirements

**VPN Access Required**: Development and production environments require VPN connection to access Fedora and Solr storage. Operations including data loading, importing, and deletion will fail without proper network access.

## Troubleshooting

### Common Issues

1. **Database Connection Errors**: Check database name in `config/database.yml` matches your Docker Compose configuration
2. **Fedora/Solr Access**: Ensure VPN connection is active
3. **Import Failures**: Verify file paths and permissions in the import directory
4. **Image Display Issues**: Check viewer configuration in views and ensure file uploads completed successfully

## Contributing

This repository is for the American Congress Digital Archives Portal (ACDA) project. For information about becoming a partner institution or contributing collections, visit https://congressarchives.org/contribute

## Funding & Support

This project was made possible by:
- National Endowment for the Humanities (NEH)
- National Historical Publications and Records Commission (NHPRC)
- LYRASIS

## Project Documentation

- [White Paper](https://researchrepository.wvu.edu/faculty_publications/3090/)
- [Project Briefing Video](https://www.cni.org/topics/special-collections/american-congress-digital-archives-portal-project)

## Contact

**Project Director**: Danielle Emerling, West Virginia University  
**Repository**: https://github.com/wvulibraries/hydra_acda_portal_public  
**Donate**: https://give.wvu.edu/congress-archives-project

## Acknowledgments

Built with the Samvera Hydra framework and maintained by West Virginia University Libraries in partnership with multiple congressional archival institutions. Special thanks to the project team, advisory board, and all contributing partner institutions.

For a complete list of team members and advisory board, visit: https://congressarchives.org/about
