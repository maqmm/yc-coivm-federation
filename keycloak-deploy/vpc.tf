# =============
# VPC resources
# =============

locals {
  need_vpc = var.kc_subnet_exist == null || var.kc_subnet_exist == ""
}

# Создание новой сети, если не существует
resource "yandex_vpc_network" "kc_net" {
  count     = local.need_vpc ? 1 : 0
  folder_id = data.yandex_resourcemanager_folder.kc_folder.id
  name      = var.kc_network_name
}

# Создание новой подсети, если не существует
resource "yandex_vpc_subnet" "kc_subnet" {
  count     = local.need_vpc ? 1 : 0
  folder_id      = data.yandex_resourcemanager_folder.kc_folder.id
  v4_cidr_blocks = ["10.10.10.0/24"]
  name           = var.kc_subnet_name
  network_id     = yandex_vpc_network.kc_net[0].id
  zone           = var.kc_zone_id
}

# Попытка получить существующую подсеть
data "yandex_vpc_subnet" "kc_subnet_existing" {
  count = local.need_vpc ? 0 : 1
  folder_id = data.yandex_resourcemanager_folder.kc_folder.id
  subnet_id = var.kc_subnet_exist
}

# Create public ip address for Keycloak VM
resource "yandex_vpc_address" "kc_pub_ip" {
  folder_id = data.yandex_resourcemanager_folder.kc_folder.id
  name      = var.kc_hostname
  external_ipv4_address {
    zone_id = var.kc_zone_id
  }
}

# Create Security Group for Keycloak VM
resource "yandex_vpc_security_group" "kc_sg" {
  name       = var.kc_vm_sg_name
  folder_id  = data.yandex_resourcemanager_folder.kc_folder.id
  network_id = local.need_vpc ? yandex_vpc_network.kc_net[0].id : data.yandex_vpc_subnet.kc_subnet_existing[0].network_id

  egress {
    description    = "Permit ALL" 
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "icmp"
    protocol       = "ICMP"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "ssh"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "https"
    protocol       = "TCP"
    port           = var.kc_port
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
