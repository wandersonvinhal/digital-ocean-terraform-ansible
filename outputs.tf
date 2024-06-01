output "vm_ip" {
  value = digitalocean_droplet.vm_web[*].ipv4_address
}