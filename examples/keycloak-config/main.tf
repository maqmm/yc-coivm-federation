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

# ===========================
# Call keycloak-config module
# ===========================
module "keycloak-config" {
  source = "../../keycloak-config"
  labels = { tag = "keycloak-config" }

  # =====================
  # Org/Federation values
  # =====================
  org_id   = "bpfqdgu3d2815fyixlks"
  fed_name = "kc-fed"

  kc_user = {
    name   = "kc-user1"
    pass   = "Gu95-paSw38"
    domain = "mydom.net"
  }

  # ==================
  # Keycloak VM values
  # ==================
  kc_realm_name  = "kc1"
  kc_realm_descr = "My Keycloak Realm"

  kc_fqdn     = "kc1.mydom.net"
  kc_port     = "8443"
  kc_adm_user = "admin"
  kc_adm_pass = "Fr#dR3n48Ga-Mov"
}

output "console-url" {
  value = module.keycloak-config.console-url
}
