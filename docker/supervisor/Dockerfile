FROM pimcore/pimcore:php8.2-supervisord-latest

# Install additional packages
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Copy supervisor configuration
COPY conf.d/ /etc/supervisor/conf.d/

# Set proper permissions
RUN chown -R www-data:www-data /var/www

WORKDIR /var/www/html

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
