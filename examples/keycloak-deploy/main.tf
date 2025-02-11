# ==================================
# Terraform & Provider Configuration
# ==================================
terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.119.0"
    }
  }
}

# ===========================
# Call keycloak-deploy module
# ===========================
module "keycloak-deploy" {
  source   = "../../keycloak-deploy"
  cloud_id = var.YC_CLOUD_ID
  folder_id  = var.YC_FOLDER_ID
  labels   = { tag = "keycloak-deploy" }

  # ==================
  # Keycloak VM values
  # ==================
  kc_image_family = "container-optimized-image"

  kc_zone_id      = "ru-central1-d"
  kc_network_name = "forkc"
  kc_subnet_name  = "forkc-ru-central1-d"
  kc_preemptible  = true

  kc_vm_sg_name       = "kc-sg"
  kc_vm_username      = "admin"
  kc_vm_ssh_pub_file  = "~/.ssh/id_rsa.pub"

  dns_zone_id   = coalesce("", var.YC_ZONE_ID)  #ONE OF NAME OR ID ARE IMPORTANT
  dns_zone_name = ""                            #ONE OF NAME OR ID ARE IMPORTANT
  kc_hostname   = "fed"

  kc_ver      = "26.1.1"
  kc_port     = "8443"
  kc_adm_user = "admin"
  kc_adm_pass = "" #RUN source ../env-yc.sh FOR FIRST RANDOM GENERATION, VALUE IN BOTH MAIN.TF MUST BE EMPTY

  # ===================
  # Certificates values
  # ===================
  kc_cert_exist        = var.CERTIFICATE_ID
  le_cert_name      = "kc"
}

output "kc_fqdn" {
  value = module.keycloak-deploy.kc_fqdn
}