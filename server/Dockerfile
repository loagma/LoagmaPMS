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

# Install PHP dependencies (no dev) for production
RUN composer install \
    --no-dev \
    --optimize-autoloader \
    --no-interaction \
    --no-progress

# Expose HTTP port (Render will map this)
EXPOSE 80

# Start Apache
CMD ["apache2-foreground"]

