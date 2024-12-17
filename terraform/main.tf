terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.28"  # Use the latest compatible version
    }
  }
}

provider "digitalocean" {
  token = var.digitalocean_token
}


variable "digitalocean_token" {
  description = "The DigitalOcean API token."
  type        = string
}

variable "region" {
  description = "Region to deploy droplets (e.g., nyc1)"
  type        = string
  default     = "nyc1"
}

variable "size" {
  description = "Droplet size (e.g., s-1vcpu-1gb)"
  type        = string
  default     = "s-1vcpu-1gb"
}

variable "image" {
  description = "Droplet image (e.g., ubuntu-22-04-x64)"
  type        = string
  default     = "ubuntu-22-04-x64"
}

variable "droplet_count" {
  description = "Number of droplets to create"
  type        = number
  default     = 1
}

variable "ssh_keys" {
  description = "List of SSH key IDs for access"
  type        = list(string)
  default     = []
}

data "external" "env_variables" {
  program = ["./read_env.sh"]
}

# Extract variables from the external data source
locals {
  vps_root_password = data.external.env_variables.result["vps_root_password"]
  jenkins_admin_password = data.external.env_variables.result["jenkins_admin_password"]
  jenkins_url = data.external.env_variables.result["jenkins_url"]
  registry_username = data.external.env_variables.result["registry_username"]
  registry_token = data.external.env_variables.result["registry_token"]
}

# Use the variables in the YAML template
resource "local_file" "ansible_all_yml" {
  filename = "../ansible/group_vars/all.yml"
  content  = <<-EOT
    vps_ip: "${digitalocean_droplet.web[0].ipv4_address}"
    vps_root_password: "${local.vps_root_password}"
    jenkins_admin_password: "${local.jenkins_admin_password}"
    jenkins_url: "${local.jenkins_url}"
    registry_username: "${local.registry_username}"
    registry_token: "${local.registry_token}"
  EOT
}

resource "digitalocean_droplet" "web" {
  count  = var.droplet_count  # Number of droplets to create
  name   = "whanos-vps-${count.index + 1}"  # Unique droplet names
  region = var.region         # Specify the region (e.g., nyc1, sfo3)
  size   = var.size           # Droplet size (e.g., s-1vcpu-1gb)
  image  = var.image          # Base image (e.g., ubuntu-22-04-x64)
  ssh_keys = var.ssh_keys

  tags = ["web", "terraform"] # Tags for the droplets
}

resource "digitalocean_kubernetes_cluster" "my_k8s_cluster" {
  name   = "example-cluster"
  region = "nyc1"  # Change to your preferred region
  version = "1.31.1-do.5"  # Use a specific Kubernetes version available in DigitalOcean

  node_pool {
    name       = "default-pool"
    size       = "s-2vcpu-4gb"  # Choose your preferred droplet size
    node_count = 3  # Number of nodes in the pool
  }
}

output "kubeconfig" {
  value = digitalocean_kubernetes_cluster.my_k8s_cluster.kube_config[0].raw_config
  sensitive = true
}

output "jenkins_droplet_ip" {
  value = digitalocean_droplet.web[0].ipv4_address
  description = "The IP address of the Jenkins droplet."
}