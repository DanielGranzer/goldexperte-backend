@echo off
REM Goldexperte Pimcore - Project Initialization Script (Windows)
REM This script initializes a new Pimcore project on Windows

echo 🚀 Initializing Goldexperte Pimcore Project...

REM Check if Docker is running
docker info >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker is not running. Please start Docker and try again.
    exit /b 1
)

REM Create pimcore directory if it doesn't exist
if not exist "pimcore" (
    echo 📦 Creating Pimcore skeleton project...
    
    REM Create Pimcore project using official container
    docker run --rm -v "%cd%:/var/www/html" pimcore/pimcore:php8.2-latest composer create-project pimcore/skeleton pimcore --no-interaction
    
    echo ✅ Pimcore skeleton created successfully!
) else (
    echo ℹ️ Pimcore directory already exists, skipping skeleton creation.
)

REM Copy environment file
if not exist ".env" (
    echo 📝 Creating environment configuration...
    copy .env.example .env
    echo ✅ Environment file created. Please review and update .env as needed.
) else (
    echo ℹ️ Environment file already exists.
)

REM Create Pimcore environment file
if not exist "pimcore\.env" (
    echo 📝 Creating Pimcore environment configuration...
    (
        echo # Pimcore Environment Configuration
        echo APP_ENV=dev
        echo APP_SECRET=your-generated-secret-key-here
        echo.
        echo # Database
        echo DATABASE_URL="mysql://pimcore:pimcore_password@db:3306/goldexperte_pimcore?serverVersion=10.11-MariaDB&charset=utf8mb4"
        echo.
        echo # Redis
        echo REDIS_URL="redis://redis:6379"
        echo.
        echo # Elasticsearch  
        echo ELASTICSEARCH_URL="http://elasticsearch:9200"
        echo.
        echo # Mailer ^(MailHog for development^)
        echo MAILER_DSN="smtp://mailhog:1025"
        echo.
        echo # Pimcore specific
        echo PIMCORE_ENVIRONMENT=dev
        echo PIMCORE_DEV_MODE=true
    ) > pimcore\.env
    echo ✅ Pimcore environment file created.
)

echo ✅ Project initialization completed!
echo.
echo 🎯 Next steps:
echo 1. Review and update .env file with your configuration
echo 2. Run: docker-compose up -d
echo 3. Run: scripts\install-dependencies.bat
echo 4. Run: scripts\setup-pimcore.bat
echo.
echo 📖 For more information, see README.md
pause
