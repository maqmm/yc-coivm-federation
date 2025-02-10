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
      source = "keycloak/keycloak"
      version = ">= 5.0.0"
    }
  }
}

# ===========================
# Call keycloak-config module
# ===========================
module "keycloak-config" {
  source = "../../keycloak-config"
  labels = { tag = "keycloak-config" }

  # =====================
  # Org/Federation values
  # =====================
  org_id = ""
  fed_name = "kc"

  users = jsondecode(file("users.json")) # replace jsondecode to yamldecode for yaml

  # ==================
  # Keycloak VM values
  # ==================
  kc_realm_name  = "kc"
  kc_realm_descr = "My Keycloak Realm"

  kc_fqdn = ""
  kc_port = "8443"
  kc_adm_user = "admin"
  kc_adm_pass = ""
}

output "console-url" {
  value = module.keycloak-config.console-url
}
