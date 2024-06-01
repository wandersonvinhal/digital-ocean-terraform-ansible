variable "do_token" {
  type        = string
  description = "Token da API da Digital Ocean"
}

variable "vm_name" {
  default     = "vm-web"
  type        = string
  description = "Nome inicial das VMs"
}

variable "region" {
  default     = "nyc1"
  type        = string
  description = "Região da VM"
}

variable "size" {

  default     = "s-1vcpu-1gb"
  type        = string
  description = "Perfil das VMs"
}

variable "ssh_key" {
  default     = "terraform-do"
  type        = string
  description = "Chave SHH de conexão"
}

variable "vms_count" {
  default     = 1
  type        = number
  description = "Qtd de VMs"
}