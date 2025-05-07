#!/bin/bash

source ./.env

[ -z "$POSTGRES_PASSWORD" ] && { echo "Не указан POSTGRES_PASSWORD в .env"; exit 1; }
[ -z "$POSTGRES_USER" ] && { echo "Не указан POSTGRES_USER в .env"; exit 1; }
[ -z "$POSTGRES_DB" ] && { echo "Не указан POSTGRES_DB в .env"; exit 1; }
[ -z "$ANALYST_NAMES" ] && { echo "Не указан ANALYST_NAMES в .env"; exit 1; }
[ -z "$LOCAL_PORT" ] && { echo "Не указан LOCAL_PORT в .env"; exit 1; }


run_psql() {
  PGPASSWORD="$POSTGRES_PASSWORD" psql -h localhost -p "$LOCAL_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "$1"
}

run_psql "CREATE ROLE analytic;"
run_psql "GRANT USAGE ON SCHEMA public TO analytic;"
run_psql "GRANT SELECT ON ALL TABLES IN SCHEMA public TO analytic;"
run_psql "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO analytic;"

IFS=',' read -ra USERS <<< "$ANALYST_NAMES"
for user in "${USERS[@]}"; do
  [ -z "$user" ] && continue

  password="${user}_123"

  run_psql "CREATE USER \"$user\" PASSWORD '$password' INHERIT IN ROLE analytic;"
done
