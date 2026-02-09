# Deployment (Internal)

ACDA Portal deployment procedures for WVU Libraries infrastructure.

## Environments

- **Development**: congressarchivesdev.lib.wvu.edu
- **Production**: congressarchives.org

## Automated Deployment Process

### GitHub Releases Workflow

1. **Development Deployment:**
   - Create a **pre-release** tag
   - Dev server auto-deploys within 5 minutes

2. **Production Deployment:**
   - Edit pre-release and mark as **latest release**
   - Production server auto-deploys

### Manual Override

For urgent fixes or testing:

```bash
# SSH to server
ssh user@server

# Pull latest changes
cd /path/to/app
git pull

# Deploy
docker-compose up -d --build
```

## Pre-deployment Checklist

- [ ] WVU VPN connected
- [ ] Database backup completed
- [ ] Test deployment on dev server first
- [ ] Coordinate with partner institutions for downtime
- [ ] Notify team of deployment window

## Post-deployment Verification

- [ ] Site accessible
- [ ] Search working
- [ ] OAI-PMH responding
- [ ] No errors in logs
- [ ] Partner institutions notified

## Rollback

If issues arise:

1. **Immediate rollback:**
   ```bash
   # On server
   docker-compose down
   git checkout previous-tag
   docker-compose up -d
   ```

2. **Database rollback:**
   - Restore from backup if schema changes
   - Coordinate with DBA team

## Infrastructure Notes

- **VPN Required**: All data access requires WVU VPN
- **Network**: Services on isolated network segments
- **Backups**: Automated daily backups of all volumes
- **Monitoring**: Health checks every 30s, alerts to dev team

## Partner Coordination

- **Dole Institute**: Notify before deployments affecting their collections
- **Byrd Center**: Coordinate for any UI/UX changes
- **WVU Libraries**: Primary contact for infrastructure issues

## Emergency Contacts

- **Infrastructure**: WVU ITS - infrastructure@wvu.edu
- **Development Team**: WVU Libraries Digital - digital@wvu.edu
- **Security**: WVU ITS Security - security@wvu.edu