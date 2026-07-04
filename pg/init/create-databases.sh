#!/bin/bash
set -e
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    CREATE USER ${PG_USER} WITH PASSWORD '${PG_PASS}';
    CREATE DATABASE ${PG_DB} OWNER ${PG_USER};

    # Create additional databases and users for other services if needed

    CREATE USER ${TEST_USER} WITH PASSWORD '${TEST_PASS}';
    CREATE DATABASE ${TEST_DB} OWNER ${TEST_USER};
EOSQL
echo "✅ Database and user created successfully."
