# Getting Started

For SoftServ development there are two repositories:

- SoftServ's :: https://github.com/scientist-softserv/west-virginia-university
- WVU's :: https://github.com/wvulibraries/hydra_acda_portal_public

SoftServ's is a fork of WVU.

In SoftServ there are two important branches: `main` and `softserv-dev`.  The `main` branch tracks to WVU's `main` branch; and likewise for `softserv-dev`.

The SoftServ `main` has changes necessary for building your local docker instance.  Those changes should not be merged into `softserv-dev` nor into any of WVU's branches.

## Procedure: Workflow

- Clone SoftServ's repository
- Checkout the SoftServ's `main` branch
- Run `docker compose -f docker-compose.dev.yml build` to build the instance.
- Once build, checkout `softserv-dev`.
- Run `docker compose -f docker-compose.dev.yml up` to spin up the built instance.

You need to start branches from `softserv-dev` and submit PRs to SoftServ's Github repository; the SoftServ team will review the changes and we then merge those changes into SoftServ's `softserv-dev` branch.

 **_Note_**: There is no automated deploy for SoftServ; nor do we have a staging environment.  SoftServ QA is handled on a local instance; and WVU QA is handled by them spinning up a staging environment.

At this point, we do local QA against SoftServ's `softserv-dev` branch.  When it passes internal QA, we can move the ticket. 

We then need to send that code to WVU for review.  We also will submit PRs from SoftServ's `softserv-dev` branch to WVU's `softserv-dev` branch.  When we submit those PRs:

- Check the commits to review what will be sent to WVU
- Ping the developers at WVU to have them review and ultimately spin up a staging environment. 

I suspect that the flow of changes will be uni-directional; code will likely only be going into WVU `softserv-dev`.  If that suspicion is not the case, we'll determine the best approach to bring changes for WVU's `softserv-dev` branch into SoftServ's branch.  Likewise for changes added to `main`; though I suspect those are unlikely.

## Procedure: Adding Changes to SoftServ's main and softserv-dev branches

When you need to add changes to both `main` and `softserv-dev`, follow the above process to get code into `softserv-dev`. 

Then:

- Checkout SoftServ's `main` branch.
- Create a new branch from SoftServ's `main` branch.
- Cherry pick the commits you want from SoftServ's `softserv-dev` branch.
- Submit a PR from this new branch to SoftServ's `main` branch.

The goal of the above is three-fold:

- to keep SoftServ's `main` aligned with WVU's `main`
- to keep SoftServ's `softserv-dev` aligned with WVU's `softserv-dev`
- to propagate SoftServ documentation to `main` and `softserv-dev` to help developers in their wayfinding.

Note, there are cases where we will first add documentation to `main` and then propogage that to `softserv-dev`.

## Local Development

The `up.sh` command uses the `docker-compose.dev.yml` file for it’s build process.  This will both build and bring up the containers.  You can access the application at http://localhost:3000.  When I first accessed the application, I had to shell into the `web` container and run `bundle exec rake db:create db:migrate`.  To shell into the `web` container use the following: `docker compose -f docker-compose.dev.yml exec web bash`.

If you prefer to start the `web` and `workers` services individually, you can use `docker-compose.dev.debug.yml` as part of the composition.

```
docker compose -f docker-compose.dev.yml -f docker-compose.dev.debug.yml up
```

You'll then need to shell into the containers to start the services.

### Adding Content

To get data into the app:

- Navigate to http://localhost:3000/importers?locale-en to import via bulkrax csv
- Sample csv files are on the roundtripping ticket:
  - https://github.com/scientist-softserv/west-virginia-university/issues/104
- You will have to log into the popup.  The username is in `ENV['BULKRAX_USERNAME']` and the password is in `ENV['BULKRAX_PW']`.  For local development, see [./env/env.dev.hydra](./env/env.dev.hydra).    
  - Barring that, shell into the web container (e.g. `docker compose -f docker-compose.dev.yml exec web bash`) and run `echo "$BULKRAX_USERNAME:$BULKRAX_PW"`.
