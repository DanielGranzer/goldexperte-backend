terraform {
  required_version = ">= 1.0"
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.0.0"
    }
  }
}

# Configure the Hetzner Cloud Provider
provider "hcloud" {
  token = var.hcloud_token
}

# Fetch all existing SSH keys
data "hcloud_ssh_keys" "all" {}

# Create VPC network
resource "hcloud_network" "goldexperte_vpc" {
  name     = "goldexperte-vpc"
  ip_range = "10.0.0.0/16"
  
  labels = {
    project = "goldexperte"
    environment = var.environment
  }
}

# Public subnet for web-facing services
resource "hcloud_network_subnet" "public_subnet" {
  network_id   = hcloud_network.goldexperte_vpc.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.0.1.0/24"
}

# Private subnet for databases and internal services
resource "hcloud_network_subnet" "private_subnet" {
  network_id   = hcloud_network.goldexperte_vpc.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.0.2.0/24"
}

# Volume for Pimcore assets and data persistence
resource "hcloud_volume" "pimcore_data" {
  size              = var.volume_size
  location          = var.server_location
  name              = "goldexperte-pimcore-data"
  format            = "ext4"
  delete_protection = true
  
  labels = {
    project = "goldexperte"
    environment = var.environment
    purpose = "pimcore-data"
  }
  
  lifecycle {
    prevent_destroy = true
  }
}

# Main Pimcore server
resource "hcloud_server" "pimcore_server" {
  depends_on = [hcloud_volume.pimcore_data]
  
  name        = "goldexperte-pimcore-${var.environment}"
  image       = "ubuntu-24.04"
  server_type = var.server_type
  location    = var.server_location
  ssh_keys    = data.hcloud_ssh_keys.all.ssh_keys[*].id
  
  network {
    network_id = hcloud_network.goldexperte_vpc.id
    ip         = "10.0.1.10"
  }
  
  labels = {
    project = "goldexperte"
    environment = var.environment
    role = "pimcore-server"
  }
  
  user_data = templatefile("${path.module}/cloud-init.yml", {
    hostname = "goldexperte-pimcore-${var.environment}"
  })
}

# Attach volume to server
resource "hcloud_volume_attachment" "pimcore_data_attachment" {
  volume_id = hcloud_volume.pimcore_data.id
  server_id = hcloud_server.pimcore_server.id
  automount = true
}

# Firewall for the server
resource "hcloud_firewall" "pimcore_firewall" {
  name = "goldexperte-pimcore-firewall"
  
  labels = {
    project = "goldexperte"
    environment = var.environment
  }
  
  # SSH access
  rule {
    direction = "in"
    port      = "22"
    protocol  = "tcp"
    source_ips = var.allowed_ssh_ips
  }
  
  # HTTP/HTTPS access
  rule {
    direction = "in"
    port      = "80"
    protocol  = "tcp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
  
  rule {
    direction = "in"
    port      = "443"
    protocol  = "tcp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
  
  # Traefik dashboard (restricted)
  rule {
    direction = "in"
    port      = "8080"
    protocol  = "tcp"
    source_ips = var.allowed_admin_ips
  }
}

# Attach firewall to server
resource "hcloud_firewall_attachment" "pimcore_firewall_attachment" {
  firewall_id = hcloud_firewall.pimcore_firewall.id
  server_ids  = [hcloud_server.pimcore_server.id]
}

# Load balancer for high availability (optional)
resource "hcloud_load_balancer" "pimcore_lb" {
  count = var.enable_load_balancer ? 1 : 0
  
  name               = "goldexperte-pimcore-lb"
  load_balancer_type = "lb11"
  location           = var.server_location
  
  labels = {
    project = "goldexperte"
    environment = var.environment
  }
}

# Load balancer network attachment
resource "hcloud_load_balancer_network" "pimcore_lb_network" {
  count = var.enable_load_balancer ? 1 : 0
  
  load_balancer_id = hcloud_load_balancer.pimcore_lb[0].id
  network_id       = hcloud_network.goldexperte_vpc.id
  ip               = "10.0.1.100"
}

# Load balancer target
resource "hcloud_load_balancer_target" "pimcore_lb_target" {
  count = var.enable_load_balancer ? 1 : 0
  
  type             = "server"
  load_balancer_id = hcloud_load_balancer.pimcore_lb[0].id
  server_id        = hcloud_server.pimcore_server.id
}

# Load balancer services
resource "hcloud_load_balancer_service" "pimcore_lb_http" {
  count = var.enable_load_balancer ? 1 : 0
  
  load_balancer_id = hcloud_load_balancer.pimcore_lb[0].id
  protocol         = "http"
  listen_port      = 80
  destination_port = 80
  
  health_check {
    protocol = "http"
    port     = 80
    interval = 15
    timeout  = 10
    retries  = 3
    http {
      path = "/health"
    }
  }
}

resource "hcloud_load_balancer_service" "pimcore_lb_https" {
  count = var.enable_load_balancer ? 1 : 0
  
  load_balancer_id = hcloud_load_balancer.pimcore_lb[0].id
  protocol         = "tcp"
  listen_port      = 443
  destination_port = 443
  
  health_check {
    protocol = "tcp"
    port     = 443
    interval = 15
    timeout  = 10
    retries  = 3
  }
}
