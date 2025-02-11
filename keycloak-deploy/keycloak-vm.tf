# =====================
# Keycloak VM resources
# =====================

data "yandex_resourcemanager_folder" "kc_folder" {
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
}

# Define a Keycloak VM base image
data "yandex_compute_image" "kc_image" {
  family = var.kc_image_family
}

# Create Keycloak VM
resource "yandex_compute_instance" "kc_vm" {
  folder_id          = data.yandex_resourcemanager_folder.kc_folder.id
  name               = var.kc_hostname
  hostname           = var.kc_hostname
  platform_id        = "standard-v3"
  zone               = var.kc_zone_id

  resources {
    cores  = var.kc_vm_cores
    memory = var.kc_vm_memory
    core_fraction = var.kc_vm_core_fraction
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
    subnet_id  = local.need_vpc ? yandex_vpc_subnet.kc_subnet[0].id : data.yandex_vpc_subnet.kc_subnet_existing[0].id
    nat                = true
    nat_ip_address     = yandex_vpc_address.kc_pub_ip.external_ipv4_address[0].address
    security_group_ids = [yandex_vpc_security_group.kc_sg.id]
  }

  metadata = {
    user-data = templatefile("${abspath(path.module)}/kc-vm-user-data.tpl", {
      username = "${chomp(var.kc_vm_username)}",
      ssh_key  = file("${chomp(var.kc_vm_ssh_pub_file)}")
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
}

resource "null_resource" "copy_certificates" {
  depends_on = [local_file.cert, local_file.key]

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
    private_key = file(var.kc_vm_ssh_priv_file != null ? chomp(var.kc_vm_ssh_priv_file) : replace(var.kc_vm_ssh_pub_file, ".pub", ""))
    host        = yandex_compute_instance.kc_vm.network_interface[0].nat_ip_address
    timeout     = "5m"
  }
}
