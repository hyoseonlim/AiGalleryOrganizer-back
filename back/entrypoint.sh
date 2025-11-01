#!/bin/sh
set -e

# Function to wait for PostgreSQL
wait_for_postgres() {
    echo "Waiting for PostgreSQL to be ready..."
    until pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER"; do
        echo "PostgreSQL is unavailable - sleeping"
        sleep 1
    done
    echo "PostgreSQL is up and running!"
}

# Wait for DB if DB_HOST is set
if [ -n "$DB_HOST" ]; then
    wait_for_postgres
fi

# Removed: Run data seeding only if SEED_DATA is set to "true"
# if [ "$SEED_DATA" = "true" ]; then
#     echo "Running initial data seeding..."
#     uv run python -m app.initial_data
# fi

# Execute the main command (CMD)
exec "$@"