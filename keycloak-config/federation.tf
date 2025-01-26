# ========================================================
# YC Federation resource
# Import Keycloak resources into Federation & Organization
# ========================================================

# Create YC Federation
resource "yandex_organizationmanager_saml_federation" "kc_fed" {
  name                         = var.fed_name
  organization_id              = var.org_id
  issuer                       = "https://${var.kc_fqdn}:${var.kc_port}/realms/${var.kc_realm_name}"
  sso_url                      = "https://${var.kc_fqdn}:${var.kc_port}/realms/${var.kc_realm_name}/protocol/saml"
  sso_binding                  = "POST"
  auto_create_account_on_login = true
  security_settings {
    encrypted_assertions = false
  }
}

data "yandex_client_config" "client" {}

resource "null_resource" "federation_cert" {
  provisioner "local-exec" {
    command = <<-EOT
      CERT=$(curl -s https://${var.kc_fqdn}:${var.kc_port}/realms/${var.kc_realm_name}/protocol/saml/descriptor | \
      sed -n 's/.*<ds:X509Certificate>\(.*\)<\/ds:X509Certificate>.*/\1/p')

      curl \
        --fail \
        --silent \
        --show-error \
        --request POST \
        --url "https://organization-manager.api.cloud.yandex.net/organization-manager/v1/saml/certificates" \
        --header "Content-Type: application/json" \
        --header "Authorization: Bearer ${data.yandex_client_config.client.iam_token}" \
        --data @- <<EOF
{
  "federationId": "${yandex_organizationmanager_saml_federation.kc_fed.id}",
  "name": "${var.fed_name}",
  "description": "Keycloak SAML Federation Certificate",
  "data": "-----BEGIN CERTIFICATE-----\n$CERT\n-----END CERTIFICATE-----"
}
EOF
    EOT
  }

  depends_on = [
    keycloak_realm.realm,
    yandex_organizationmanager_saml_federation.kc_fed
  ]
}

# Import Test user account to YC Organization from Keycloak
resource "yandex_organizationmanager_saml_federation_user_account" "kc_test_user" {
  federation_id = yandex_organizationmanager_saml_federation.kc_fed.id
  name_id       = var.kc_user.name

  depends_on = [
    null_resource.federation_cert
  ]
}