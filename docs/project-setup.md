# Project Setup Guide

This guide will help you set up the Goldexperte Pimcore backend project for local development.

## Prerequisites

Before you begin, ensure you have the following installed:

- **Docker Desktop** (Windows/Mac) or **Docker Engine** (Linux)
- **Git** for version control
- **Node.js 18+** (optional, for local development tools)

## Quick Setup

### 1. Clone the Repository

```bash
git clone <your-repository-url>
cd goldexperte-backend
```

### 2. Initialize the Project

#### Windows:
```cmd
scripts\init-project.bat
```

#### Linux/Mac:
```bash
chmod +x scripts/*.sh
./scripts/init-project.sh
```

This script will:
- Create the Pimcore skeleton project
- Set up environment configuration files
- Configure proper file permissions

### 3. Configure Environment

Edit the `.env` file to match your local development needs:

```env
# Database passwords
DB_ROOT_PASSWORD=your_secure_root_password
DB_PASSWORD=your_secure_pimcore_password

# Admin credentials
PIMCORE_ADMIN_USER=admin
PIMCORE_ADMIN_PASSWORD=your_secure_admin_password

# Docker user (Linux/Mac only - set to your uid:gid)
DOCKER_USER=1000:1000
```

**Important for Windows users**: The `DOCKER_USER` variable is automatically handled by Docker Desktop.

### 4. Start Development Environment

```bash
docker-compose up -d
```

This will start all services:
- **MariaDB** - Database server
- **Redis** - Caching server
- **Elasticsearch** - Search engine
- **PHP-FPM** - PHP processor
- **Nginx** - Web server
- **Supervisor** - Background task manager
- **MailHog** - Email testing server

### 5. Install Dependencies

#### Windows:
```cmd
scripts\install-dependencies.bat
```

#### Linux/Mac:
```bash
./scripts/install-dependencies.sh
```

### 6. Setup Pimcore

#### Windows:
```cmd
scripts\setup-pimcore.bat
```

#### Linux/Mac:
```bash
./scripts/setup-pimcore.sh
```

## Access Your Application

After setup is complete, you can access:

- **Pimcore Admin**: http://localhost:8080/admin
- **API Endpoint**: http://localhost:8080/api
- **MailHog Interface**: http://localhost:8025
- **Elasticsearch**: http://localhost:9200

### Default Credentials

- **Username**: admin
- **Password**: admin_password (or what you set in `.env`)

## Development Workflow

### Container Management

```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# View logs
docker-compose logs -f

# Access PHP container
docker-compose exec php bash

# Access database
docker-compose exec db mysql -u pimcore -p goldexperte_pimcore
```

### Common Tasks

#### Clear Pimcore Cache
```bash
docker-compose exec php php bin/console cache:clear
```

#### Run Pimcore Maintenance
```bash
docker-compose exec php php bin/console pimcore:maintenance
```

#### Rebuild Search Index
```bash
docker-compose exec php php bin/console pimcore:search-backend-reindex
```

#### Install/Update Composer Dependencies
```bash
docker-compose exec php composer install
```

#### Build Frontend Assets (if applicable)
```bash
docker-compose exec php npm run dev
```

## File Structure

```
goldexperte-backend/
├── docker-compose.yml          # Development containers
├── docker-compose.prod.yml     # Production containers  
├── .env                        # Environment variables
├── pimcore/                    # Pimcore application
│   ├── bin/                    # Pimcore console commands
│   ├── config/                 # Configuration files
│   ├── public/                 # Web root
│   ├── src/                    # Custom PHP code
│   ├── templates/              # Twig templates
│   └── var/                    # Cache and logs
├── docker/                     # Docker configurations
│   ├── nginx/                  # Nginx configuration
│   ├── php/                    # PHP configuration
│   └── supervisor/             # Background tasks
├── scripts/                    # Helper scripts
├── devops/                     # Infrastructure code
│   ├── terraform/              # Infrastructure as Code
│   └── ansible/                # Server provisioning
└── docs/                       # Documentation
```

## Environment Configuration

### Development (.env)

The `.env` file contains all environment-specific configuration:

```env
# Environment
NODE_ENV=development
PIMCORE_ENVIRONMENT=dev

# Database
DB_HOST=db
DB_PORT=3306
DB_NAME=goldexperte_pimcore
DB_USER=pimcore
DB_PASSWORD=pimcore_password
DB_ROOT_PASSWORD=root_password

# Services
REDIS_HOST=redis
ELASTICSEARCH_HOST=elasticsearch
MAILER_DSN=smtp://mailhog:1025

# Security
APP_SECRET=your-app-secret-key-here

# Development
DEBUG=true
PHP_MEMORY_LIMIT=2048M
```

### Pimcore Configuration (pimcore/.env)

Pimcore-specific configuration is stored in `pimcore/.env`:

```env
APP_ENV=dev
DATABASE_URL="mysql://pimcore:pimcore_password@db:3306/goldexperte_pimcore?serverVersion=10.11-MariaDB&charset=utf8mb4"
REDIS_URL="redis://redis:6379"
ELASTICSEARCH_URL="http://elasticsearch:9200"
MAILER_DSN="smtp://mailhog:1025"
```

## Troubleshooting

### Common Issues

1. **Port conflicts**: Make sure ports 8080, 3306, 6379, 9200, 8025 are not in use
2. **Permission issues**: On Linux/Mac, ensure your user ID is correctly set in `DOCKER_USER`
3. **Database connection errors**: Wait for the database to be fully ready (check logs with `docker-compose logs db`)

### Useful Commands

```bash
# Check service status
docker-compose ps

# View all logs
docker-compose logs

# Restart a specific service
docker-compose restart nginx

# Remove all containers and volumes (⚠️ DATA LOSS!)
docker-compose down -v

# Clean up Docker system
docker system prune -f
```

### Log Locations

- **Nginx**: `docker-compose logs nginx`
- **PHP**: `docker-compose logs php`
- **Database**: `docker-compose logs db`
- **Pimcore**: `pimcore/var/logs/`

## Next Steps

1. **Configure Content Structure**: Set up your data objects, classes, and content in Pimcore
2. **API Development**: Create custom API endpoints for your Next.js frontend
3. **Security**: Change all default passwords and configure proper security settings
4. **Production Deployment**: Follow the [Deployment Guide](./deployment.md) for production setup

## Getting Help

- **Pimcore Documentation**: https://pimcore.com/docs/
- **Docker Documentation**: https://docs.docker.com/
- **Project Issues**: Create an issue in the project repository
