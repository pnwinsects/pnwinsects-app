#!/bin/bash
set -e

# Ensure data directory exists
mkdir -p /app/data

# Initialize database on first run
if [ ! -f /app/data/.initialized ]; then
    echo "==================================================="
    echo " First run — initializing database..."
    echo "==================================================="

    # Create migrations directory for species app (gitignored in repo)
    mkdir -p /app/species/migrations
    touch /app/species/migrations/__init__.py

    # Create initial South migration for species
    python manage.py schemamigration species --initial || true

    # Create all database tables (--noinput skips superuser prompt)
    python manage.py syncdb --noinput

    # Apply South migrations
    python manage.py migrate || true

    touch /app/data/.initialized

    echo ""
    echo "==================================================="
    echo " Database initialized!"
    echo " Create an admin user by running:"
    echo ""
    echo "   docker-compose exec web python manage.py createsuperuser"
    echo ""
    echo "==================================================="
    echo ""
fi

echo "Starting development server at http://localhost:8000"
exec "$@"
