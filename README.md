# Example Wireguard

This repository contains an example of wireguard ([wg-easy](https://github.com/WeeJeWel/wg-easy)) deployment via terraform and docker (rootless) in gitlab ci.

## Gitlab pipelines

- [pipelines](https://gitlab.com/sreway/iac/examples/wireguard-docker-compose/-/pipelines)

## Environment variables

| Env | Description |
| - | - |
| `CI_SSH_PRIVATE_KEY` | The SSH private key to access managed host |
| `TF_VAR_sel_account_id` | Selectel account id. (contract number) |
| `TF_VAR_sel_account_id` | Selectel account id. (contract number) |
| `TF_VAR_sel_api_key` | Selectel API key. Can be created [here](https://my.selectel.ru/profile/apikeys) |
| `TF_VAR_sel_project_id` | Selectel VPC project id |
| `TF_VAR_sel_user_name` | Selectel VPC project name |
| `TF_VAR_sel_user_password` | The password of user for access to Selectel VPC project |
| `TF_VAR_ssh_public_key` | The SSH public key to access managed host in ci for users created via ansible (SSH access for the root user is disabled) |
| `SSL_EMAIL` | The email address to use for the SSL certificate creation |
| `WG_HOST` | The public hostname of your VPN server |
| `WG_PASSWORD` |  The password used for authentication in the Web UI |

`Warning` In this example, TF_VAR_ssh_public_key is the same key as [input_sel_ssh_key_name](/infra/vars.tf#L44)

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.3 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_local"></a> [local](#provider\_local) | n/a |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ansible_inventory"></a> [ansible\_inventory](#module\_ansible\_inventory) | [git](https://github.com/sreway/terraform-selectel-modules/tree/main/modules/vpc/ansible_inventory) | n/a |
| <a name="module_available_instances"></a> [available\_instances](#module\_available\_instances) | [git](https://github.com/sreway/terraform-selectel-modules/tree/main/modules/vpc/datasource/available_instances) | n/a |
| <a name="module_domain_record"></a> [domain\_record](#module\_domain\_record) | [git](https://github.com/sreway/terraform-selectel-modules/tree/main/modules/dns/domain_record) | n/a |
| <a name="module_floating_ip_mapping"></a> [floating\_ip\_mapping](#module\_floating\_ip\_mapping) | [git](https://github.com/sreway/terraform-selectel-modules/tree/main/modules/vpc/network/floating_ip_mapping) | n/a |
| <a name="module_instance"></a> [instance](#module\_instance) | [git](https://github.com/sreway/terraform-selectel-modules/tree/main/modules/vpc/instance) | n/a |
| <a name="module_internal_network"></a> [internal\_network](#module\_internal\_network) | [git](https://github.com/sreway/terraform-selectel-modules/tree/main/modules/vpc/network/internal_network) | n/a |
| <a name="module_router"></a> [router](#module\_router) | [git](https://github.com/sreway/terraform-selectel-modules/tree/main/modules/vpc/network/router) | n/a |

## Resources

| Name | Type |
|------|------|
| [local_file.ansible_inventory](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [null_resource.deploy_inventory](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_dns_records"></a> [dns\_records](#input\_dns\_records) | Hash map of settings dns records that should be created | <pre>map(object({<br>    name               = string<br>    domain             = string<br>    type               = string<br>    ttl                = number<br>    link_instance_name = string<br>  }))</pre> | <pre>{<br>  "wireguard": {<br>    "domain": "sreway.ru",<br>    "link_instance_name": "wireguard",<br>    "name": "wireguard.sreway.ru",<br>    "ttl": 200,<br>    "type": "A"<br>  }<br>}</pre> | no |
| <a name="input_instances"></a> [instances](#input\_instances) | Hash map of instances setting that should be created | <pre>map(object({<br>    name         = string<br>    vcpus        = number<br>    ram          = number<br>    disk         = number<br>    image        = string<br>    zone         = string<br>    network_name = string<br>    remote_volumes = map(object({<br>      name = string<br>      size = number<br>      type = string<br>      zone = string<br>    }))<br>    create_floating_ip = bool<br>    tags               = list(string)<br>  }))</pre> | <pre>{<br>  "wireguard": {<br>    "create_floating_ip": true,<br>    "disk": 40,<br>    "image": "Ubuntu 22.04 LTS 64-bit",<br>    "name": "wireguard",<br>    "network_name": "wireguard-net",<br>    "ram": 4096,<br>    "remote_volumes": {},<br>    "tags": [<br>      "wireguard",<br>      "bastion",<br>      "docker",<br>      "primary"<br>    ],<br>    "vcpus": 2,<br>    "zone": "ru-7a"<br>  }<br>}</pre> | no |
| <a name="input_networks"></a> [networks](#input\_networks) | Hash map of Virtual Private Cloud network settings that should be created | <pre>map(object({<br>    name            = string<br>    subnet_cidr     = string<br>    router_name     = string<br>    dns_nameservers = list(string)<br>    tags            = list(string)<br>  }))</pre> | <pre>{<br>  "wireguard-net": {<br>    "dns_nameservers": [<br>      "188.93.16.19",<br>      "188.93.17.19"<br>    ],<br>    "enable_dhcp": false,<br>    "name": "wireguard-net",<br>    "router_name": "wireguard-router",<br>    "subnet_cidr": "192.168.1.0/24",<br>    "tags": [<br>      "wireguard_net"<br>    ]<br>  }<br>}</pre> | no |
| <a name="input_sel_account_id"></a> [sel\_account\_id](#input\_sel\_account\_id) | Selectel account id. (contract number) | `string` | n/a | yes |
| <a name="input_sel_api_key"></a> [sel\_api\_key](#input\_sel\_api\_key) | Selectel API key. Can be create: https://my.selectel.ru/profile/apikeys | `string` | n/a | yes |
| <a name="input_sel_auth_url"></a> [sel\_auth\_url](#input\_sel\_auth\_url) | Auth url of Selectel VPC API. | `string` | `"https://api.selvpc.ru/identity/v3"` | no |
| <a name="input_sel_project_id"></a> [sel\_project\_id](#input\_sel\_project\_id) | Selectel VPC project ID | `string` | n/a | yes |
| <a name="input_sel_project_name"></a> [sel\_project\_name](#input\_sel\_project\_name) | Selectel VPC project name | `string` | `"sreway"` | no |
| <a name="input_sel_region_name"></a> [sel\_region\_name](#input\_sel\_region\_name) | Name of region for Selectel VPC resources | `string` | `"ru-7"` | no |
| <a name="input_sel_ssh_key_name"></a> [sel\_ssh\_key\_name](#input\_sel\_ssh\_key\_name) | The name of the SSH key pair to put on the compute instance. The key pair must already be created in some region and associated with Selectel vpc project | `string` | `"ci"` | no |
| <a name="input_sel_user_name"></a> [sel\_user\_name](#input\_sel\_user\_name) | Name of user for access to Selectel VPC project | `string` | n/a | yes |
| <a name="input_sel_user_password"></a> [sel\_user\_password](#input\_sel\_user\_password) | Password of user for access to Selectel VPC project | `string` | n/a | yes |
| <a name="input_ssh_public_key"></a> [ssh\_public\_key](#input\_ssh\_public\_key) | SSH public key on compute nodes | `string` | n/a | yes |
| <a name="input_ssh_user_admin"></a> [ssh\_user\_admin](#input\_ssh\_user\_admin) | SSH username administrator on compute nodes (sudoers) | `string` | `"is"` | no |
| <a name="input_ssh_user_ci"></a> [ssh\_user\_ci](#input\_ssh\_user\_ci) | SSH unprivileged username on compute nodes (not sudoers) | `string` | `"ci"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ansible_inventory_data"></a> [ansible\_inventory\_data](#output\_ansible\_inventory\_data) | n/a |
| <a name="output_ssh_config"></a> [ssh\_config](#output\_ssh\_config) | n/a |
<!-- END_TF_DOCS -->