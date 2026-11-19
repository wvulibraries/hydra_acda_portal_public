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
- Start all services (Rails, Fedora, Solr, PostgreSQL, Memcached)

The application will be available at: **http://localhost:3000** once the database is prepared (next step).

## 3. Prepare the Database

```bash
docker compose exec web bash scripts/setup.sh
```

This drops/creates the database, loads the schema (or runs migrations), and seeds it.

## 4. Access the Application

**Main Portal**: http://localhost:3000  
**Bulkrax Importer**: http://localhost:3000/importers  
**Background Jobs (GoodJob)**: http://localhost:3000/good_job 

## 5. Default Credentials

Bulkrax importer login (from `env/env.dev.hydra`):

```bash
docker compose exec web sh -c 'echo "Username: $BULKRAX_USERNAME, Password: $BULKRAX_PW"'
```

There is no separate admin-user login — the catalog itself has no authenticated admin area.

## 6. Import Sample Data

Navigate to: http://localhost:3000/bulkrax/importers

1. Click "New Importer"
2. Select: "CSV" as the parser
3. Upload a CSV file matching the expected field mapping (see [[Bulkrax Configuration]] — no sample file ships with this repo yet)
4. Configure field mappings
5. Start import

## 7. Stop the Application

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

### Bundler::GitError on `web` / `workers`

If `web` or `workers` keep restarting and `docker compose logs web` shows something like:

```
The git source https://github.com/wvulibraries/active_fedora.git is not yet checked out.
Please run `bundle install` before trying to start your application (Bundler::GitError)
```

this means the `bundle_data` Docker volume has stale gems from before the image was last
rebuilt (it only gets seeded from the image on its *first* creation — rebuilding the image
later, e.g. after switching branches or bumping a gem, doesn't refresh it). Fix it without
touching your Postgres/Solr/Fedora data:

```bash
docker compose -f docker-compose.dev.yml run --rm app bundle install
docker compose -f docker-compose.dev.yml up -d
```

## Next Steps

- **Development**: See [[Development Guide]]
- **Architecture**: See [[System Architecture Overview]]
- **Data Import**: See [[Bulkrax Configuration Guide]]
- **Troubleshooting**: See [[Common Issues & Solutions]]

---

See [[README]] for full wiki index.
