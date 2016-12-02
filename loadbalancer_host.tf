# Deploy and configure the proxy server

data "template_file" "proxy_config" {
  template = "${file("templates/init.tpl")}"
  
  vars {
    hostname = "proxy01"
    fqdn     = "proxy01.${var.domain_name}"
  }
}

data "template_file" "haproxy_cfg" {
  template = "${file("templates/haproxy_cfg.tpl")}"
  
  vars {
    IPADDRESS    = "${openstack_compute_instance_v2.proxy_host.access_ip_v4}"
    BACKEND_LIST = "${join("\n", formatlist("    server %s %s:80 check", openstack_compute_instance_v2.web_host.*.name, openstack_compute_instance_v2.web_host.*.access_ip_v4))}"
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
  security_groups = ["${openstack_networking_secgroup_v2.internal_ssh.name}",
                     "${openstack_networking_secgroup_v2.any_web.name}"]

  user_data = "${data.template_file.proxy_config.rendered}"

  network {
    name = "${openstack_networking_network_v2.internal.name}"
    floating_ip = "${openstack_compute_floatingip_v2.proxy_host_ip.address}"
  }

  depends_on = [ "openstack_compute_instance_v2.jumpbox_host" ]

  connection {
    bastion_host = "${openstack_compute_floatingip_v2.jumpbox_host_ip.address}"
    bastion_user = "centos"
    bastion_private_key = "${file(var.private_key_file)}"

    user = "${var.ssh_user}"
    private_key = "${file(var.private_key_file)}"
    host = "${openstack_compute_instance_v2.proxy_host.access_ip_v4}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum -y install epel-release yum-plugin-priorities haproxy wget",
      "sudo systemctl enable haproxy",
      "sudo systemctl start haproxy",
      "wget https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/hatop/hatop-0.7.7.tar.gz",
      "tar zxvf hatop-0.7.7.tar.gz",
      "sudo install -m 755 hatop-0.7.7/bin/hatop /usr/local/bin"
    ]
  }
}

resource "null_resource" "haproxy_config" {
  depends_on = [ "openstack_compute_instance_v2.proxy_host", "openstack_compute_instance_v2.web_host" ]

  triggers {
    instance_ids = "${join(",", openstack_compute_instance_v2.web_host.*.id)},${openstack_compute_instance_v2.proxy_host.id}"
    config = "${data.template_file.haproxy_cfg.rendered}"
  }

  connection {
    bastion_host = "${openstack_compute_floatingip_v2.jumpbox_host_ip.address}"
    bastion_user = "centos"
    bastion_private_key = "${file(var.private_key_file)}"

    user = "${var.ssh_user}"
    private_key = "${file(var.private_key_file)}"
    host = "${openstack_compute_instance_v2.proxy_host.access_ip_v4}"
  }

  provisioner "file" {
    content = "${data.template_file.haproxy_cfg.rendered}"
    destination = "/tmp/haproxy.cfg"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cp /tmp/haproxy.cfg /etc/haproxy/haproxy.cfg",
      "sudo systemctl reload haproxy"
    ]
  }

}