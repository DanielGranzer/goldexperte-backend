FROM pimcore/pimcore:php8.2-latest

# Install additional PHP extensions and tools needed for headless setup
RUN apt-get update && apt-get install -y \
    # Additional tools
    curl \
    wget \
    unzip \
    git \
    supervisor \
    # Elasticsearch PHP client requirements
    libcurl4-openssl-dev \
    # Image processing
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libwebp-dev \
    # Video processing
    ffmpeg \
    # PDF processing
    poppler-utils \
    # Cleanup
    && rm -rf /var/lib/apt/lists/*

# Configure PHP extensions
RUN docker-php-ext-configure gd \
        --with-freetype \
        --with-jpeg \
        --with-webp \
    && docker-php-ext-install -j$(nproc) gd

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Install additional PHP packages via PECL
RUN pecl install redis elasticsearch \
    && docker-php-ext-enable redis

# Custom PHP configuration
COPY php.ini /usr/local/etc/php/conf.d/99-custom.ini

# Set proper permissions
RUN chown -R www-data:www-data /var/www

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:9000/health || exit 1

WORKDIR /var/www/html

EXPOSE 9000

CMD ["php-fpm"]
