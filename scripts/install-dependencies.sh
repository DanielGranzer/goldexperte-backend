#!/bin/bash

# Goldexperte Pimcore - Install Dependencies Script
# This script installs PHP and Node.js dependencies

set -e

echo "📦 Installing Goldexperte Pimcore Dependencies..."

# Check if containers are running
if ! docker-compose ps | grep -q "goldexperte-dev-php"; then
    echo "❌ Docker containers are not running. Please run 'docker-compose up -d' first."
    exit 1
fi

# Install PHP dependencies
echo "🐘 Installing PHP dependencies..."
docker-compose exec php bash -c "COMPOSER_MEMORY_LIMIT=-1 composer install --no-interaction --optimize-autoloader"

# Install Node.js dependencies (if package.json exists)
if [ -f "pimcore/package.json" ]; then
    echo "📦 Installing Node.js dependencies..."
    docker-compose exec php bash -c "cd /var/www/html && npm install --force"
    
    echo "🏗️ Building frontend assets..."
    docker-compose exec php bash -c "cd /var/www/html && npm run dev"
else
    echo "ℹ️ No package.json found, skipping Node.js dependencies."
fi

# Set proper permissions
echo "🔐 Setting proper file permissions..."
docker-compose exec php bash -c "chown -R www-data:www-data /var/www/html/var /var/www/html/public/var"
docker-compose exec php bash -c "chmod -R 755 /var/www/html/var /var/www/html/public/var"

echo "✅ Dependencies installed successfully!"
echo ""
echo "🎯 Next step: ./scripts/setup-pimcore.sh"
