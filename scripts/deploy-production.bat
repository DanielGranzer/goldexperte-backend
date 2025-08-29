@echo off
REM Goldexperte Pimcore - Production Deployment Script (Windows)

echo 🚀 Goldexperte Pimcore Production Deployment
echo ============================================

REM Check prerequisites
echo 🔍 Checking prerequisites...

where terraform >nul 2>&1
if errorlevel 1 (
    echo ❌ Terraform is not installed. Please install Terraform and try again.
    exit /b 1
)

where ansible-playbook >nul 2>&1
if errorlevel 1 (
    echo ❌ Ansible is not installed. Please install Ansible and try again.
    exit /b 1
)

REM Navigate to terraform directory
cd /d "%~dp0\..\devops\terraform"

REM Check if terraform.tfvars exists
if not exist "terraform.tfvars" (
    echo ❌ terraform.tfvars not found. Please copy terraform.tfvars.example and configure it.
    exit /b 1
)

REM Initialize Terraform
echo 🏗️ Initializing Terraform...
terraform init

REM Plan infrastructure changes
echo 📋 Planning infrastructure changes...
terraform plan -out=tfplan

REM Ask for confirmation
set /p REPLY="🤔 Do you want to apply these changes? (yes/no): "
if /i not "%REPLY%"=="yes" (
    echo Deployment cancelled.
    exit /b 0
)

REM Apply infrastructure changes
echo 🚀 Applying infrastructure changes...
terraform apply tfplan

REM Generate Ansible inventory
echo 📝 Generating Ansible inventory...
terraform output -raw ansible_inventory > ..\ansible\inventory

REM Navigate to ansible directory
cd ..\ansible

REM Wait for server to be ready
echo ⏳ Waiting for server to be ready (60 seconds)...
timeout /t 60 >nul

REM Run Ansible provisioning
echo ⚙️ Running Ansible provisioning...
ansible-playbook -i inventory provision.yml

REM Display deployment information
echo.
echo ✅ Deployment completed successfully!
echo.
echo 🌐 Your Goldexperte Pimcore backend is now available
echo 🔐 Don't forget to update DNS records and change default passwords!

pause
