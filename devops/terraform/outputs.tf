# Server Information
output "server_ipv4" {
  description = "IPv4 address of the Pimcore server"
  value       = hcloud_server.pimcore_server.ipv4_address
}

output "server_ipv6" {
  description = "IPv6 address of the Pimcore server"
  value       = hcloud_server.pimcore_server.ipv6_address
}

output "server_id" {
  description = "ID of the Pimcore server"
  value       = hcloud_server.pimcore_server.id
}

output "server_name" {
  description = "Name of the Pimcore server"
  value       = hcloud_server.pimcore_server.name
}

# Network Information
output "vpc_id" {
  description = "ID of the VPC network"
  value       = hcloud_network.goldexperte_vpc.id
}

output "vpc_ip_range" {
  description = "IP range of the VPC network"
  value       = hcloud_network.goldexperte_vpc.ip_range
}

# Volume Information
output "volume_id" {
  description = "ID of the data volume"
  value       = hcloud_volume.pimcore_data.id
}

output "volume_device" {
  description = "Device path of the attached volume"
  value       = "/dev/sdb"  # Standard device for attached volumes
}

# Load Balancer Information (if enabled)
output "load_balancer_ipv4" {
  description = "IPv4 address of the load balancer"
  value       = var.enable_load_balancer ? hcloud_load_balancer.pimcore_lb[0].ipv4 : null
}

output "load_balancer_ipv6" {
  description = "IPv6 address of the load balancer"
  value       = var.enable_load_balancer ? hcloud_load_balancer.pimcore_lb[0].ipv6 : null
}

# DNS Configuration Instructions
output "dns_configuration" {
  description = "DNS configuration instructions"
  value = <<-EOT
    Configure the following DNS records:
    
    Main Domain:
    ${var.main_domain}        A    ${hcloud_server.pimcore_server.ipv4_address}
    ${var.main_domain}        AAAA ${hcloud_server.pimcore_server.ipv6_address}
    
    Admin Panel:
    ${var.admin_domain}       A    ${hcloud_server.pimcore_server.ipv4_address}
    ${var.admin_domain}       AAAA ${hcloud_server.pimcore_server.ipv6_address}
    
    API Endpoint:
    ${var.api_domain}         A    ${hcloud_server.pimcore_server.ipv4_address}
    ${var.api_domain}         AAAA ${hcloud_server.pimcore_server.ipv6_address}
    
    Optional subdomains:
    mailhog.${var.main_domain}  A    ${hcloud_server.pimcore_server.ipv4_address}
    traefik.${var.main_domain}  A    ${hcloud_server.pimcore_server.ipv4_address}
  EOT
}

# Ansible Inventory
output "ansible_inventory" {
  description = "Ansible inventory configuration"
  value = <<-EOT
    [pimcore_servers]
    ${hcloud_server.pimcore_server.name} ansible_host=${hcloud_server.pimcore_server.ipv4_address} ansible_user=root
    
    [pimcore_servers:vars]
    server_id=${hcloud_server.pimcore_server.id}
    volume_device=/dev/sdb
    main_domain=${var.main_domain}
    admin_domain=${var.admin_domain}
    api_domain=${var.api_domain}
    acme_email=${var.acme_email}
    environment=${var.environment}
  EOT
}
