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

# Drop, create, and migrate the Postgres database
# (this also clears all GoodJob job records, since they live in Postgres)
echo "Dropping, creating, and migrating Postgres database..."
if docker exec acda_portal bin/rails db:drop:_unsafe db:create db:migrate; then
  echo "Postgres database recreated and migrated successfully."
else
  echo "Error resetting Postgres database!" >&2
  exit 1
fi

echo "Data clearing process completed: $(date)"
