#!/bin/bash

# Goldexperte Pimcore - Setup Script
# This script installs and configures Pimcore

set -e

echo "⚙️ Setting up Goldexperte Pimcore..."

# Check if containers are running
if ! docker-compose ps | grep -q "goldexperte-dev-php"; then
    echo "❌ Docker containers are not running. Please run 'docker-compose up -d' first."
    exit 1
fi

# Wait for database to be ready
echo "⏳ Waiting for database to be ready..."
docker-compose exec php bash -c "
    while ! mysql -h db -u pimcore -ppimcore_password goldexperte_pimcore -e 'SELECT 1' >/dev/null 2>&1; do
        echo 'Waiting for database...'
        sleep 2
    done
    echo 'Database is ready!'
"

# Check if Pimcore is already installed
if docker-compose exec php bash -c "[ -f /var/www/html/var/config/system.yml ]" >/dev/null 2>&1; then
    echo "ℹ️ Pimcore appears to be already installed."
    read -p "Do you want to reinstall? This will delete all data! (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi
    
    echo "🗑️ Cleaning previous installation..."
    docker-compose exec php bash -c "rm -rf /var/www/html/var/config/system.yml"
fi

# Install Pimcore
echo "🏗️ Installing Pimcore..."
docker-compose exec php bash -c "
    vendor/bin/pimcore-install \
        --mysql-host-socket=db \
        --mysql-username=pimcore \
        --mysql-password=pimcore_password \
        --mysql-database=goldexperte_pimcore \
        --admin-username=admin \
        --admin-password=admin_password \
        --install-bundles=PimcoreApplicationLoggerBundle,PimcoreCustomReportsBundle,PimcoreSeoBundle,PimcoreSimpleBackendSearchBundle,PimcoreStaticRoutesBundle,PimcoreTinymceBundle,PimcoreUuidBundle,PimcoreEcommerceFrameworkBundle \
        --no-interaction
"

# Configure headless mode
echo "🎯 Configuring headless mode..."
docker-compose exec php bash -c "
    # Enable REST API
    php bin/console pimcore:bundle:enable PimcoreRestApiBundle || true
    
    # Clear cache
    php bin/console cache:clear
    
    # Warm up cache
    php bin/console cache:warmup
"

# Configure Elasticsearch (if available)
echo "🔍 Configuring Elasticsearch..."
docker-compose exec php bash -c "
    # Wait for Elasticsearch to be ready
    while ! curl -s http://elasticsearch:9200/_cluster/health >/dev/null 2>&1; do
        echo 'Waiting for Elasticsearch...'
        sleep 2
    done
    
    # Configure search backend
    php bin/console pimcore:search-backend-reindex || echo 'Search backend configuration will be done later'
"

# Set proper permissions
echo "🔐 Setting final permissions..."
docker-compose exec php bash -c "
    chown -R www-data:www-data /var/www/html/var /var/www/html/public/var
    chmod -R 755 /var/www/html/var /var/www/html/public/var
"

echo "✅ Pimcore setup completed successfully!"
echo ""
echo "🎉 Your Goldexperte Pimcore backend is now ready!"
echo ""
echo "📱 Access points:"
echo "   • Admin Panel: http://localhost:8080/admin"
echo "   • API Endpoint: http://localhost:8080/api"
echo "   • MailHog: http://localhost:8025"
echo "   • Elasticsearch: http://localhost:9200"
echo ""
echo "🔐 Default credentials:"
echo "   • Username: admin"
echo "   • Password: admin_password"
echo ""
echo "⚠️  Don't forget to:"
echo "   1. Change default admin password"
echo "   2. Configure your headless API endpoints"
echo "   3. Set up your content structure"
