terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.7.6"
    }
  }
}

# Configure the libvirt provider to connect to your local machine
provider "libvirt" {
  uri = "qemu:///system"
}

# 1. Fetch the official Ubuntu 22.04 Cloud Image from the internet
resource "libvirt_volume" "ubuntu_image" {
  name   = "ubuntu-jammy.qcow2"
  pool   = "default" # This is KVM's default storage area
  source = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
  format = "qcow2"
}

# 2. Create the Cloud-Init disk using our config file
resource "libvirt_cloudinit_disk" "commoninit" {
  name      = "commoninit.iso"
  pool      = "default"
  user_data = templatefile("${path.module}/cloud_init.cfg", {
    # This reads your public key from your Ubuntu machine and passes it to the config
    ssh_key = file("~/.ssh/id_ed25519.pub")
  })
}

# 3. Define the Virtual Machine itself
resource "libvirt_domain" "docker_node" {
  name   = "docker-node-01"
  memory = "2048" # 2GB RAM
  vcpu   = 2      # 2 CPU Cores

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  # Connect to KVM's default virtual network
  network_interface {
    network_name   = "default"
    wait_for_lease = true # Wait until the VM gets an IP address
  }

  # Attach the Ubuntu hard drive we downloaded
  disk {
    volume_id = libvirt_volume.ubuntu_image.id
  }

  # Setup a virtual console
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }
}

# 4. Output the IP Address so we know how to connect to it!
output "vm_ip" {
  value       = try(libvirt_domain.docker_node.network_interface[0].addresses[0], "IP not assigned yet or VM is off")
  description = "The IP address of the first Docker Node"
}

# ==========================================
# node-02 configuration
# ==========================================

# 1. Create a separate hard drive for the second VM
resource "libvirt_volume" "ubuntu_image_02" {
  name   = "ubuntu-jammy-02.qcow2"
  pool   = "default"
  source = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
  format = "qcow2"
}

# 2. Define the second Virtual Machine
resource "libvirt_domain" "docker_node_02" {
  name   = "docker-node-02"
  memory = "2048"
  vcpu   = 2

  # We reuse the exact same Cloud-Init ISO from the first node!
  cloudinit = libvirt_cloudinit_disk.commoninit.id

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

# 3. Output the IP Address for node 2
output "vm_ip_02" {
  value       = try(libvirt_domain.docker_node_02.network_interface[0].addresses[0], "IP not assigned yet or VM is off")
  description = "The IP address of Docker Node 02"
}