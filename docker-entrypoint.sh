#!/bin/bash
set -e

# If the app has artisan, optionally run migrations here.
# Recommendation: run migrations via DigitalOcean release command or manually.
if [ -f /var/www/html/artisan ]; then
  echo "Setting permissions..."
  chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
fi

# Execute the container CMD (supervisord)
exec "$@"