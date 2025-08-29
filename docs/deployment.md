# Deployment Guide

This guide covers deploying the Goldexperte Pimcore backend to production using Terraform and Ansible.

## Prerequisites

### Local Requirements

- **Terraform** >= 1.0
- **Ansible** >= 2.9
- **Git** for repository management
- **SSH Key** for server access

### Cloud Provider

- **Hetzner Cloud Account** with API token
- **Domain** configured with DNS management access

## Infrastructure Setup

### 1. Configure Terraform

Navigate to the Terraform directory:

```bash
cd devops/terraform
```

Copy and configure the variables file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your configuration:

```hcl
# Required: Hetzner Cloud API Token
hcloud_token = "your-hetzner-cloud-api-token"

# Server Configuration
server_type     = "cx31"    # 2 vCPUs, 8GB RAM, 80GB SSD
server_location = "nbg1"    # Nuremberg
volume_size     = 100       # GB

# Security (IMPORTANT: Replace with your IPs!)
allowed_ssh_ips = ["1.2.3.4/32"]      # Your IP for SSH
allowed_admin_ips = ["1.2.3.4/32"]    # Your IP for admin access

# Domains
main_domain  = "diegoldexperten.com"
admin_domain = "admin.diegoldexperten.com"
api_domain   = "api.diegoldexperten.com"
acme_email   = "admin@diegoldexperten.com"
```

### 2. Deploy Infrastructure

#### Automated Deployment

Use the deployment script for easy setup:

```bash
# From project root
./scripts/deploy-production.sh    # Linux/Mac
# or
scripts\deploy-production.bat     # Windows
```

#### Manual Deployment

If you prefer manual control:

```bash
cd devops/terraform

# Initialize Terraform
terraform init

# Plan changes
terraform plan

# Apply changes
terraform apply

# Save outputs for Ansible
terraform output -raw ansible_inventory > ../ansible/inventory
```

### 3. Configure DNS

After infrastructure deployment, configure your DNS records:

```
# A Records (IPv4)
diegoldexperten.com           A    YOUR_SERVER_IP
admin.diegoldexperten.com     A    YOUR_SERVER_IP
api.diegoldexperten.com       A    YOUR_SERVER_IP

# AAAA Records (IPv6)
diegoldexperten.com           AAAA YOUR_SERVER_IPV6
admin.diegoldexperten.com     AAAA YOUR_SERVER_IPV6
api.diegoldexperten.com       AAAA YOUR_SERVER_IPV6

# Optional subdomains
mailhog.diegoldexperten.com   A    YOUR_SERVER_IP
traefik.diegoldexperten.com   A    YOUR_SERVER_IP
```

## Server Provisioning

### 1. Configure Ansible

Navigate to the Ansible directory:

```bash
cd devops/ansible
```

If you didn't use the automated deployment, create the inventory file:

```bash
cp inventory.example inventory
```

Edit the inventory with your server details and secrets:

```ini
[pimcore_servers]
goldexperte-pimcore-prod ansible_host=YOUR_SERVER_IP ansible_user=root

[pimcore_servers:vars]
main_domain=diegoldexperten.com
admin_domain=admin.diegoldexperten.com
api_domain=api.diegoldexperten.com
acme_email=admin@diegoldexperten.com

# Database configuration (use strong passwords!)
mysql_root_password=very_secure_root_password
mysql_pimcore_password=very_secure_pimcore_password
mysql_pimcore_database=goldexperte_pimcore

# Pimcore admin (change these!)
pimcore_admin=admin
pimcore_admin_password=very_secure_admin_password

# Git repository
git_repo_url=https://github.com/yourusername/goldexperte-backend.git
```

### 2. Run Provisioning

```bash
# Test connection
ansible all -i inventory -m ping

# Run full provisioning
ansible-playbook -i inventory provision.yml
```

The provisioning process will:

1. Install Docker and required packages
2. Configure firewall and security
3. Clone your repository
4. Start all services with Docker Compose
5. Install and configure Pimcore
6. Set up SSL certificates with Let's Encrypt
7. Configure monitoring and maintenance tasks

## Production Configuration

### Environment Variables

The production environment uses different settings optimized for performance and security:

```env
# Production environment
NODE_ENV=production
PIMCORE_ENVIRONMENT=prod
DEBUG=false

# Optimized resource limits
PHP_MEMORY_LIMIT=1024M

# Security
APP_SECRET=auto-generated-secure-secret
```

### SSL/TLS Certificates

Let's Encrypt certificates are automatically provisioned and renewed via Traefik:

- **HTTP** traffic is automatically redirected to **HTTPS**
- Certificates are renewed automatically every 90 days
- HSTS headers are configured for enhanced security

### Services

The production stack includes:

- **Traefik** - Reverse proxy with automatic SSL
- **Nginx** - Web server optimized for Pimcore
- **PHP-FPM** - PHP processor with production settings
- **MariaDB** - Database with optimized configuration
- **Redis** - High-performance caching
- **Elasticsearch** - Search engine for content
- **Supervisor** - Background task management
- **MailHog** - Email testing (can be disabled in production)

## Monitoring and Maintenance

### Health Checks

Automated health checks are configured to monitor:

- Service availability
- Database connectivity
- Disk space usage
- SSL certificate expiration

### Automated Tasks

Cron jobs are set up for:

```cron
# Pimcore maintenance (daily at 2 AM)
0 2 * * * cd /opt/goldexperte-pimcore && docker-compose -f docker-compose.prod.yml exec -T php php bin/console pimcore:maintenance

# Health checks (every 5 minutes)
*/5 * * * * /usr/local/bin/goldexperte-health-check

# Docker cleanup (daily at 3 AM)
0 3 * * * docker system prune -f
```

### Log Management

Logs are automatically rotated to prevent disk space issues:

- **Application logs**: `/mnt/pimcore-data/logs/`
- **Docker logs**: Managed by Docker daemon
- **System logs**: Standard `/var/log/` locations

### Backup Strategy

**Important**: Set up regular backups for:

1. **Database**: 
   ```bash
   docker-compose exec db mysqldump -u root -p goldexperte_pimcore > backup.sql
   ```

2. **Pimcore assets**:
   ```bash
   tar -czf pimcore-assets.tar.gz /mnt/pimcore-data/pimcore/
   ```

3. **Configuration files**:
   ```bash
   tar -czf config-backup.tar.gz /opt/goldexperte-pimcore/
   ```

## Security Considerations

### Firewall Configuration

The server firewall is configured to allow only necessary ports:

- **22** (SSH) - Restricted to your IP addresses
- **80** (HTTP) - Redirects to HTTPS
- **443** (HTTPS) - Public access
- **8080** (Traefik Dashboard) - Restricted to admin IPs

### Security Headers

Nginx is configured with security headers:

```nginx
add_header X-Frame-Options "SAMEORIGIN";
add_header X-XSS-Protection "1; mode=block";
add_header X-Content-Type-Options "nosniff";
add_header Referrer-Policy "strict-origin-when-cross-origin";
```

### Database Security

- Root password is randomly generated
- Pimcore user has limited privileges
- Database is not exposed externally
- All connections use strong passwords

## Scaling and Performance

### Vertical Scaling

To increase server resources:

1. Update `server_type` in `terraform.tfvars`
2. Run `terraform apply`
3. The server will be resized automatically

### Horizontal Scaling

For high-traffic scenarios:

1. Enable load balancer in Terraform
2. Deploy multiple Pimcore instances
3. Use external database service
4. Configure Redis cluster

### Performance Optimization

Production optimizations include:

- **OPcache** enabled for PHP
- **Redis** for session and cache storage
- **Elasticsearch** for fast content search
- **Nginx** with gzip compression
- **CDN**-ready asset serving

## Troubleshooting

### Common Issues

1. **SSL Certificate Issues**
   ```bash
   # Check Traefik logs
   docker-compose logs traefik
   
   # Force certificate renewal
   docker-compose restart traefik
   ```

2. **Database Connection Problems**
   ```bash
   # Check database status
   docker-compose exec db mysql -u root -p -e "SHOW PROCESSLIST;"
   ```

3. **Performance Issues**
   ```bash
   # Monitor resource usage
   htop
   docker stats
   ```

### Log Analysis

Key log locations for troubleshooting:

```bash
# Application logs
docker-compose logs -f php

# Web server logs
docker-compose logs -f nginx

# Database logs
docker-compose logs -f db

# Traefik logs
docker-compose logs -f traefik
```

## Updates and Maintenance

### Updating the Application

1. Update your code repository
2. SSH to the server
3. Pull latest changes:
   ```bash
   cd /opt/goldexperte-pimcore
   git pull
   docker-compose -f docker-compose.prod.yml pull
   docker-compose -f docker-compose.prod.yml up -d
   ```

### System Updates

```bash
# Update system packages
apt update && apt upgrade -y

# Update Docker images
docker-compose pull

# Restart services
docker-compose up -d
```

## Rollback Procedures

In case of deployment issues:

1. **Terraform rollback**:
   ```bash
   terraform apply -target=resource_name
   ```

2. **Application rollback**:
   ```bash
   git checkout previous-commit
   docker-compose up -d
   ```

3. **Database rollback**:
   Restore from backup using standard MySQL procedures

## Support and Monitoring

### Monitoring Setup

Consider implementing:

- **Prometheus** + **Grafana** for metrics
- **ELK Stack** for centralized logging  
- **Uptime monitoring** services
- **SSL certificate monitoring**

### Support Contacts

- **Hetzner Cloud Support**: For infrastructure issues
- **Pimcore Community**: For CMS-related questions
- **Project Team**: For application-specific problems
