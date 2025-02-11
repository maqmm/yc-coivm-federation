# ==================================
# Terraform & Provider configuration
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
      source  = "keycloak/keycloak"
      version = ">= 5.0.0"
    }
  }
}

# ==================================
# Call keycloak-config module
# ==================================
module "keycloak-config" {
  source           = "../../keycloak-config"

  # ================================
  # Input variables
  # ================================
  labels           = { tag = "keycloak-config" }

  # ================================
  # Organization variables
  # ================================
  org_id           = ""
  fed_name         = "kc"

  # ================================
  # Keycloak variables
  # ================================
  kc_fqdn          = ""
  kc_port          = ""

  kc_adm_user      = ""
  kc_adm_pass      = ""

  kc_realm_name    = "kc"
  kc_realm_descr   = "My Keycloak Realm"

  # ================================
  # Users configuration
  # ================================
  users            = jsondecode(file("users.json")) # replace jsondecode to yamldecode for yaml

}

output "console-url" {
  value = module.keycloak-config.console-url
}
