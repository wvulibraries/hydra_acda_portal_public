#!/bin/bash

# Replace these with your own GitHub username and repository name
GITHUB_USER="wvulibraries"
REPO_NAME="hydra_acda_portal_public"

# GITHUB_USER="scientist-softserv"
# REPO_NAME="west-virginia-university"

if [ -z "$1" ] ; then
  echo "Usage: ./check_new_release.sh (dev|prod). Argument not found"
  exit 1
fi

if [ "$1" == "dev" ] ; then
  # GitHub API endpoint for all releases
  API_URL="https://api.github.com/repos/$GITHUB_USER/$REPO_NAME/releases"

  # Get the latest pre-release tag from the GitHub API
  LATEST_TAG=$(curl --silent $API_URL | jq -r '.[] | select(.prerelease==true) | .tag_name' | head -1)
elif [ "$1" == "prod" ] ; then
  # GitHub API endpoint for release tags
  API_URL="https://api.github.com/repos/$GITHUB_USER/$REPO_NAME/releases/latest"

  # Get the latest release tag from the GitHub API
  LATEST_TAG=$(curl --silent $API_URL | jq -r '.tag_name' | head -1)
else
  echo "Usage: ./check_new_release.sh (dev|prod). Argument not recognized"
  exit 1
fi

# Check if the tag exists
if [ -z "$LATEST_TAG" ]; then
  echo "Error: No release tags found."
  exit 1
fi

# Get the current checked-out tag
CURRENT_TAG=$(git describe --tags --abbrev=0)

# Check if the current tag matches the latest tag
if [ "$LATEST_TAG" == "$CURRENT_TAG" ]; then
  echo "Already on the latest release tag: $LATEST_TAG"
  exit 0
else
  echo "Found new release tag: $LATEST_TAG"
  echo "Checking out the new tag..."

  # Fetch the latest tags from the remote repository
  git fetch --tags origin

  # Check out the latest tag
  git checkout $LATEST_TAG

  # Show the current checked-out tag
  echo "Now on tag: $(git describe --tags --abbrev=0)"

  echo "Beginning build"
  docker-compose -f docker-compose.$1.yml build

  echo "Restarting processes"
  docker-compose-f docker-compose.$1.yml up -d web workers conversion
fi
