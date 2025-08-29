#!/bin/bash

# Goldexperte Pimcore - Production Deployment Script
# This script deploys the application to production using Terraform and Ansible

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🚀 Goldexperte Pimcore Production Deployment"
echo "============================================"

# Check prerequisites
echo "🔍 Checking prerequisites..."

if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed. Please install Terraform and try again."
    exit 1
fi

if ! command -v ansible-playbook &> /dev/null; then
    echo "❌ Ansible is not installed. Please install Ansible and try again."
    exit 1
fi

# Navigate to terraform directory
cd "$PROJECT_ROOT/devops/terraform"

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo "❌ terraform.tfvars not found. Please copy terraform.tfvars.example and configure it."
    exit 1
fi

# Initialize Terraform
echo "🏗️ Initializing Terraform..."
terraform init

# Plan infrastructure changes
echo "📋 Planning infrastructure changes..."
terraform plan -out=tfplan

# Ask for confirmation
read -p "🤔 Do you want to apply these changes? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Deployment cancelled."
    exit 0
fi

# Apply infrastructure changes
echo "🚀 Applying infrastructure changes..."
terraform apply tfplan

# Generate Ansible inventory
echo "📝 Generating Ansible inventory..."
terraform output -raw ansible_inventory > ../ansible/inventory

# Navigate to ansible directory
cd ../ansible

# Check if inventory was generated correctly
if [ ! -s "inventory" ]; then
    echo "❌ Failed to generate Ansible inventory. Please check Terraform outputs."
    exit 1
fi

# Wait for server to be ready
echo "⏳ Waiting for server to be ready (60 seconds)..."
sleep 60

# Run Ansible provisioning
echo "⚙️ Running Ansible provisioning..."
ansible-playbook -i inventory provision.yml

# Display deployment information
echo ""
echo "✅ Deployment completed successfully!"
echo ""
echo "🌐 Your Goldexperte Pimcore backend is now available at:"
terraform -chdir=../terraform output dns_configuration
echo ""
echo "🔐 Don't forget to:"
echo "   1. Update your DNS records as shown above"
echo "   2. Change default passwords"
echo "   3. Configure your Pimcore content structure"
echo "   4. Test all endpoints"
