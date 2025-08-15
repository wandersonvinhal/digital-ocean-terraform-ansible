terraform {
  cloud {
    organization = "wanderson-org"  # <- sua org

    workspaces {
      name = "digitalocean-infra"   # <- seu workspace
    }
  }

  required_version = ">= 1.5.0"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

resource "digitalocean_droplet" "vm_web" {
  image    = "ubuntu-25-04-x64"
  name     = "${var.vm_name}-${count.index + 1}"
  region   = var.region
  size     = var.size
  ssh_keys = [digitalocean_ssh_key.ssh_key.fingerprint]
  count = var.vms_count
}

resource "local_file" "ansible_inventory" {
  content = templatefile("./ansible/inventory.tmpl",
    { ips = digitalocean_droplet.vm_web[*].ipv4_address }
  )

  filename        = "./ansible/hosts"
  file_permission = "0644"
}

resource "digitalocean_ssh_key" "ssh_key" {
  name       = "terraform-do"
  public_key = file("~/.ssh/terraform-do.pub")
}

resource "digitalocean_firewall" "firewall_terraform_vm" {
  name = "firewall-vms-terraform"

  droplet_ids = digitalocean_droplet.vm_web[*].id

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "53"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "22"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "53"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "80"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "443"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}
