#!/bin/bash

# Function to log and exit on error
function error_exit {
  echo "Error: $1"
  exit 1
}

# Log the current directory
ls -la /usr/src/app

# Check if required parameters are set
[ -z "$PROJECT_PATH" ] && error_exit "PROJECT_PATH is not set."
[ -z "$PROJECT_NAME" ] && error_exit "PROJECT_NAME is not set."
[ -z "$ASPNETCORE_ENVIRONMENT" ] && error_exit "ASPNETCORE_ENVIRONMENT is not set."

# Variables
MIGRATIONS_PROJECT="/usr/src/app$PROJECT_PATH$PROJECT_NAME"
STARTUP_PROJECT="/usr/src/app$PROJECT_PATH"

# Verify that the directories exist
[ ! -f "$MIGRATIONS_PROJECT" ] && error_exit "Migrations project path '$MIGRATIONS_PROJECT' does not exist."
[ ! -d "$STARTUP_PROJECT" ] && error_exit "Startup project path '$STARTUP_PROJECT' does not exist."

# Log parameters for debugging
echo "Using parameters:"
echo "  MIGRATIONS_PROJECT: $MIGRATIONS_PROJECT"
echo "  STARTUP_PROJECT: $STARTUP_PROJECT"
echo "  ASPNETCORE_ENVIRONMENT: $ASPNETCORE_ENVIRONMENT"

export ASPNETCORE_ENVIRONMENT=$ASPNETCORE_ENVIRONMENT
export ASPNETCORE_LOGGING__CONSOLE__LOGLEVEL__DEFAULT=Debug

# List migrations before applying
echo "Listing migrations before applying..."
dotnet ef migrations list \
  -p "$MIGRATIONS_PROJECT" \
  -s "$STARTUP_PROJECT" \
  --no-build --verbose \
  -- --environment "$ASPNETCORE_ENVIRONMENT" || error_exit "Failed to list migrations before applying."

# Apply migrations
echo "Applying migrations..."
dotnet ef database update \
  -p "$MIGRATIONS_PROJECT" \
  -s "$STARTUP_PROJECT" \
  --no-build --verbose \
  -- --environment "$ASPNETCORE_ENVIRONMENT" || error_exit "Failed to apply migrations."

# List migrations after applying
echo "Listing migrations after applying..."
dotnet ef migrations list \
  -p "$MIGRATIONS_PROJECT" \
  -s "$STARTUP_PROJECT" \
  --no-build --verbose \
  -- --environment "$ASPNETCORE_ENVIRONMENT" || error_exit "Failed to list migrations after applying."

echo "Migrations applied successfully."
