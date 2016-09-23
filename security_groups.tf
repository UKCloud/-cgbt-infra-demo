resource "openstack_networking_secgroup_v2" "any_ssh" {
  name = "External SSH Access"
  description = "Allow SSH access to VMs"
}

resource "openstack_networking_secgroup_rule_v2" "any_ssh_rule_1" {
  direction = "ingress"
  ethertype = "IPv4"
  protocol = "tcp"
  port_range_min = 22
  port_range_max = 22
  remote_ip_prefix = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.any_ssh.id}"
}

resource "openstack_networking_secgroup_v2" "any_web" {
  name = "External Web Access"
  description = "Allow Web access to VMs"
}

resource "openstack_networking_secgroup_rule_v2" "any_web_rule_1" {
  direction = "ingress"
  ethertype = "IPv4"
  protocol = "tcp"
  port_range_min = 80
  port_range_max = 80
  remote_ip_prefix = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.any_web.id}"
}
