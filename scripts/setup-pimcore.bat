@echo off
REM Goldexperte Pimcore - Setup Script (Windows)

echo ⚙️ Setting up Goldexperte Pimcore...

REM Check if containers are running
docker-compose ps | findstr "goldexperte-dev-php" >nul
if errorlevel 1 (
    echo ❌ Docker containers are not running. Please run 'docker-compose up -d' first.
    exit /b 1
)

REM Wait for database to be ready
echo ⏳ Waiting for database to be ready...
:waitdb
docker-compose exec db mysql -u pimcore -ppimcore_password goldexperte_pimcore -e "SELECT 1;" >nul 2>&1
if errorlevel 1 (
    echo Waiting for database...
    timeout /t 5 >nul
    goto waitdb
)
echo Database is ready!

REM Check if Pimcore is already installed
docker-compose exec php test -f var/config/system.yml >nul 2>&1
if not errorlevel 1 (
    echo ⚠️  Pimcore is already installed! Skipping installation...
    goto permissions
)

REM Install Pimcore
echo 🏗️ Installing Pimcore...
docker-compose exec php bash -c "vendor/bin/pimcore-install --mysql-host-socket=db --mysql-username=pimcore --mysql-password=pimcore_password --mysql-database=goldexperte_pimcore --admin-username=admin --admin-password=admin_password --install-bundles=PimcoreApplicationLoggerBundle,PimcoreCustomReportsBundle,PimcoreSeoBundle,PimcoreSimpleBackendSearchBundle,PimcoreStaticRoutesBundle,PimcoreTinymceBundle,PimcoreUuidBundle,PimcoreEcommerceFrameworkBundle --no-interaction"

REM Configure headless mode
echo 🎯 Configuring headless mode...
docker-compose exec php bash -c "php bin/console cache:clear && php bin/console cache:warmup"

REM Set proper permissions
:permissions
echo 🔐 Setting final permissions...
docker-compose exec php bash -c "chown -R www-data:www-data /var/www/html/var /var/www/html/public/var && chmod -R 755 /var/www/html/var /var/www/html/public/var"

echo ✅ Pimcore setup completed successfully!
echo.
echo 🎉 Your Goldexperte Pimcore backend is now ready!
echo.
echo 📱 Access points:
echo    • Admin Panel: http://localhost:8080/admin
echo    • API Endpoint: http://localhost:8080/api
echo    • MailHog: http://localhost:8025
echo    • Elasticsearch: http://localhost:9200
echo.
echo 🔐 Default credentials:
echo    • Username: admin
echo    • Password: admin_password
echo.
echo ⚠️  Don't forget to:
echo    1. Change default admin password
echo    2. Configure your headless API endpoints
echo    3. Set up your content structure
pause
