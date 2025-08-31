#!/bin/bash

# Setup Script for Metals API Integration
# This script sets up the complete metals API integration system

set -e

echo "🏅 Setting up Metals API Integration for GoldExperte"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "composer.json" ]; then
    print_error "Please run this script from the Pimcore root directory"
    exit 1
fi

echo "Step 1: Checking environment..."

# Check PHP version
php_version=$(php -v | head -n1 | awk '{print $2}' | cut -d. -f1,2)
if [[ $(echo "$php_version >= 8.1" | bc) -eq 1 ]]; then
    print_status "PHP version: $php_version"
else
    print_error "PHP 8.1 or higher required. Current: $php_version"
    exit 1
fi

# Check if Pimcore is installed
if [ ! -d "vendor/pimcore" ]; then
    print_error "Pimcore not found. Please install Pimcore first."
    exit 1
fi

print_status "Pimcore installation found"

echo ""
echo "Step 2: Installing Metals API components..."

# Create necessary directories
mkdir -p var/classes
mkdir -p src/DataObject
mkdir -p src/Service
mkdir -p src/Controller/Api
mkdir -p src/Command
mkdir -p docs

print_status "Created directory structure"

# Check if MetalPrice data object needs to be installed
if [ ! -f "var/classes/definition_MetalPrice_simple.json" ]; then
    print_warning "MetalPrice data object not found in var/classes/"
    echo "Please install the MetalPrice class definition through:"
    echo "1. Pimcore Admin → Settings → Data Objects → Classes"
    echo "2. Import the definition_MetalPrice_simple.json file"
    echo "3. Or copy it manually to var/classes/ and rebuild classes"
fi

echo ""
echo "Step 3: Configuring environment variables..."

# Check if .env file exists
if [ ! -f ".env" ]; then
    print_warning ".env file not found, creating from .env.example"
    if [ -f ".env.example" ]; then
        cp .env.example .env
    else
        touch .env
    fi
fi

# Check for required environment variables
if ! grep -q "METALS_API_KEY" .env; then
    echo "" >> .env
    echo "# Metals API Configuration" >> .env
    echo "METALS_API_KEY=your-metals-api-key-here" >> .env
    print_warning "Added METALS_API_KEY to .env - please update with your actual API key"
fi

if ! grep -q "ADMIN_API_KEY" .env; then
    echo "ADMIN_API_KEY=$(openssl rand -base64 32)" >> .env
    print_status "Generated ADMIN_API_KEY"
fi

echo ""
echo "Step 4: Setting up database..."

# Run database schema update (if needed)
if command -v php bin/console &> /dev/null; then
    print_status "Updating database schema..."
    php bin/console doctrine:schema:update --force --quiet || print_warning "Schema update failed - this is normal if classes aren't installed yet"
    
    # Clear cache
    print_status "Clearing cache..."
    php bin/console cache:clear --quiet
else
    print_warning "Could not run console commands - please run manually:"
    echo "  php bin/console doctrine:schema:update --force"
    echo "  php bin/console cache:clear"
fi

echo ""
echo "Step 5: Creating MetalPrices folder..."

# This would need to be done through Pimcore API or admin panel
print_warning "Please create /MetalPrices folder in Pimcore admin:"
echo "1. Go to Pimcore Admin → Objects"
echo "2. Right-click on root folder"
echo "3. Create new folder named 'MetalPrices'"

echo ""
echo "Step 6: Setting up cron jobs..."

echo "Add these cron jobs for automatic price updates:"
echo ""
echo "# Weekdays: Every 3 hours"
echo "0 */3 * * 1-6 $(which php) $(pwd)/bin/console app:update-metal-prices"
echo ""
echo "# Sunday: Once in the morning" 
echo "0 9 * * 0 $(which php) $(pwd)/bin/console app:update-metal-prices"
echo ""

read -p "Would you like to add these cron jobs automatically? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Add to crontab
    (crontab -l 2>/dev/null; echo "# GoldExperte Metals API Updates"; echo "0 */3 * * 1-6 $(which php) $(pwd)/bin/console app:update-metal-prices"; echo "0 9 * * 0 $(which php) $(pwd)/bin/console app:update-metal-prices") | crontab -
    print_status "Cron jobs added"
else
    print_warning "Please add cron jobs manually using the commands above"
fi

echo ""
echo "Step 7: Testing installation..."

# Test console command
if php bin/console app:update-metal-prices --dry-run &>/dev/null; then
    print_status "Console command working"
else
    print_warning "Console command test failed - this is normal if MetalPrice class isn't installed yet"
fi

# Test API endpoints (basic)
if command -v curl &> /dev/null; then
    # This would need the web server running
    print_warning "API endpoint testing skipped - start your web server and test manually:"
    echo "  curl http://localhost/api/metal-prices/health"
else
    print_warning "curl not found - please test API endpoints manually"
fi

echo ""
echo "🎉 Setup Complete!"
echo "=================="
echo ""
echo "Next steps:"
echo "1. Update METALS_API_KEY in .env with your actual key from metals-api.com"
echo "2. Install MetalPrice data object through Pimcore admin"
echo "3. Create /MetalPrices folder in Pimcore objects"
echo "4. Test the system: php bin/console app:update-metal-prices --dry-run"
echo "5. Run first update: php bin/console app:update-metal-prices"
echo ""
echo "Documentation:"
echo "- Backend Guide: docs/METALS_API_INTEGRATION_GUIDE.md"
echo "- API Endpoints: http://your-domain/api/metal-prices/health"
echo ""
echo "Need help? Check the documentation or logs in var/log/"

# Create a quick test script
cat > test-metals-api.sh << 'EOF'
#!/bin/bash
echo "Testing Metals API Integration..."
echo "================================"

echo "1. Testing console command:"
php bin/console app:update-metal-prices --dry-run

echo ""
echo "2. Checking API usage:"
php bin/console app:update-metal-prices --dry-run | grep -E "(Monthly|Daily|Can Make)"

echo ""
echo "3. Testing API endpoint (if web server is running):"
curl -s http://localhost/api/metal-prices/health | jq . 2>/dev/null || echo "Web server not running or jq not installed"

echo ""
echo "Test complete!"
EOF

chmod +x test-metals-api.sh
print_status "Created test-metals-api.sh for testing"

echo ""
print_status "Setup script completed successfully!"
