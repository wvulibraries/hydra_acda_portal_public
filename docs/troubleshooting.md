# Troubleshooting Guide

This guide helps resolve common issues with the ACDA Portal development and deployment.

## Quick Diagnostics

### Check Service Status

```bash
# View all containers
docker ps -a

# Check container health
docker stats

# View logs for specific service
docker logs acda_portal
docker logs fcrepo
docker logs solr
```

### Common Health Checks

```bash
# Test Fedora
curl -f http://localhost:8080/fcrepo

# Test Solr
curl -f http://localhost:8983/solr/#/

# Test database
docker exec db pg_isready -d fcrepo

# Test Redis
docker exec redis redis-cli ping
```

## Startup Issues

### Containers Won't Start

**Symptoms:** `docker-compose up` fails or containers exit immediately

**Solutions:**
1. Check available disk space: `df -h`
2. Check available memory: `docker system df`
3. Clear Docker cache: `docker system prune`
4. Check logs: `docker logs <container_name>`

### Port Conflicts

**Symptoms:** "Port already in use" errors

**Solutions:**
1. Find process using port: `lsof -i :3000`
2. Stop conflicting service
3. Or modify docker-compose.yml to use different ports

### VPN Connection Issues

**Symptoms:** Fedora/Solr connection failures

**Solutions:**
1. Verify VPN is connected
2. Check network connectivity: `ping <fedora_host>`
3. Verify firewall settings
4. Check VPN routing tables

## Database Issues

### Connection Refused

**Symptoms:** "PG::ConnectionBad" or similar errors

**Solutions:**
1. Ensure database container is running: `docker ps | grep db`
2. Check database logs: `docker logs db`
3. Verify credentials in `config/database.yml`
4. Test connection: `docker exec db pg_isready -d fcrepo`

### Migration Failures

**Symptoms:** `rake db:migrate` fails

**Solutions:**
1. Check database connectivity
2. Review migration file syntax
3. Check for conflicting migrations
4. Reset database if needed: `rake db:reset` (⚠️ destroys data)

### Data Corruption

**Symptoms:** Inconsistent or missing data

**Solutions:**
1. Check database integrity: `docker exec db pg_checksums`
2. Restore from backup
3. Run data repair scripts

## Fedora Repository Issues

### Connection Failures

**Symptoms:** "Fedora connection error"

**Solutions:**
1. Verify VPN connection
2. Check Fedora logs: `docker logs fcrepo`
3. Test Fedora endpoint: `curl http://localhost:8080/fcrepo`
4. Check network connectivity between containers

### Repository Unavailable

**Symptoms:** Fedora returns 500 errors

**Solutions:**
1. Check Fedora health: `docker ps | grep fcrepo`
2. Review Fedora configuration in `fcrepo/`
3. Check disk space in Fedora container
4. Restart Fedora: `docker restart fcrepo`

## Solr Search Issues

### Search Not Working

**Symptoms:** No search results or errors

**Solutions:**
1. Check Solr status: `docker logs solr`
2. Verify core exists: `curl http://localhost:8983/solr/admin/cores`
3. Reindex content: `docker exec acda_portal rake hydra:reindex`
4. Check Solr configuration in `solr9-setup/`

### Indexing Failures

**Symptoms:** Content not appearing in search

**Solutions:**
1. Check Sidekiq workers: `docker logs sidekiq`
2. Monitor indexing jobs in Rails admin
3. Verify metadata format
4. Check for indexing errors in logs

## Application Issues

### Rails Server Won't Start

**Symptoms:** Puma/Rails fails to start

**Solutions:**
1. Check Rails logs: `docker logs acda_portal`
2. Verify environment variables
3. Check database connectivity
4. Test Ruby dependencies: `docker exec acda_portal bundle check`

### Asset Compilation Errors

**Symptoms:** CSS/JS not loading

**Solutions:**
1. Precompile assets: `docker exec acda_portal rake assets:precompile`
2. Check Node.js/Yarn installation
3. Verify asset pipeline configuration
4. Clear asset cache

### Memory Issues

**Symptoms:** Container crashes with OOM

**Solutions:**
1. Increase container memory limits in docker-compose.yml
2. Monitor memory usage: `docker stats`
3. Optimize application memory usage
4. Consider jemalloc tuning (if re-enabled)

## Import/Export Issues

### Bulkrax Import Failures

**Symptoms:** Import jobs fail or hang

**Solutions:**
1. Check Sidekiq status: `docker logs sidekiq`
2. Verify import file format and paths
3. Check available disk space
4. Review Bulkrax configuration

### File Upload Issues

**Symptoms:** Files not uploading or processing

**Solutions:**
1. Check file permissions in containers
2. Verify upload directory paths
3. Check file size limits
4. Test file processing pipeline

## Networking Issues

### Container Communication

**Symptoms:** Services can't communicate

**Solutions:**
1. Verify Docker network: `docker network ls`
2. Check container IP addresses: `docker inspect <container>`
3. Test service discovery: `docker exec acda_portal ping solr`
4. Restart network: `docker network restart hydra`

### External Access

**Symptoms:** Can't access localhost:3000

**Solutions:**
1. Check port mapping: `docker ps`
2. Verify firewall settings
3. Test from different browser/machine
4. Check Docker daemon status

## Performance Issues

### Slow Response Times

**Symptoms:** Application is slow

**Solutions:**
1. Check resource usage: `docker stats`
2. Monitor database query performance
3. Check cache hit rates
4. Optimize slow queries

### High Memory Usage

**Symptoms:** Containers using excessive memory

**Solutions:**
1. Monitor memory patterns
2. Adjust JVM heap sizes
3. Implement memory limits
4. Profile memory usage in application

## Development Environment Issues

### Code Changes Not Reflecting

**Symptoms:** Changes not appearing after save

**Solutions:**
1. Verify volume mounting in docker-compose.yml
2. Check file permissions
3. Restart containers if needed
4. Clear Rails cache: `docker exec acda_portal rake tmp:clear`

### Test Failures

**Symptoms:** RSpec/Capybara tests failing

**Solutions:**
1. Check test database setup
2. Verify test dependencies
3. Review test configuration
4. Check for environment differences

## Emergency Procedures

### Complete Environment Reset

**⚠️ WARNING: Destroys all data**

```bash
# Stop all services
docker-compose down -v

# Remove all containers and volumes
docker system prune -a --volumes

# Restart fresh
./up.sh
```

### Data Recovery

1. **Identify backup location**
2. **Stop services**: `docker-compose down`
3. **Restore volumes from backup**
4. **Restart services**: `docker-compose up -d`
5. **Verify data integrity**

## Getting Help

### Log Collection

```bash
# Collect all logs
docker-compose logs > debug.log

# System information
docker system info > system.log
```

### Support Information

When reporting issues, include:
- Docker version: `docker --version`
- Docker Compose version: `docker-compose --version`
- OS and version
- Full error messages and stack traces
- Steps to reproduce
- Recent changes to code or configuration