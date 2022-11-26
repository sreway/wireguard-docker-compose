provider "openstack" {
  user_name           = var.sel_user_name
  password            = var.sel_user_password
  tenant_name         = var.sel_project_name
  project_domain_name = var.sel_account_id
  user_domain_name    = var.sel_account_id
  auth_url            = var.sel_auth_url
  region              = var.sel_region_name
}

provider "selectel" {
  token = var.sel_api_key
}

// Create networks
module "internal_network" {
  source                 = "git::https://github.com/sreway/terraform-selectel-modules.git//modules/vpc/network/internal_network"
  for_each               = var.networks
  network_name           = each.value.name
  subnet_cidr            = each.value.subnet_cidr
  subnet_dns_nameservers = each.value.dns_nameservers
}

// Create routers for networks
module "router" {
  source      = "git::https://github.com/sreway/terraform-selectel-modules.git//modules/vpc/network/router"
  for_each    = module.internal_network
  router_name = var.networks[each.key].router_name
  subnet_id   = each.value.subnet_id
  depends_on = [
    module.internal_network
  ]
}

// Get available instances 
module "available_instances" {
  source = "git::https://github.com/sreway/terraform-selectel-modules.git//modules/vpc/datasource/available_instances"
  region = var.sel_region_name
}

// Create instances
module "instance" {
  source                  = "git::https://github.com/sreway/terraform-selectel-modules.git//modules/vpc/instance"
  for_each                = var.instances
  instance_name           = each.value.name
  instance_ram            = each.value.ram
  instance_vcpus          = each.value.vcpus
  instance_disk           = each.value.disk
  instance_image          = each.value.image
  instance_zone           = each.value.zone
  instance_network_id     = module.internal_network[each.value.network_name].network_id
  instance_subnet_id      = module.internal_network[each.value.network_name].subnet_id
  instance_remote_volumes = each.value.remote_volumes
  instance_tags           = each.value.tags
  instance_key_pair_name  = var.sel_ssh_key_name
  depends_on = [
    module.internal_network
  ]
}

// Create floating ip addresses and mapping inctances ports
module "floating_ip_mapping" {
  source     = "git::https://github.com/sreway/terraform-selectel-modules.git//modules/vpc/network/floating_ip_mapping"
  for_each   = { for k, v in module.instance : k => v if var.instances[k].create_floating_ip == true }
  port_id    = module.instance[each.key].port_id
  depends_on = [module.instance, module.internal_network]
}

// Create DNS records
module "domain_record" {
  source                = "git::https://github.com/sreway/terraform-selectel-modules.git//modules/dns/domain_record"
  for_each              = var.dns_records
  domain_name           = each.value.domain
  domain_record_name    = each.value.name
  domain_record_type    = each.value.type
  domain_record_ttl     = each.value.ttl
  domain_record_content = module.floating_ip_mapping[each.value.link_instance_name].address
  depends_on = [
    module.floating_ip_mapping
  ]
}

// Add tag new_instance for recently createated compute instances (need for re-run apply when new instance added)
locals {
  instances = { for k, v in module.instance : k => {
    id           = v.id
    access_ip_v4 = v.access_ip_v4
    tags         = !contains(module.available_instances.instances, k) ? toset(concat(tolist(v.tags), ["new_instance"])) : v.tags
  } }
}

// Create ansible inventory
module "ansible_inventory" {
  source       = "git::https://github.com/sreway/terraform-selectel-modules.git//modules/vpc/ansible_inventory"
  instances    = local.instances
  floating_ips = module.floating_ip_mapping
  depends_on = [
    local.instances, module.floating_ip_mapping
  ]
}

// Create ansible inventory file
resource "local_file" "ansible_inventory" {
  content    = module.ansible_inventory.data
  filename   = "${path.module}/ansible/inventory/hosts.yml"
  depends_on = [module.ansible_inventory]
}


// Run ansible playbook
resource "null_resource" "deploy_inventory" {
  triggers = {
    instances    = sha1(jsonencode(module.instance))
    floating_ips = sha1(jsonencode(module.floating_ip_mapping))
  }
  provisioner "local-exec" {
    command = <<-EOT
      ansible-galaxy role install -r ${path.module}/ansible/requirements.yml -p ${path.module}/ansible/roles --force
      ansible-playbook -i ${local_file.ansible_inventory.filename} ${path.module}/ansible/site.yml
    EOT
    environment = {
      ANSIBLE_FORCE_COLOR = 1
      SSH_USER_ADMIN      = var.ssh_user_admin
      SSH_NOT_ADMIN_USER  = var.ssh_user_ci
      SSH_PUBLIC_KEY      = var.ssh_public_key
    }
    on_failure = continue
  }
  depends_on = [local_file.ansible_inventory]
}

// Create ssh config for ci jobs
locals {
  ssh_config = templatefile("${path.module}/templates/ssh_config.tpl", {
    ssh_user     = var.ssh_user_ci
    bastion_host = one([for _, v in module.instance : v.access_ip_v4 if contains(v.tags, "bastion")][*])
    docker_host = coalesce(one([for _, v in module.instance : v.access_ip_v4 if contains(v.tags, "docker")
    && contains(v.tags, "primary")][*]), "not found")
    hosts        = module.instance
    floating_ips = module.floating_ip_mapping
  })
}