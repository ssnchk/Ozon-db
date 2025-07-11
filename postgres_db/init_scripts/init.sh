#!/bin/bash

psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "CREATE ROLE ${CREATOR_USER} WITH LOGIN PASSWORD '${CREATOR_PASSWORD}' CREATEDB;"
psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "CREATE DATABASE ${DB_NAME} WITH OWNER ${CREATOR_USER};"
psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${CREATOR_USER};"

if [ "${APP_ENV}" = "dev" ]; then
  psql -U "${POSTGRES_USER}" -d "${DB_NAME}" -c "CREATE EXTENSION IF NOT EXISTS plpython3u;"
  psql -U "${POSTGRES_USER}" -d "${DB_NAME}" -c "CREATE SCHEMA IF NOT EXISTS faker;"
  psql -U "${POSTGRES_USER}" -d "${DB_NAME}" -c "CREATE EXTENSION IF NOT EXISTS faker SCHEMA faker;"
  psql -U "${POSTGRES_USER}" -d "${DB_NAME}" -c "GRANT USAGE ON SCHEMA faker TO ${CREATOR_USER};"
  psql -U "${POSTGRES_USER}" -d "${DB_NAME}" -c "GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA faker TO ${CREATOR_USER};"
fi
