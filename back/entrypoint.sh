#!/bin/sh
set -e

# Run data seeding
echo "Running initial data seeding..."
uv run python -m app.initial_data

# Execute the main command (CMD)
exec "$@"
