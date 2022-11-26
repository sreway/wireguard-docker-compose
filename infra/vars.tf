variable "sel_user_name" {
  type        = string
  description = "Name of user for access to Selectel VPC project"
}

variable "sel_user_password" {
  type        = string
  description = "Password of user for access to Selectel VPC project"
}

variable "sel_api_key" {
  type        = string
  description = "Selectel API key. Can be create: https://my.selectel.ru/profile/apikeys"
}

variable "sel_project_name" {
  type        = string
  default     = "sreway"
  description = "Selectel VPC project name"
}

variable "sel_project_id" {
  type        = string
  description = "Selectel VPC project ID"
}

variable "sel_account_id" {
  type        = string
  description = "Selectel account id. (contract number)"
}

variable "sel_auth_url" {
  type        = string
  default     = "https://api.selvpc.ru/identity/v3"
  description = "Auth url of Selectel VPC API."
}

variable "sel_region_name" {
  type        = string
  default     = "ru-7"
  description = "Name of region for Selectel VPC resources"
}

variable "sel_ssh_key_name" {
  type        = string
  default     = "ci"
  description = "The name of the SSH key pair to put on the compute instance. The key pair must already be created in some region and associated with Selectel vpc project"
}

variable "networks" {
  type = map(object({
    name            = string
    subnet_cidr     = string
    router_name     = string
    dns_nameservers = list(string)
    tags            = list(string)
  }))

  default = {
    "wireguard-net" = {
      name            = "wireguard-net"
      subnet_cidr     = "192.168.1.0/24"
      router_name     = "wireguard-router"
      enable_dhcp     = false
      dns_nameservers = ["188.93.16.19", "188.93.17.19"]
      tags            = ["wireguard_net"]
    }
  }
  description = "Hash map of Virtual Private Cloud network settings that should be created"
}


variable "instances" {
  type = map(object({
    name         = string
    vcpus        = number
    ram          = number
    disk         = number
    image        = string
    zone         = string
    network_name = string
    remote_volumes = map(object({
      name = string
      size = number
      type = string
      zone = string
    }))
    create_floating_ip = bool
    tags               = list(string)
  }))

  default = {
    "wireguard" = {
      disk               = 40
      image              = "Ubuntu 22.04 LTS 64-bit"
      name               = "wireguard"
      ram                = 4096
      vcpus              = 2
      zone               = "ru-7a"
      network_name       = "wireguard-net"
      remote_volumes     = {}
      create_floating_ip = true
      tags               = ["wireguard", "bastion", "docker", "primary", "preemptible"]
    },
  }

  description = "Hash map of instances setting that should be created"
}

variable "dns_records" {
  type = map(object({
    name               = string
    domain             = string
    type               = string
    ttl                = number
    link_instance_name = string
  }))

  default = {
    "wireguard" = {
      name               = "wireguard.sreway.ru"
      domain             = "sreway.ru"
      type               = "A"
      ttl                = 200
      link_instance_name = "wireguard"
    },
  }
  description = "Hash map of settings dns records that should be created"
}

variable "ssh_user_admin" {
  type        = string
  default     = "is"
  description = "SSH username administrator on compute nodes (sudoers)"
}

variable "ssh_user_ci" {
  type        = string
  default     = "ci"
  description = "SSH unprivileged username on compute nodes (not sudoers)"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key on compute nodes"
}

