# =====================
# Keycloak VM resources
# =====================

data "yandex_resourcemanager_folder" "kc_folder" {
  cloud_id  = var.cloud_id
  folder_id = var.kc_folder_name
}

# Define a Keycloak VM base image
data "yandex_compute_image" "kc_image" {
  family = var.kc_image_family
}

# Create Service Account (SA) for Keycloak VM
resource "yandex_iam_service_account" "kc_sa" {
  name        = "${var.kc_hostname}-sa"
  folder_id   = data.yandex_resourcemanager_folder.kc_folder.id
  description = "for using on Keycloak's VM"
}

# Grant SA access to download certificates from Certificate Manager (CM)
resource "yandex_resourcemanager_folder_iam_member" "cm_cert_download" {
  folder_id = data.yandex_resourcemanager_folder.kc_folder.id
  role      = "certificate-manager.certificates.downloader"
  member    = "serviceAccount:${yandex_iam_service_account.kc_sa.id}"
}

# Grant SA access to Keycloak's VM metadata
resource "yandex_resourcemanager_folder_iam_member" "rm_viewer" {
  folder_id = data.yandex_resourcemanager_folder.kc_folder.id
  role      = "resource-manager.viewer"
  member    = "serviceAccount:${yandex_iam_service_account.kc_sa.id}"
}

# Grant SA access to Keycloak's VM metadata
resource "yandex_resourcemanager_folder_iam_member" "compute_viewer" {
  folder_id = data.yandex_resourcemanager_folder.kc_folder.id
  role      = "compute.viewer"
  member    = "serviceAccount:${yandex_iam_service_account.kc_sa.id}"
}

# Create Keycloak VM
resource "yandex_compute_instance" "kc_vm" {
  folder_id          = data.yandex_resourcemanager_folder.kc_folder.id
  name               = var.kc_hostname
  hostname           = var.kc_hostname
  platform_id        = "standard-v3"
  zone               = var.kc_zone_id
  service_account_id = yandex_iam_service_account.kc_sa.id

  resources {
    cores  = 2
    memory = 2
    core_fraction = 100
  }

  scheduling_policy {
    preemptible = var.kc_preemptible
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.kc_image.id
      type     = "network-ssd"
      size     = data.yandex_compute_image.kc_image.min_disk_size + 18
    }
  }

  network_interface {
    subnet_id          = var.create_vpc ? (yandex_vpc_subnet.kc_subnet[0].id) : (data.yandex_vpc_subnet.kc_subnet[0].id)
    nat                = true
    nat_ip_address     = yandex_vpc_address.kc_pub_ip.external_ipv4_address[0].address
    security_group_ids = [yandex_vpc_security_group.kc_sg.id]
  }

  metadata = {
    user-data = templatefile("${abspath(path.module)}/kc-vm-user-data.tpl", {
      username = "${chomp(var.kc_vm_username)}",
      ssh_key  = file("${chomp(var.kc_vm_ssh_key_file)}")
    }),
    docker-compose = templatefile("${abspath(path.module)}/kc-vm-docker-compose.tpl", {
      VER = "${chomp(var.kc_ver)}",
      PORT = "${chomp(var.kc_port)}",
      KC_USER = "${chomp(var.kc_adm_user)}",
      KC_PASS = "${chomp(var.kc_adm_pass)}",
      VM_USER = "${chomp(var.kc_vm_username)}",
      KC_FQDN = "${chomp(local.kc_fqdn)}",
    }),
  }

  provisioner "file" {
    source      = "${path.root}/cert.pem"
    destination = "/home/${var.kc_vm_username}/cert.pem"
  }

  provisioner "file" {
    source      = "${path.root}/key.pem"
    destination = "/home/${var.kc_vm_username}/key.pem"
  }

  connection {
    type        = "ssh"
    user        = var.kc_vm_username
    private_key = file("~/.ssh/id_rsa")
    host        = yandex_vpc_address.kc_pub_ip.external_ipv4_address[0].address
  }

}
