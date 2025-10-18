#!/bin/bash
set -e

# Ensure app files have correct ownership
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache || true

# If artisan exists and migrations should be run here, do it via run command instead of at build time.
# Example production-safe steps (uncomment if you want them to run automatically):
# php artisan migrate --force
# php artisan config:cache
# php artisan route:cache
# php artisan view:cache

exec "$@"