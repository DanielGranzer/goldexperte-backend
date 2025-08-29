# Goldexperte Pimcore Backend

A headless Pimcore CMS setup for the Goldexperten project providing content for multiple Next.js frontends.

## Domains

- **Main Frontend**: https://www.diegoldexperten.com/
- **Admin Panel**: https://admin.diegoldexperten.com/
- **API Endpoint**: https://api.diegoldexperten.com/

## Tech Stack

- [Pimcore](https://pimcore.com/) - Headless CMS
- [Docker](https://www.docker.com/) - Containerization
- [Traefik](https://traefik.io/) - Reverse Proxy & Load Balancer
- [Redis](https://redis.io) - Caching
- [Elasticsearch](https://www.elastic.co/) - Search Engine
- [MailHog](https://github.com/mailhog/MailHog) - Email Testing
- [Let's Encrypt](https://letsencrypt.org/) - SSL Certificates
- [MariaDB](https://mariadb.org/) - Database
- [Terraform](https://www.terraform.io/) - Infrastructure as Code
- [Ansible](https://ansible.com/) - Configuration Management

## Prerequisites

### Local Development
- [Docker](https://www.docker.com/)
- [Node.js 18+](https://nodejs.org/en/)
- [Composer](https://getcomposer.org/)

### Production Deployment
- [Terraform](https://www.terraform.io/)
- [Ansible](https://ansible.com/)

## Quick Start

1. **Initialize Pimcore Project**
   ```bash
   ./scripts/init-project.sh
   ```

2. **Start Development Environment**
   ```bash
   docker-compose up -d
   ```

3. **Install Dependencies**
   ```bash
   ./scripts/install-dependencies.sh
   ```

4. **Setup Pimcore**
   ```bash
   ./scripts/setup-pimcore.sh
   ```

5. **Access Services**
   - Pimcore Admin: http://localhost:8080/admin
   - API Endpoint: http://localhost:8080/api
   - MailHog: http://localhost:8025
   - Elasticsearch: http://localhost:9200

## Development

### Directory Structure
```
├── docker-compose.yml          # Local development containers
├── docker-compose.prod.yml     # Production containers with Traefik
├── pimcore/                    # Pimcore application
├── scripts/                    # Helper scripts
├── devops/                     # Infrastructure & deployment
│   ├── terraform/              # Infrastructure as Code
│   └── ansible/                # Server provisioning
└── docs/                       # Documentation
```

### Environment Configuration

Copy and configure environment files:
```bash
cp .env.example .env
cp pimcore/.env.example pimcore/.env
```

## Features

- ✅ Headless CMS architecture
- ✅ Multi-domain support with Traefik
- ✅ Auto SSL with Let's Encrypt
- ✅ Redis caching
- ✅ Elasticsearch integration
- ✅ Email testing with MailHog
- ✅ Development & production configs
- ✅ Infrastructure automation
- ✅ API-first approach for Next.js frontends

## API Endpoints

The headless Pimcore setup provides RESTful APIs for:

- `/api/content` - Content management
- `/api/products` - Product data
- `/api/assets` - Media assets
- `/api/search` - Elasticsearch-powered search

## Deployment

### Development
```bash
docker-compose up -d
```

### Production
```bash
# Deploy infrastructure
cd devops/terraform
terraform apply

# Provision servers
cd ../ansible
ansible-playbook -i inventory production.yml
```

## Documentation

- [Project Setup](./docs/project-setup.md)
- [API Documentation](./docs/api.md)
- [Deployment Guide](./docs/deployment.md)
- [Troubleshooting](./docs/troubleshooting.md)
