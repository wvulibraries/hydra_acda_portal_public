# Development Setup (Internal)

This document provides setup instructions for ACDA Portal development.

## Prerequisites

- Docker and Docker Compose
- WVU VPN access (REQUIRED for Fedora/Solr connectivity)
- Git access to repository
- At least 8GB RAM for Docker containers

## Critical: VPN Access

**🔴 VPN REQUIRED**: All data operations (Fedora, Solr, imports) require active WVU VPN connection. Without VPN:
- Fedora connections will fail
- Solr indexing will fail
- Import operations will fail
- Development environment will be unusable

## Environment Setup

1. **Clone repository:**
   ```bash
   git clone https://github.com/wvulibraries/hydra_acda_portal_public.git
   cd hydra_acda_portal_public
   ```

2. **Connect to WVU VPN**

3. **Start services:**
   ```bash
   ./up.sh
   ```

4. **Verify VPN connectivity:**
   ```bash
   # Test Fedora access
   curl -f http://localhost:8080/fcrepo
   ```

## Database Setup

If needed:
```bash
docker exec -it acda_portal rake db:create db:migrate db:seed
```

## Development URLs

- **App**: http://localhost:3000
- **Fedora**: http://localhost:8080/fcrepo (VPN required)
- **Solr**: http://localhost:8983 (VPN required)

## Container Access

```bash
# Rails container
docker exec -it acda_portal sh

# Sidekiq container
docker exec -it sidekiq sh
```

## Import Operations

**VPN REQUIRED**

Access Bulkrax importer at: http://localhost:3000/importers

Use credentials from `env/` files.

## Data Clearing (Development Only)

**⚠️ DESTRUCTIVE - Development only**

```bash
docker exec -it acda_portal ruby import/explode_fcrepo_solr.rb
```

## Common Issues

- **Connection failures**: Check VPN
- **Import failures**: Verify VPN and file paths
- **Service startup**: Ensure adequate RAM (8GB+)

## Partner Access

For partner institutions:
- Request VPN access from WVU IT
- Coordinate with WVU Libraries for repository access
- Use provided environment configurations