# Quick Start Guide

Get the ACDA Portal running in your local environment in 5 minutes.

## Prerequisites

- Docker and Docker Compose
- Git
- VPN access (required for Fedora/Solr connectivity in production environments)

## 1. Clone the Repository

```bash
git clone https://github.com/wvulibraries/hydra_acda_portal_public.git
cd hydra_acda_portal_public
```

## 2. Start the Application

```bash
./up.sh
```

This will:
- Build Docker images
- Start all services (Rails, Fedora, Solr, PostgreSQL, Redis, Memcached)
- Initialize the database
- Seed any initial data

The application will be available at: **http://localhost:3000**

## 3. Access the Application

**Main Portal**: http://localhost:3000  
**Admin Dashboard**: http://localhost:3000/admin  
**Bulkrax Importer**: http://localhost:3000/bulkrax/importers  

## 4. Default Credentials

Development credentials are configured in `env/env.dev.hydra`:

```bash
# Admin user (create in rails console if needed)
Email: admin@example.com
Password: (check env variables)

# Bulkrax importer login
Username: (check ENV['BULKRAX_USERNAME'])
Password: (check ENV['BULKRAX_PW'])
```

To view credentials:

```bash
docker compose exec web echo "Username: $BULKRAX_USERNAME, Password: $BULKRAX_PW"
```

## 5. Import Sample Data

Navigate to: http://localhost:3000/bulkrax/importers

1. Click "New Importer"
2. Select: "CSV" as the parser
3. Upload a sample CSV file (examples in repository)
4. Configure field mappings
5. Start import

## 6. Stop the Application

```bash
./down.sh
```

This will stop all running containers.

## Common Issues

### Database Errors
If you encounter "database does not exist" errors:

```bash
docker compose exec web rake db:create db:migrate
```

### Port Already in Use
If port 3000 is already in use, modify `docker-compose.dev.yml`:

```yaml
ports:
  - "3001:3000"  # Changed from 3000:3000
```

Then access at http://localhost:3001

### Container Won't Start
Check logs:

```bash
docker compose logs web
docker compose logs fcrepo
docker compose logs solr
```

## Next Steps

- **Development**: See [[Development Guide]]
- **Architecture**: See [[System Architecture Overview]]
- **Data Import**: See [[Bulkrax Configuration Guide]]
- **Troubleshooting**: See [[Common Issues & Solutions]]

---

See [[README]] for full wiki index.
