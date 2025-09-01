#!/bin/bash

# Goldexperte Pimcore - Project Initialization Script
# This script initializes a new Pimcore project

set -e

echo "🚀 Initializing Goldexperte Pimcore Project..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Create pimcore directory if it doesn't exist
if [ ! -d "pimcore" ]; then
    echo "📦 Creating Pimcore skeleton project..."
    
    # Get current user ID and group ID for proper permissions
    USER_ID=$(id -u)
    GROUP_ID=$(id -g)
    
    # Create Pimcore project using official container
    docker run --rm \
        -u "${USER_ID}:${GROUP_ID}" \
        -v "$(pwd):/var/www/html" \
        pimcore/pimcore:php8.2-latest \
        composer create-project pimcore/skeleton pimcore --no-interaction
    
    echo "✅ Pimcore skeleton created successfully!"
else
    echo "ℹ️ Pimcore directory already exists, skipping skeleton creation."
fi

# Copy environment file
if [ ! -f ".env" ]; then
    echo "📝 Creating environment configuration..."
    cp .env.example .env
    
    # Generate random app secret
    APP_SECRET=$(openssl rand -hex 32)
    sed -i "s/your-app-secret-key-here/${APP_SECRET}/g" .env
    
    echo "✅ Environment file created. Please review and update .env as needed."
else
    echo "ℹ️ Environment file already exists."
fi

# Create Pimcore environment file
if [ ! -f "pimcore/.env" ]; then
    echo "📝 Creating Pimcore environment configuration..."
    cat > pimcore/.env << EOF
# Pimcore Environment Configuration
APP_ENV=dev
APP_SECRET=${APP_SECRET:-$(openssl rand -hex 32)}

# Database
DATABASE_URL="mysql://pimcore:pimcore_password@db:3306/goldexperte_pimcore?serverVersion=10.11-MariaDB&charset=utf8mb4"

# Redis
REDIS_URL="redis://redis:6379"

# Elasticsearch  
ELASTICSEARCH_URL="http://elasticsearch:9200"

# Mailer (MailHog for development)
MAILER_DSN="smtp://mailhog:1025"

# Pimcore specific
PIMCORE_ENVIRONMENT=dev
PIMCORE_DEV_MODE=true
EOF
    echo "✅ Pimcore environment file created."
fi

# Set correct permissions
echo "🔐 Setting correct permissions..."
if [ -d "pimcore" ]; then
    USER_ID=$(id -u)
    GROUP_ID=$(id -g)
    
    # Update docker-compose.yml with correct user ID
    sed -i "s/DOCKER_USER:-1000:1000/DOCKER_USER:-${USER_ID}:${GROUP_ID}/g" docker-compose.yml
    
    # Ensure pimcore directory has correct permissions
    sudo chown -R "${USER_ID}:${GROUP_ID}" pimcore/ || true
fi

echo "✅ Project initialization completed!"
echo ""
echo "🎯 Next steps:"
echo "1. Review and update .env file with your configuration"
echo "2. Run: docker-compose up -d"
echo "3. Run: ./scripts/install-dependencies.sh"
echo "4. Run: ./scripts/setup-pimcore.sh"
echo ""
echo "📖 For more information, see README.md"
