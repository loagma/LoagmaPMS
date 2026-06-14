FROM php:8.2-apache

WORKDIR /var/www/html

# Install system dependencies and PHP extensions required by Laravel 12
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libicu-dev \
    libonig-dev \
    libzip-dev \
 && docker-php-ext-install \
    pdo_mysql \
    intl \
    bcmath \
 && a2enmod rewrite \
 && rm -rf /var/lib/apt/lists/*

# Set Apache document root to Laravel's public directory
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
 && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Copy application source
COPY . /var/www/html

# Ensure Laravel storage/cache directories exist and are writable, then install dependencies
RUN mkdir -p \
      storage/framework/cache \
      storage/framework/sessions \
      storage/framework/views \
      bootstrap/cache \
 && chown -R www-data:www-data storage bootstrap/cache \
 && composer install \
    --no-dev \
    --optimize-autoloader \
    --no-interaction \
    --no-progress

# Startup script: runs migrations + admin promotion, then starts Apache.
# Used as CMD so the base image's ENTRYPOINT (docker-php-entrypoint) still runs first.
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Expose HTTP port (Render will map this)
EXPOSE 80

# Start: runtime setup then Apache (via base image's docker-php-entrypoint)
CMD ["docker-entrypoint.sh"]

