#!/bin/bash

#!/bin/bash

# Set up logging
LOGFILE="clear_data.log"
exec > >(tee -i $LOGFILE)
exec 2>&1

echo "Starting data clearing process: $(date)"

# Clear the project data from Fedora
echo "Clearing Fedora project data..."
if docker exec acda_portal bin/rails r import/delete_project.rb; then
  echo "Fedora project data cleared successfully."
else
  echo "Error clearing Fedora project data!" >&2
  exit 1
fi

# Clear Sidekiq jobs and related data
echo "Clearing Sidekiq jobs and data..."
if docker exec acda_portal bin/rails r import/clear-sidekiq-jobs.rb; then
  echo "Sidekiq jobs and data cleared successfully."
else
  echo "Error clearing Sidekiq jobs and data!" >&2
  exit 1
fi

# Drop, create, and migrate the Postgres database
echo "Dropping, creating, and migrating Postgres database..."
if docker exec acda_portal bin/rails db:drop:_unsafe db:create db:migrate; then
  echo "Postgres database recreated and migrated successfully."
else
  echo "Error resetting Postgres database!" >&2
  exit 1
fi

echo "Data clearing process completed: $(date)"

