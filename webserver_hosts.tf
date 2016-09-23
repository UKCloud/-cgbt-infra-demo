# Deploy Webservers

data "template_file" "web_config" {
  template = "${file("templates/init.tpl")}"
  count    = "${var.num_webservers}"
  
  vars {
    hostname = "${format("web%02d", count.index + 1)}"
    fqdn     = "${format("web%02d", count.index + 1)}.${var.domain_name}"
  }
}

resource "openstack_compute_instance_v2" "web_host" {
  name        = "${format("web%02d", count.index + 1)}.${var.domain_name}"
  image_name  = "${var.IMAGE_NAME}"
  flavor_name = "${var.web_type}"
  key_pair    = "${openstack_compute_keypair_v2.ssh-keypair.name}"
  security_groups = ["${openstack_networking_secgroup_v2.any_ssh.name}",
                     "${openstack_networking_secgroup_v2.any_web.name}"]

  count = "${var.num_webservers}"

  user_data = "${element(data.template_file.web_config.*.rendered, count)}"

  network {
    name = "${openstack_networking_network_v2.dmz.name}"
  }

  depends_on = [ "openstack_compute_instance_v2.jumpbox_host" ]

  connection {
    bastion_host = "${openstack_compute_floatingip_v2.jumpbox_host_ip.address}"
    bastion_user = "centos"
    bastion_private_key = "${file(var.private_key_file)}"

    user = "${var.ssh_user}"
    private_key = "${file(var.private_key_file)}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum -y install epel-release yum-plugin-priorities httpd"
    ]
  }

}
