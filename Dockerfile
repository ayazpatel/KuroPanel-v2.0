# Use official PHP image with Apache
FROM php:8.2-apache

# Set working directory
WORKDIR /var/www/html

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libicu-dev \
    libzip-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libonig-dev \
    libxml2-dev \
    libcurl4-openssl-dev \
    sqlite3 \
    libsqlite3-dev \
    vim \
    nano \
    curl \
    wget \
    cron \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions with OPCache optimization
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install \
    pdo \
    pdo_mysql \
    pdo_sqlite \
    mysqli \
    mbstring \
    exif \
    pcntl \
    bcmath \
    gd \
    zip \
    intl \
    curl \
    xml \
    opcache

# Configure OPCache for production
RUN echo "opcache.enable=1" >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini \
    && echo "opcache.memory_consumption=256" >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini \
    && echo "opcache.max_accelerated_files=20000" >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini \
    && echo "opcache.revalidate_freq=0" >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini

# Enable Apache modules
RUN a2enmod rewrite headers ssl

# Copy custom Apache configuration
COPY docker/apache/000-default.conf /etc/apache2/sites-available/000-default.conf

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy application files
COPY . .

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html \
    && chmod -R 777 /var/www/html/writable \
    && chmod +x /var/www/html/docker/scripts/*.sh

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Copy supervisor configuration
COPY docker/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Setup cron for maintenance tasks
RUN echo "0 2 * * * www-data /var/www/html/docker/scripts/backup.sh" >> /etc/crontab \
    && echo "*/5 * * * * www-data /var/www/html/docker/scripts/monitor.sh" >> /etc/crontab \
    && echo "0 */6 * * * www-data /var/www/html/docker/scripts/cleanup.sh" >> /etc/crontab

# Create environment file and run setup
RUN cp .env.development .env.example \
    && cp .env.example .env \
    && php setup_kuro_v2.php --docker-mode

# Expose ports
EXPOSE 80 443

# Add health check with V2 endpoint
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD /var/www/html/docker/scripts/health-check.sh quick

# Use supervisor to manage multiple processes
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
