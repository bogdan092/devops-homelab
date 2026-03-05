terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

# Connect to the system-wide KVM hypervisor
provider "libvirt" {
  uri = "qemu:///system"
}

# ==========================================
# Shared Resources
# ==========================================

# 1. Cloud-Init ISO for Node 1
resource "libvirt_cloudinit_disk" "commoninit_01" {
  name      = "commoninit-01.iso"
  pool      = "default"
  user_data = templatefile("${path.module}/cloud_init.cfg", {
    ssh_key = trimspace(file(pathexpand("~/.ssh/id_ed25519.pub")))
  })
}

# 1.1. Cloud-Init ISO for Node 2
resource "libvirt_cloudinit_disk" "commoninit_02" {
  name      = "commoninit-02.iso"
  pool      = "default"
  user_data = templatefile("${path.module}/cloud_init.cfg", {
    ssh_key = trimspace(file(pathexpand("~/.ssh/id_ed25519.pub")))
  })
}
# 2. Base Ubuntu Image (Downloaded once, acts as a read-only template)
resource "libvirt_volume" "ubuntu_base" {
  name   = "ubuntu-base.img"
  pool   = "default"
  source = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
  format = "qcow2"
}

# ==========================================
# Node 01 Configuration
# ==========================================

# 3. Node 1 Hard Drive (Cloned from base, expanded to 20GB)
resource "libvirt_volume" "ubuntu_image" {
  name           = "ubuntu-jammy.qcow2"
  pool           = "default"
  base_volume_id = libvirt_volume.ubuntu_base.id
  size           = 21474836480 # 20GB in bytes
}

# 4. Node 1 Virtual Machine
resource "libvirt_domain" "docker_node" {
  name   = "docker-node-01"
  memory = "2048"
  vcpu   = 2

  cloudinit = libvirt_cloudinit_disk.commoninit_01.id

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.ubuntu_image.id
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }
}

# ==========================================
# Node 02 Configuration
# ==========================================

# 5. Node 2 Hard Drive (Cloned from base, expanded to 20GB)
resource "libvirt_volume" "ubuntu_image_02" {
  name           = "ubuntu-jammy-02.qcow2"
  pool           = "default"
  base_volume_id = libvirt_volume.ubuntu_base.id
  size           = 21474836480 # 20GB in bytes
}

# 6. Node 2 Virtual Machine
resource "libvirt_domain" "docker_node_02" {
  name   = "docker-node-02"
  memory = "2048"
  vcpu   = 2

  cloudinit = libvirt_cloudinit_disk.commoninit_02.id

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.ubuntu_image_02.id
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }
}

# ==========================================
# Outputs
# ==========================================

output "vm_ip" {
  value       = try(libvirt_domain.docker_node.network_interface[0].addresses[0], "IP not assigned yet or VM is off")
  description = "The IP address of the first Docker Node"
}

output "vm_ip_02" {
  value       = try(libvirt_domain.docker_node_02.network_interface[0].addresses[0], "IP not assigned yet or VM is off")
  description = "The IP address of Docker Node 02"
}