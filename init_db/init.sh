#!/bin/sh

export PGPASSWORD="${POSTGRES_PASSWORD}"

# Step 1: Create the role if it does not exist
psql -h haproxy -p 5000 -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" <<EOF
DO \$\$
BEGIN
  IF NOT EXISTS (
    SELECT FROM pg_catalog.pg_roles WHERE rolname = '${CREATOR_USER}'
  ) THEN
    CREATE ROLE ${CREATOR_USER} WITH LOGIN PASSWORD '${CREATOR_PASSWORD}' CREATEDB;
  END IF;
END
\$\$;
EOF

# Step 2: Check if the database exists and create it if necessary
DB_EXISTS=$(psql -h haproxy -p 5000 -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -tAc "SELECT 1 FROM pg_catalog.pg_database WHERE datname = '${DB_NAME}'")

if [ -z "$DB_EXISTS" ]; then
  # Create the database outside of a DO block
  psql -h haproxy -p 5000 -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "CREATE DATABASE ${DB_NAME} WITH OWNER ${CREATOR_USER};"
fi

# Step 3: Grant privileges on the database
psql -h haproxy -p 5000 -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${CREATOR_USER};"

# Step 4: Conditional setup for dev environment
if [ "${APP_ENV}" = "dev" ]; then
  # Connect to the newly created database
  psql -h haproxy -p 5000 -U "${POSTGRES_USER}" -d "${DB_NAME}" <<EOF
  -- Create the plpython3u extension if it does not exist
  CREATE EXTENSION IF NOT EXISTS plpython3u;

  -- Create the faker schema if it does not exist
  CREATE SCHEMA IF NOT EXISTS faker;

  -- Create the faker extension in the faker schema if it does not exist
  DO \$\$
  BEGIN
    IF NOT EXISTS (
      SELECT FROM pg_extension WHERE extname = 'faker'
    ) THEN
      CREATE EXTENSION faker SCHEMA faker;
    END IF;
  END
  \$\$;

  -- Grant usage and execute permissions on the faker schema
  GRANT USAGE ON SCHEMA faker TO ${CREATOR_USER};
  GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA faker TO ${CREATOR_USER};
EOF
fi