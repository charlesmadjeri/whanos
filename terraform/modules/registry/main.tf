terraform {
  required_version = ">= 1.5.0"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.34"
    }
  }
}

variable "name" {
  type        = string
  description = "Registry name (lowercase alphanumeric)"
}

variable "region" {
  type    = string
  default = "fra1"
}

variable "subscription_tier" {
  type    = string
  default = "starter"
}

resource "digitalocean_container_registry" "this" {
  name                   = var.name
  subscription_tier_slug = var.subscription_tier
  region                 = var.region
}

output "name" {
  value = digitalocean_container_registry.this.name
}

output "endpoint" {
  value = digitalocean_container_registry.this.endpoint
}

output "server_url" {
  value = digitalocean_container_registry.this.server_url
}
