# Multi-stage Dockerfile: builds composer deps and frontend, final image runs nginx + php-fpm under supervisord
# Final image listens on port 8080 (DigitalOcean App Platform uses this)

# ---------- STAGE 1: PHP deps ----------
FROM php:8.2-fpm AS php-base

# Install system deps and php extensions required by Laravel
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
       git curl ca-certificates unzip libzip-dev zip libpng-dev libonig-dev libxml2-dev \
       libjpeg-dev libfreetype6-dev \
  && docker-php-ext-configure gd --with-freetype --with-jpeg \
  && docker-php-ext-install pdo_mysql mbstring zip exif pcntl bcmath gd \
  && rm -rf /var/lib/apt/lists/*

# Install composer (official)
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Copy composer files early for layer caching
COPY composer.json composer.lock ./

# Install PHP deps (production)
RUN composer install --no-dev --prefer-dist --no-interaction --optimize-autoloader --no-progress \
  && rm -rf /root/.composer/cache

# Copy application code
COPY . .

# Run artisan optimizations (optional here, can be run on release)
RUN php artisan config:cache || true

# ---------- STAGE 2: Node build for assets ----------
FROM node:22-alpine AS node-build
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci --silent
# Copy only the frontend sources the build needs. Adjust path if using vite/webpack
COPY . .
RUN npm run build

# ---------- STAGE 3: Final runtime with nginx + php-fpm ----------
FROM php:8.2-fpm

# Install runtime deps, nginx and supervisor
RUN apt-get update \
  && apt-get install -y --no-install-recommends nginx supervisor \
  && rm -rf /var/lib/apt/lists/*

# Create web user and directories
RUN mkdir -p /var/www/html \
  && chown -R www-data:www-data /var/www/html /var/lib/nginx

WORKDIR /var/www/html

# Copy PHP vendor + app from php-base
COPY --from=php-base /var/www/html /var/www/html

# Copy built frontend from node-build (adjust path to where your build outputs)
COPY --from=node-build /app/public /var/www/html/public

# Copy supervisor + nginx configs
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Ensure storage directories exist and are writable
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache \
  && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

EXPOSE 8080

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]