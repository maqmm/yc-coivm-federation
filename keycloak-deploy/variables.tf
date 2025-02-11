# ==================================
# Keycloak-deploy module
# ==================================

# ==================================
# Input variables
# ==================================

variable "cloud_id" {
  description = "Cloud ID"
  type        = string
}

variable "folder_id" {
  description = "Folder ID"
  type        = string
}

variable "labels" {
  description = "A set of key/value label pairs to assign."
  type        = map(string)
  default     = null
}

# ==================================
# VM variables
# ==================================

variable "kc_image_family" {
  description = "Keycloak VM image family"
  type        = string
  default     = null
}

variable "kc_preemptible" {
  description = "Keycloak VM preemptible"
  type        = bool
  default     = false
}

variable "kc_zone_id" {
  description = "Keycloak zone-id for deployment"
  type        = string
  default     = "ru-central1-d"
}

variable "kc_hostname" {
  description = "Keycloak VM name & Hostname & Public DNS name"
  type        = string
  default     = "sso"
}

variable "kc_vm_cores" {
  description = "Keycloak VM cores count"
  type        = number
  default     = 2
}

variable "kc_vm_memory" {
  description = "Keycloak VM memory in GB"
  type        = number
  default     = 2
}

variable "kc_vm_core_fraction" {
  description = "Keycloak VM Core Fraction in %"
  type        = number
  default     = 100
}

variable "kc_vm_username" {
  description = "Keycloak VM username"
  type        = string
  default     = "admin"
}

variable "kc_vm_ssh_pub_file" {
  description = "SSH Public key path and filename"
  type        = string
  default     = null
}

variable "kc_vm_ssh_priv_file" {
  description = "SSH Private key path and filename"
  type        = string
  default     = null
}

# ==================================
# Keycloak variables
# ==================================

variable "kc_ver" {
  description = "Keycloak version for deployment"
  type        = string
  default     = "24.0.0"
}

variable "kc_adm_user" {
  description = "Keycloak admin user name"
  type        = string
  default     = null
}

variable "kc_adm_pass" {
  description = "Keycloak admin user password"
  type        = string
  default     = null
}

output "kc_fqdn" {
  value = local.kc_fqdn
}

# ==================================
# VPC variables
# ==================================

variable "kc_network_name" {
  description = "Keycloak VM network name"
  type        = string
  default     = null
}

variable "kc_subnet_name" {
  description = "Keycloak VM subnet name"
  type        = string
  default     = null
}

variable "kc_subnet_exist" {
  description = "subnet id if it exist in folder"
  type        = string
  default     = null
}

variable "kc_port" {
  description = "Keycloak HTTPS port listener"
  type        = string
  default     = "8443"
}

variable "kc_vm_sg_name" {
  description = "Keycloak VM Security Group name"
  type        = string
  default     = "kc-sg"
}

# ==================================
# DNS zone variables
# ==================================

variable "dns_zone_id" {
  description = "Yandex Cloud DNS Zone ID"
  type        = string
  default     = null
}

variable "dns_zone_name" {
  description = "Yandex Cloud DNS Zone Name"
  type        = string
  default     = null
}

variable "dns_zone_exist" {
  description = "zone id if it exist in folder"
  type        = string
  default     = null
}

# =================================
# LE Certificate variables
# =================================

variable "kc_cert_exist" {
  description = "cloud cert id if it exist in folder"
  type        = string
  default     = null
}

variable "le_cert_name" {
  description = "Let's Encrypt certificate name (CM)"
  type        = string
  default     = null
}

variable "le_cert_descr" {
  description = "Let's Encrypt certificate description (CM)"
  type        = string
  default     = null
}