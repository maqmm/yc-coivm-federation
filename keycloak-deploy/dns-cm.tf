# ===================================
# DNS & Certificate Manager resources
# ===================================

data "yandex_dns_zone" "kc_dns_zone" {
  folder_id = data.yandex_resourcemanager_folder.kc_folder.id
  dns_zone_id = coalesce(var.dns_zone_id, var.dns_zone_exist) != "" ? coalesce(var.dns_zone_id, var.dns_zone_exist) : null
  name        = coalesce(var.dns_zone_id, var.dns_zone_exist) == "" ? var.dns_zone_name : null
}

locals {
  kc_fqdn = "${var.kc_hostname}.${trimsuffix(data.yandex_dns_zone.kc_dns_zone.zone, ".")}"
}

# create DNS record for Keycloak VM with created public ip address
resource "yandex_dns_recordset" "kc_dns_rec" {
  zone_id = data.yandex_dns_zone.kc_dns_zone.id
  name    = var.kc_hostname
  type    = "A"
  ttl     = 300
  data    = ["${yandex_vpc_address.kc_pub_ip.external_ipv4_address[0].address}"]
}

locals {
  need_cert = var.kc_cert_exist == null || var.kc_cert_exist == ""
}

# take existing certificate
data "yandex_cm_certificate" "cert_existing" {
  count = local.need_cert ? 0 : 1
  certificate_id = var.kc_cert_exist
  folder_id     = data.yandex_resourcemanager_folder.kc_folder.id
}

# create new certificate
resource "yandex_cm_certificate" "kc_le_cert" {
  count     = local.need_cert ? 1 : 0
  folder_id = data.yandex_resourcemanager_folder.kc_folder.id
  name      = var.le_cert_name
  domains   = [local.kc_fqdn]
  managed {
    challenge_type = "DNS_CNAME"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# create domain validation DNS record for Let's Encrypt
resource "yandex_dns_recordset" "validation_dns_rec" {
  count  = local.need_cert ? 1 : 0
  zone_id = data.yandex_dns_zone.kc_dns_zone.id
  name    = yandex_cm_certificate.kc_le_cert[0].challenges[0].dns_name
  type    = yandex_cm_certificate.kc_le_cert[0].challenges[0].dns_type
  data    = [yandex_cm_certificate.kc_le_cert[0].challenges[0].dns_value]
  ttl     = 60

  lifecycle {
    prevent_destroy = true
  }
}

# wait for certificate validation
data "yandex_cm_certificate" "cert_validated" {
  depends_on = [
    yandex_cm_certificate.kc_le_cert,
    yandex_dns_recordset.validation_dns_rec
  ]
  certificate_id = local.need_cert ? yandex_cm_certificate.kc_le_cert[0].id : data.yandex_cm_certificate.cert_existing[0].id
  wait_validation = true
}

# get certificate content
data "yandex_cm_certificate_content" "cert" {
  certificate_id = data.yandex_cm_certificate.cert_validated.id
  wait_validation = true
}

resource "local_file" "cert" {
  content  = join("\n", data.yandex_cm_certificate_content.cert.certificates)
  filename = "${path.root}/cert.pem"
}

resource "local_file" "key" {
  content  = data.yandex_cm_certificate_content.cert.private_key
  filename = "${path.root}/key.pem"
}
