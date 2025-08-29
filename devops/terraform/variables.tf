# Hetzner Cloud Configuration
variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

# Server Configuration
variable "server_type" {
  description = "Hetzner Cloud server type"
  type        = string
  default     = "cx31"  # 2 vCPUs, 8GB RAM, 80GB SSD
}

variable "server_location" {
  description = "Hetzner Cloud server location"
  type        = string
  default     = "nbg1"  # Nuremberg
}

variable "volume_size" {
  description = "Size of the data volume in GB"
  type        = number
  default     = 100
}

# Environment Configuration
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

# Network Security
variable "allowed_ssh_ips" {
  description = "List of IP addresses allowed to SSH to the server"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Change this to your specific IPs!
}

variable "allowed_admin_ips" {
  description = "List of IP addresses allowed to access admin interfaces"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Change this to your specific IPs!
}

# Load Balancer
variable "enable_load_balancer" {
  description = "Enable load balancer for high availability"
  type        = bool
  default     = false
}

# Domain Configuration
variable "main_domain" {
  description = "Main domain for the application"
  type        = string
  default     = "diegoldexperten.com"
}

variable "admin_domain" {
  description = "Admin domain for Pimcore admin panel"
  type        = string
  default     = "admin.diegoldexperten.com"
}

variable "api_domain" {
  description = "API domain for headless endpoints"
  type        = string
  default     = "api.diegoldexperten.com"
}

# SSL Configuration
variable "acme_email" {
  description = "Email for Let's Encrypt certificate registration"
  type        = string
  default     = "admin@diegoldexperten.com"
}
