# Development Guide

Comprehensive guide to setting up and developing locally on the ACDA Portal.

## Repository Structure

We work with two GitHub repositories:

- **WVU's Repository** (source of truth): https://github.com/wvulibraries/hydra_acda_portal_public
- **SoftServ's Repository** (development fork): https://github.com/scientist-softserv/west-virginia-university

**Key Branches**:
- `main` - Production-ready code
- `develop` - Current development
- `feature/*` - Feature branches (always from `develop`)

## Setting Up Git Remotes

If working with both WVU and SoftServ repositories:

```bash
# Clone SoftServ's repository
git clone https://github.com/scientist-softserv/west-virginia-university.git

# Add WVU as upstream (convention: call it 'wvu')
git remote add wvu https://github.com/wvulibraries/hydra_acda_portal_public.git

# Verify remotes
git remote -v
# origin  https://github.com/scientist-softserv/west-virginia-university.git
# wvu     https://github.com/wvulibraries/hydra_acda_portal_public.git
```

## Local Development Workflow

### Initial Setup

```bash
# 1. Checkout SoftServ's main branch
git checkout main

# 2. Build the Docker instance
docker compose -f docker-compose.dev.yml build

# 3. Checkout development branch
git checkout softserv-dev

# 4. Start the application
docker compose -f docker-compose.dev.yml up
```

### Database Setup

If you encounter database errors:

```bash
docker compose -f docker-compose.dev.yml exec web bash
rake db:create db:migrate
```

### Running Tests

```bash
# Access container
docker compose exec web bash

# Run all specs
rspec

# Run specific spec
rspec spec/services/chicago_citation_service_spec.rb
```

### Accessing Containers

```bash
# Rails application container
docker compose exec web bash

# Background worker container
docker compose exec workers bash

# Database container
docker compose exec db psql -U postgres
```

## Development Docker Compose

### Standard Development

```bash
docker compose -f docker-compose.dev.yml up
```

### Debug Mode

For detailed debugging with individual service control:

```bash
docker compose -f docker-compose.dev.yml -f docker-compose.dev.debug.yml up
```

Then start services individually as needed.

## Email in Development

Emails sent in development are captured and viewable at:

**http://localhost:3000/letter_opener/**

This allows testing email functionality without actually sending.

## Data Import (Bulkrax)

### Add Content via CSV

1. Navigate to: http://localhost:3000/bulkrax/importers
2. Login with credentials from `env/env.dev.hydra`:
   - Username: `$BULKRAX_USERNAME`
   - Password: `$BULKRAX_PW`
3. Create new importer (CSV)
4. Upload sample CSV (examples in repository)
5. Configure field mappings
6. Click "Start import"

### Sample CSV Files

Sample CSV files for testing are available in the repository:
- See GitHub issues for roundtripping examples
- Check `data/sample_imports/` directory

### Monitor Import Status

```bash
# Access container
docker compose exec web bash

# Check import status
rails console
Bulkrax::Importer.last
Bulkrax::Importer.last.entries.failed
```

## Development Tools

### Rails Console

```bash
docker compose exec web rails console

# Example: Create admin user
user = User.new
user.email = 'admin@example.com'
user.password = 'password'
user.admin = true
user.save
```

### ActiveRecord Migrations

```bash
# Create new migration
docker compose exec web rails generate migration AddFieldToRecords

# Run migrations
docker compose exec web rake db:migrate

# Rollback
docker compose exec web rake db:rollback
```

### Debugging

#### byebug Debugger

Add breakpoint in code:

```ruby
def some_method
  byebug  # Execution will pause here
  # Your code
end
```

Then run tests:

```bash
docker compose exec web rspec spec/path/to/spec.rb
```

#### Print Debugging

```bash
docker compose exec web tail -f log/development.log
```

## Code Standards

### RuboCop Linting

```bash
docker compose exec web rubocop

# Auto-fix issues
docker compose exec web rubocop -a
```

### Testing

- All features should have corresponding specs
- Use RSpec for unit and integration tests
- Aim for >80% code coverage

## Working with Two Repositories

### Sync from WVU to SoftServ

```bash
# Fetch WVU changes
git fetch wvu

# Check if WVU is ahead
git log --oneline main..wvu/main

# Merge WVU changes into SoftServ
git merge wvu/main --no-ff

# Or use GitHub "Sync Fork" button
```

### Send Changes Back to WVU

```bash
# Create PR from SoftServ softserv-dev → WVU softserv-dev
# 1. Go to GitHub and create PR
# 2. WVU team will review
# 3. WVU team merges and may deploy to staging
```

### Handle Merge Conflicts

```bash
# If sync fork fails with conflicts:
git fetch wvu
git merge wvu/softserv-dev --no-ff
# Resolve conflicts in your editor
git add .
git commit -m "Merge WVU softserv-dev"
git push origin softserv-dev
```

## Common Development Tasks

### Add a New Model

```bash
docker compose exec web rails generate model ModelName field:type

# Then create the migration
rake db:migrate
```

### Add a New View

Place views in: `hydra/app/views/`

Naming convention:
- `controller_name/action_name.html.erb`

### Modify Solr Configuration

Solr core configuration is in: `solr9-setup/`

After changes:

```bash
docker compose restart solr
```

### Update Dependencies

```bash
# Update gems
docker compose exec web bundle update gem_name

# Update npm packages (if applicable)
docker compose exec web npm update
```

## Performance Tips

### Database Indexing

Check slow queries in development logs and add indexes:

```ruby
# In migration
add_index :table_name, :column_name
```

### Caching

Enable caching in development:

```bash
# Edit config/environments/development.rb
config.action_controller.perform_caching = true
```

### Query Optimization

Use `bullet` gem to detect N+1 queries:

```ruby
# In Gemfile (development group)
gem 'bullet'

# Generate reports at: http://localhost:3000/bullet/request_logs
```

## Troubleshooting Development Issues

### Container Won't Start

```bash
# Check logs
docker compose logs web
docker compose logs fcrepo
docker compose logs solr

# Rebuild
docker compose down
docker compose build --no-cache
docker compose up
```

### Database Lock

```bash
# If rake tasks hang
docker compose exec db psql -U postgres
# In psql: SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'acda_portal_development';
```

### Memory Issues

```bash
# Increase Docker memory
# Edit Docker Desktop settings or docker-compose.yml:
services:
  web:
    mem_limit: 2g
```

---

See [[README]] for full wiki index.
