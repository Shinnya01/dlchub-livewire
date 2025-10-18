# PHP-FPM Dockerfile (app + supervisor). Adjust as needed.
FROM php:8.2-fpm

# Install system deps for building and runtime (keep image small)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       git curl ca-certificates libzip-dev zip unzip libpng-dev libonig-dev libxml2-dev supervisor \
       build-essential libpng-dev libjpeg-dev libfreetype6-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo_mysql mbstring zip exif pcntl bcmath gd \
    && rm -rf /var/lib/apt/lists/*

# Composer (copy from official composer image)
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Copy application files
COPY . .

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-progress

# Node build: install, build, then remove build deps
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get update && apt-get install -y nodejs \
    && npm install --silent \
    && npm run build \
    && apt-get remove -y nodejs build-essential \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* /root/.npm /root/.cache

# Ensure permissions for storage and cache
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Supervisor config + entrypoint
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Expose PHP-FPM port for internal networking
EXPOSE 9000

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]