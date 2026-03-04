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
  value       = libvirt_domain.docker_node.network_interface[0].addresses[0]
  description = "The IP address of the Docker Node"
}
