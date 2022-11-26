%{ for floating_ip in floating_ips ~}
%{ if floating_ip.fixed_ip == bastion_host ~}
Host bastion
  Hostname ${ floating_ip.address }
  User ${ssh_user}
%{ endif ~}
%{ endfor ~}
# primary host for ci
Host docker-node
  Hostname ${ docker_host }
  User ${ ssh_user }
  ProxyJump bastion
# internal server on private network
%{ for _, host in hosts ~}
Host ${host.name}
  Hostname ${ host.access_ip_v4 }
  User ${ ssh_user }
  ProxyJump bastion
%{ endfor ~}
Host *
    StrictHostKeyChecking no