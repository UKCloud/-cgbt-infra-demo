output "jumpbox_address" {
  value = "${openstack_compute_floatingip_v2.jumpbox_host_ip.address}"
}

output "server_names" {
	value = ["${list(openstack_compute_instance_v2.jumpbox_host.name, openstack_compute_instance_v2.proxy_host.name)}"]
}

output "private_key" {
	value = "${var.private_key_file}"
}

output "jumpbox_user" {
	value = "${var.ssh_user}"
}