# ================================
# Keycloak configuration resources 
# ================================

provider "keycloak" {
  client_id = "admin-cli"
  username  = var.kc_adm_user
  password  = var.kc_adm_pass
  url       = "https://${var.kc_fqdn}:${var.kc_port}"
  client_timeout = 600
}

resource "keycloak_realm" "realm" {
  realm                          = var.kc_realm_name
  enabled                        = true
  display_name                   = var.kc_realm_descr
  display_name_html              = "<b>${var.kc_realm_descr}</b>"
  ssl_required                   = "external"
  registration_allowed           = false
  registration_email_as_username = false
  remember_me                    = false
  verify_email                   = false
  reset_password_allowed         = false
  login_with_email_allowed       = false

  internationalization {
    supported_locales = ["en"]
    default_locale    = "en"
  }

  security_defenses {
    headers {
      x_frame_options                     = "DENY"
      content_security_policy             = "frame-src 'self'; frame-ancestors 'self'; object-src 'none';"
      content_security_policy_report_only = ""
      x_content_type_options              = "nosniff"
      x_robots_tag                        = "none"
      x_xss_protection                    = "1; mode=block"
      strict_transport_security           = "max-age=31536000; includeSubDomains"
    }
    brute_force_detection {
      permanent_lockout                = false
      max_login_failures               = 10
      wait_increment_seconds           = 60
      quick_login_check_milli_seconds  = 1000
      minimum_quick_login_wait_seconds = 60
      max_failure_wait_seconds         = 900
      failure_reset_time_seconds       = 43200
    }
  }
}

locals {
  url_prefix = "https://auth.yandex.cloud"
}

resource "keycloak_saml_client" "client" {
  realm_id = keycloak_realm.realm.id
  name     = "${var.fed_name}-federation"
  enabled  = true

  client_id                     = "${local.url_prefix}/federations/${yandex_organizationmanager_saml_federation.kc_fed.id}"
  base_url                      = "${local.url_prefix}/federations/${yandex_organizationmanager_saml_federation.kc_fed.id}"
  valid_redirect_uris           = ["${local.url_prefix}/federations/${yandex_organizationmanager_saml_federation.kc_fed.id}"]
  idp_initiated_sso_relay_state = "${local.url_prefix}/federations/${yandex_organizationmanager_saml_federation.kc_fed.id}"

  assertion_consumer_redirect_url = local.url_prefix

  sign_documents          = false
  sign_assertions         = true
  include_authn_statement = true
  name_id_format          = "username"
  force_name_id_format    = false
  signature_algorithm     = "RSA_SHA256"
  signature_key_name      = "CERT_SUBJECT"
  full_scope_allowed      = true

  force_post_binding        = true
  client_signature_required = false
  encrypt_assertions        = false
}


resource "keycloak_realm_user_profile" "user_profile" {
  realm_id = keycloak_realm.realm.id
  unmanaged_attribute_policy = "ENABLED"

  attribute {
    name         = "username"
    display_name = "$${username}"
    group        = "user-metadata"
    multi_valued = false

    permissions {
      view = ["admin", "user"]
      edit = ["admin", "user"]
    }

    validator {
      name = "length"
      config = {
        min = "3"
        max = "63"
      }
    }

    validator {
      name = "username-prohibited-characters"
    }

    validator {
      name = "up-username-not-idn-homograph"
    }
  }

  attribute {
    name         = "email"
    display_name = "$${email}"
    group        = "user-metadata"
    multi_valued = false
    required_for_roles = ["user"]

    permissions {
      view = ["admin", "user"]
      edit = ["admin", "user"]
    }

    validator {
      name = "email"
    }

    validator {
      name = "length"
      config = {
        max = "255"
      }
    }
  }

  attribute {
    name         = "firstName"
    display_name = "$${firstName}"
    group        = "user-metadata"
    multi_valued = false

    permissions {
      view = ["admin", "user"]
      edit = ["admin", "user"]
    }

    validator {
      name = "length"
      config = {
        max = "63"
      }
    }

    validator {
      name = "person-name-prohibited-characters"
    }
  }

  attribute {
    name         = "lastName"
    display_name = "$${lastName}"
    group        = "user-metadata"
    multi_valued = false

    permissions {
      view = ["admin", "user"]
      edit = ["admin", "user"]
    }

    validator {
      name = "length"
      config = {
        max = "63"
      }
    }

    validator {
      name = "person-name-prohibited-characters"
    }
  }
  attribute {
    name         = "name"
    display_name = "Full Name"
    group        = "user-metadata"
    multi_valued = false

    permissions {
      view = ["admin", "user"]
      edit = ["admin", "user"]
    }

    validator {
      name = "length"
      config = {
        max = "64"
      }
    }

    validator {
      name = "person-name-prohibited-characters"
    }
  }

  attribute {
    name         = "phone"
    display_name = "Phone Number"
    group        = "user-metadata"
    multi_valued = false

    permissions {
      view = ["admin", "user"]
      edit = ["admin", "user"]
    }

    validator {
      name = "length"
      config = {
        max = "64"
      }
    }

    validator {
      name = "pattern"
      config = {
        pattern = "^\\+[0-9]{11}$"
        error-message = "Phone number must be in format: +71234567890"
      }
    }
  }

  attribute {
    name         = "thumbnailPhoto"
    display_name = "Avatar"
    group        = "user-metadata"
    multi_valued = false

    permissions {
      view = ["admin", "user"]
      edit = ["admin", "user"]
    }

    validator {
      name = "length"
      config = {
        max = "204800"
      }
    }

    validator {
      name = "pattern"
      config = {
        pattern = "^[A-Za-z0-9+/]*={0,2}$"
        error-message = "Avatar must be in Base64 format"
      }
    }
  }

  attribute {
    name         = "member"
    display_name = "Group Membership"
    group        = "user-metadata"
    multi_valued = true

    permissions {
      view = ["admin", "user"]
      edit = ["admin"]
    }

    validator {
      name = "length"
      config = {
        max = "255"
      }
    }
  }

  group {
    name                = "user-metadata"
    display_header      = "User metadata"
    display_description = "Attributes, which refer to user metadata"
  }
}

resource "keycloak_generic_protocol_mapper" "role_list_mapper" {
  realm_id        = keycloak_realm.realm.id
  client_id       = keycloak_saml_client.client.id
  name            = "role list"
  protocol        = "saml"
  protocol_mapper = "saml-role-list-mapper"
  config = {
    "attribute.name"       = "Role"
    "attribute.nameformat" = "Basic"
    "single"               = "true"
  }
}

resource "keycloak_generic_protocol_mapper" "group_membership" {
  realm_id        = keycloak_realm.realm.id
  client_id       = keycloak_saml_client.client.id
  name            = "Group Membership"
  protocol        = "saml"
  protocol_mapper = "saml-group-membership-mapper"
  config = {
    "attribute.name"       = "member"
    "attribute.nameformat" = "Basic"
    "single"              = "false"
    "full.path"           = "true"
  }
}

resource "keycloak_saml_user_property_protocol_mapper" "property_email" {
  realm_id                   = keycloak_realm.realm.id
  client_id                  = keycloak_saml_client.client.id
  name                       = "X500 email"
  user_property              = "email"
  friendly_name              = "email"
  saml_attribute_name        = "email"
  saml_attribute_name_format = "Basic"
}

resource "keycloak_saml_user_property_protocol_mapper" "property_givenname" {
  realm_id                   = keycloak_realm.realm.id
  client_id                  = keycloak_saml_client.client.id
  name                       = "X500 givenName"
  user_property              = "firstName"
  friendly_name              = "firstName"
  saml_attribute_name        = "firstName"
  saml_attribute_name_format = "Basic"
}

resource "keycloak_saml_user_property_protocol_mapper" "property_surname" {
  realm_id                   = keycloak_realm.realm.id
  client_id                  = keycloak_saml_client.client.id
  name                       = "X500 surname"
  user_property              = "lastName"
  friendly_name              = "lastName"
  saml_attribute_name        = "lastName"
  saml_attribute_name_format = "Basic"
}

resource "keycloak_saml_user_attribute_protocol_mapper" "attribute_fullname" {
  realm_id                   = keycloak_realm.realm.id
  client_id                  = keycloak_saml_client.client.id
  name                       = "Full Name"
  user_attribute             = "name"
  friendly_name              = "name"
  saml_attribute_name        = "name"
  saml_attribute_name_format = "Basic"
}

resource "keycloak_saml_user_attribute_protocol_mapper" "attribute_phone" {
  realm_id                   = keycloak_realm.realm.id
  client_id                  = keycloak_saml_client.client.id
  name                       = "Phone"
  user_attribute             = "phone"
  friendly_name              = "phone"
  saml_attribute_name        = "phone"
  saml_attribute_name_format = "Basic"
}

resource "keycloak_saml_user_attribute_protocol_mapper" "attribute_avatar" {
  realm_id                   = keycloak_realm.realm.id
  client_id                  = keycloak_saml_client.client.id
  name                       = "Avatar"
  user_attribute             = "thumbnailPhoto"
  friendly_name              = "thumbnailPhoto"
  saml_attribute_name        = "thumbnailPhoto"
  saml_attribute_name_format = "Basic"
}

resource "random_password" "user_password" {
  for_each = var.users.users

  length           = 16
  special          = false
  min_lower       = 1
  min_upper       = 1
  min_numeric     = 1
}

resource "keycloak_user" "users" {
  for_each = var.users.users

  realm_id    = keycloak_realm.realm.id
  username    = each.key
  enabled     = try(coalesce(
    try(each.value.enabled, null),
    try(var.users.templates[each.value.template].enabled, null),
    try(var.users.templates[""].enabled, null)),
    true)
  first_name  = try(coalesce(
    try(each.value.first_name, null),
    try(var.users.templates[each.value.template].first_name, null),
    try(var.users.templates[""].first_name, null)),
    null)
  last_name   = try(coalesce(
    try(each.value.last_name, null),
    try(var.users.templates[each.value.template].last_name, null),
    try(var.users.templates[""].last_name, null)),
    null)
  email       = try(coalesce(
    try("${each.key}@${each.value.email_domain}", null),
    try("${each.key}@${var.users.templates[each.value.template].email_domain}", null),
    try("${each.key}@${var.users.templates[""].email_domain}", null),
    try("${each.key}@${replace(var.kc_fqdn, "/^[^.]+\\./", "")}", null)),
    null)

  attributes = {
    "phone"    = try(coalesce(
      try(each.value.phone, null),
      try(var.users.templates[each.value.template].phone, null),
      try(var.users.templates[""].phone, null)),
      null)
    "name"     = try(coalesce(
      try(each.value.full_name, null),
      try(var.users.templates[each.value.template].full_name, null),
      try(var.users.templates[""].full_name, null)),
      null)
    "thumbnailPhoto" = try(coalesce(
      try(filebase64(each.value.photo_path), null),
      try(filebase64(var.users.templates[each.value.template].photo_path), null),
      try(filebase64(var.users.templates[""].photo_path), null)),
      null)
  }

  initial_password {
    value     = coalesce(
      try(each.value.password, null),
      try(var.users.templates[each.value.template].password, null),
      try(var.users.templates[""].password, null),
      random_password.user_password[each.key].result
    )
    temporary = try(coalesce(
      try(each.value.temporary_password, null),
      try(var.users.templates[each.value.template].temporary_password, null),
      try(var.users.templates[""].temporary_password, null)),
      false)
  }

  depends_on = [
    keycloak_realm_user_profile.user_profile,
    random_password.user_password
  ]
}

/*output "generated_passwords" {
  value     = { for k, v in random_password.user_password : k => v.result }
  sensitive = true
}
*/