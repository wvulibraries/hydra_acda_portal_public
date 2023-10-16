# Local Development

The `up.sh` command uses the `docker-compose.dev.yml` file for it’s build process.  This will both build and bring up the containers.  You can access the application at http://localhost:3000.  When I first accessed the application, I had to shell into the `web` container and run `bundle exec rake db:create db:migrate`.  To shell into the `web` container use the following: `docker compose -f docker-compose.dev.yml exec web bash`.

If you prefer to start the `web` and `workers` services individually, you can use `docker-compose.dev.debug.yml` as part of the composition.

```
docker compose -f docker-compose.dev.yml -f docker-compose.dev.debug.yml up
```

You'll then need to shell into the containers to start the services.
