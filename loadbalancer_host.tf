# Deploy and configure the proxy server

data "template_file" "proxy_config" {
  template = "${file("init.tpl")}"
  
  vars {
    hostname = "proxy01"
    fqdn     = "proxy01.${var.domain_name}"
  }
}

resource "openstack_compute_floatingip_v2" "proxy_host_ip" {
  region = ""
  pool = "${var.OS_INTERNET_NAME}"
}

resource "openstack_compute_instance_v2" "proxy_host" {
  name        = "proxy01.${var.domain_name}"
  image_name  = "${var.IMAGE_NAME}"
  flavor_name = "${var.proxy_type}"
  key_pair    = "${openstack_compute_keypair_v2.ssh-keypair.name}"
  security_groups = ["${openstack_networking_secgroup_v2.any_ssh.name}"]

  user_data = "${data.template_file.jumpbox_config.rendered}"

  network {
    name = "${openstack_networking_network_v2.dmz.name}"
    fixed_ip_v4 = "${cidrhost(var.DMZ_Subnet, 5)}"
    floating_ip = "${openstack_compute_floatingip_v2.proxy_host_ip.address}"
  }

  connection {
    bastion_host = "${openstack_compute_floatingip_v2.jumpbox_host_ip.address}"
    bastion_user = "centos"
    bastion_private_key = "${file(var.private_key_file)}"

    user = "${var.ssh_user}"
    private_key = "${file(var.private_key_file)}"
    host = "${openstack_compute_floatingip_v2.proxy_host.access_ip_v4}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum -y install epel-release yum-plugin-priorities nmap-ncat",
      "sudo yum update -y --exclude=kernel"
    ]
  }

}
