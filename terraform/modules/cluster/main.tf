terraform {
  required_version = ">= 1.5.0"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.34"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

variable "name" {
  type = string
}

variable "region" {
  type    = string
  default = "fra1"
}

variable "node_size" {
  type    = string
  default = "s-2vcpu-4gb"
}

variable "node_count" {
  type        = number
  description = "Prod must be >= 2 for the Whanos subject."
  default     = 2

  validation {
    condition     = var.node_count >= 1
    error_message = "node_count must be at least 1."
  }
}

variable "kubernetes_version" {
  type        = string
  default     = ""
  description = "Empty = DigitalOcean default latest slug."
}

variable "auto_upgrade" {
  type        = bool
  default     = false
  description = "Patch upgrades. Off for lab (avoids surprise node churn)."
}

variable "surge_upgrade" {
  type        = bool
  default     = false
  description = "During upgrades, DO may add a temporary extra node (billed). Keep false for lab."
}

variable "ha" {
  type        = bool
  default     = false
  description = "HA control plane (3 CP nodes). Much slower to provision and costs extra; leave false for lab."
}

variable "kubeconfig_path" {
  type        = string
  description = "Where to write kubeconfig (repo-root kubeconfig.yaml)."
}

data "digitalocean_kubernetes_versions" "available" {
  count = var.kubernetes_version == "" ? 1 : 0
}

locals {
  k8s_version = var.kubernetes_version != "" ? var.kubernetes_version : data.digitalocean_kubernetes_versions.available[0].latest_version
}

resource "digitalocean_kubernetes_cluster" "this" {
  name          = var.name
  region        = var.region
  version       = local.k8s_version
  auto_upgrade  = var.auto_upgrade
  surge_upgrade = var.surge_upgrade
  # Provider/API may default HA on; pin explicitly. HA often 15–30+ min vs ~5 min basic.
  ha            = var.ha

  node_pool {
    name       = "${var.name}-default-pool"
    size       = var.node_size
    node_count = var.node_count
  }
}

resource "local_sensitive_file" "kubeconfig" {
  content              = digitalocean_kubernetes_cluster.this.kube_config[0].raw_config
  filename             = var.kubeconfig_path
  file_permission      = "0600"
  directory_permission = "0700"
}

output "id" {
  value = digitalocean_kubernetes_cluster.this.id
}

output "endpoint" {
  value = digitalocean_kubernetes_cluster.this.endpoint
}

output "kubeconfig_path" {
  value = local_sensitive_file.kubeconfig.filename
}

output "node_count" {
  value = var.node_count
}
