# Local Development

The `up.sh` command uses the `docker-compose.dev.yml` file for it’s build process.  This will both build and bring up the containers.  You can access the application at http://localhost:3000.  When I first accessed the application, I had to shell into the `web` container and run `bundle exec rake db:create db:migrate`.  To shell into the `web` container use the following: `docker compose -f docker-compose.dev.yml exec web bash`.

If you prefer to start the `web` and `workers` services individually, you can use `docker-compose.dev.debug.yml` as part of the composition.

```
docker compose -f docker-compose.dev.yml -f docker-compose.dev.debug.yml up
```

You'll then need to shell into the containers to start the services.

## Adding Content

To get data into the app:

- Navigate to http://localhost:3000/importers?locale-en to import via bulkrax csv
- Sample csv files are on the roundtripping ticket:
  - https://github.com/scientist-softserv/west-virginia-university/issues/104
- You will have to log into the popup.  The username is in `ENV['BULKRAX_USERNAME']` and the password is in `ENV['BULKRAX_PW']`.  For local development, see [./env/env.dev.hydra](./env/env.dev.hydra).    
  - Barring that, shell into the web container (e.g. `docker compose -f docker-compose.dev.yml exec web bash`) and run `echo "$BULKRAX_USERNAME:$BULKRAX_PW"`.
