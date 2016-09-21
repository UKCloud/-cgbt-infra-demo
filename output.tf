output "jumpbox_address" {
  value = "${openstack_compute_floatingip_v2.jumpbox_host_ip.address}"
}