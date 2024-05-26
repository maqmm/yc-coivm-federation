# ==================================
# Terraform & Provider Configuration
# ==================================

terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.119.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.2"
    }
    keycloak = {
      source  = "mrparkers/keycloak"
      version = "~> 4.4.0"
    }
  }
}
