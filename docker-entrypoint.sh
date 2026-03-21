#!/bin/bash
set -e

# Wait for MySQL to be ready
echo "Waiting for MySQL at ${DB_HOST:-db}:${DB_PORT:-3306}..."
while ! python -c "
import MySQLdb
MySQLdb.connect(
    host='${DB_HOST:-db}',
    port=int('${DB_PORT:-3306}'),
    user='${DB_USER:-pnwmoths}',
    passwd='${DB_PASSWORD:-pnwmoths}',
    db='${DB_NAME:-pnwmoths}',
)
" 2>/dev/null; do
    sleep 2
done
echo "MySQL is ready!"

# Create migrations directory for species app (gitignored in repo)
mkdir -p /app/species/migrations
touch /app/species/migrations/__init__.py

# Check if the database was loaded from a SQL dump (has tables already)
TABLE_COUNT=$(python -c "
import MySQLdb
conn = MySQLdb.connect(
    host='${DB_HOST:-db}',
    port=int('${DB_PORT:-3306}'),
    user='${DB_USER:-pnwmoths}',
    passwd='${DB_PASSWORD:-pnwmoths}',
    db='${DB_NAME:-pnwmoths}',
)
cur = conn.cursor()
cur.execute('SHOW TABLES')
print(len(cur.fetchall()))
conn.close()
")

if [ "$TABLE_COUNT" -gt 0 ]; then
    echo "==================================================="
    echo " Database has $TABLE_COUNT tables (loaded from SQL dump)"
    echo "==================================================="
else
    echo "==================================================="
    echo " Empty database — initializing schema..."
    echo "==================================================="

    # Create initial South migration for species
    python manage.py schemamigration species --initial || true

    # Create all database tables (--noinput skips superuser prompt)
    python manage.py syncdb --noinput

    # Apply South migrations
    python manage.py migrate || true

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
