#!/bin/bash

echo "Validating environment variables..."

# Check if SERVER_NAME is set
if [ -z "$SERVER_NAME" ]; then
  echo "Error: SERVER_NAME is not set."
  exit 1
fi

# Check if MSSQL_SA_PASSWORD is set
if [ -z "$MSSQL_SA_PASSWORD" ]; then
  echo "Error: MSSQL_SA_PASSWORD is not set."
  exit 1
fi

# Check if DATABASE_NAME is set
if [ -z "$DATABASE_NAME" ]; then
  echo "Error: DATABASE_NAME is not set."
  exit 1
fi

# Check if DATABASE_USERNAME is set
if [ -z "$DATABASE_USERNAME" ]; then
  echo "Error: DATABASE_USERNAME is not set."
  exit 1
fi

# Check if DATABASE_PASSWORD is set
if [ -z "$DATABASE_PASSWORD" ]; then
  echo "Error: DATABASE_PASSWORD is not set."
  exit 1
fi

# Check if INIT_SQL_PATH is set
if [ -z "$INIT_SQL_PATH" ]; then
  echo "Error: INIT_SQL_PATH is not set."
  exit 1
fi

echo "Environment variables validated..."
echo "SERVER_NAME: $SERVER_NAME"
echo "MSSQL_SA_PASSWORD: [REDACTED]"
echo "DATABASE_NAME: $DATABASE_NAME"
echo "DATABASE_USERNAME: $DATABASE_USERNAME"
echo "DATABASE_PASSWORD: [REDACTED]"
echo "INIT_SQL_PATH: $INIT_SQL_PATH"

echo "Checking if sqlcmd is installed..."
/opt/mssql-tools18/bin/sqlcmd -?

# Execute the initialization script with parameters passed to sqlcmd
echo "Initializing database..."

for i in {1..5}; do
  /opt/mssql-tools18/bin/sqlcmd -S "$SERVER_NAME" -U SA -P "$MSSQL_SA_PASSWORD" -d master -C \
    -i "$INIT_SQL_PATH" \
    -v "DatabaseName=$DATABASE_NAME" "Username=$DATABASE_USERNAME" "Password=$DATABASE_PASSWORD" && break

  echo "Retrying in 3s..."
  sleep 3
done

if [ $? -ne 0 ]; then
  echo "Error: Database initialization failed..."
  exit 1
fi

echo "Database initialized..."
exit 0
