# =======================================
# Keycloak-config module. Input variables
# =======================================

variable "labels" {
  description = "A set of key/value label pairs to assign."
  type        = map(string)
  default     = null
}

# ========================
# Org/Federation variables
# ========================
variable "org_id" {
  description = "YC Organization ID"
  type        = string
  default     = null
}

variable "fed_name" {
  description = "YC Federation name"
  type        = string
  default     = null
}

variable "yc_cert" {
  description = "Yandex Cloud SSL certificate"
  type        = string
  default     = "yc-root.crt"
}

variable "users" {
  description = "Users configuration"
  type = object({
    templates = optional(map(object({
      first_name          = optional(string)
      last_name           = optional(string)
      email_domain        = optional(string)
      phone              = optional(string)
      full_name          = optional(string)
      password           = optional(string)
      photo_path        = optional(string)
      temporary_password = optional(bool)
      enabled            = optional(bool)
    })))
    users = map(object({
      template           = optional(string)
      first_name         = optional(string)
      last_name          = optional(string)
      email_domain       = optional(string)
      phone             = optional(string)
      full_name         = optional(string)
      password          = optional(string)
      photo_path        = optional(string)
      temporary_password = optional(bool)
      enabled           = optional(bool)
    }))
  })
}

# =====================
# Keycloak VM variables
# =====================

variable "kc_fqdn" {
  description = "Keycloak public DNS FQDN"
  type        = string
  default     = null
}

variable "kc_port" {
  description = "Keycloak HTTPS port listener"
  type        = string
  default     = null
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

variable "kc_realm_name" {
  description = "Keycloak Realm name"
  type        = string
  default     = null
}

variable "kc_realm_descr" {
  description = "Keycloak Realm description"
  type        = string
  default     = null
}

output "console-url" {
  value = "https://console.yandex.cloud/federations/${yandex_organizationmanager_saml_federation.kc_fed.id}"
}
