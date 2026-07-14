#!/bin/bash
set -e

# Wait for database to be ready
echo "Waiting for MySQL to be ready..."
while ! nc -z db 3306; do
  sleep 1
done
echo "MySQL is ready!"

# Run migrations if needed (uncomment if using Alembic)
# flask db upgrade

# Start Flask application
exec flask run --host=0.0.0.0
