# Deploy Webservers

data "template_file" "web_config" {
  template = "${file("templates/init.tpl")}"
  count    = "${var.num_webservers}"
  
  vars {
    hostname = "${format("web%02d", count.index + 1)}"
    fqdn     = "${format("web%02d", count.index + 1)}.${var.domain_name}"
  }
}

data "template_file" "php_config" {
  template = "${file("templates/config.php")}"

  vars {
    DB_HOST = "${openstack_compute_instance_v2.db_host.access_ip_v4}"
    DB_NAME = "${var.app_db_name}"
    DB_PORT = "3306"
    DB_USER = "${var.app_db_user}"
    DB_PASSWORD = "${var.app_db_password}"
    APP_ENVIRONMENT = "${var.app_environment}"
  }
}

resource "openstack_compute_instance_v2" "web_host" {
  name        = "${format("web%02d", count.index + 1)}.${var.domain_name}"
  image_name  = "${var.IMAGE_NAME}"
  flavor_name = "${var.web_type}"
  key_pair    = "${openstack_compute_keypair_v2.ssh-keypair.name}"
  security_groups = ["${openstack_networking_secgroup_v2.internal_ssh.name}",
                     "${openstack_networking_secgroup_v2.internal_web.name}"]

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
      "sudo yum -y install epel-release yum-plugin-priorities httpd php php-mysql",
      "sudo systemctl enable httpd",
      "sudo systemctl start httpd"
    ]
  }

}

resource "null_resource" "webapp_config" {
  depends_on = [ "openstack_compute_instance_v2.web_host", "openstack_compute_instance_v2.jumpbox_host" ]

  triggers {
    instance_ids = "${join(",", openstack_compute_instance_v2.web_host.*.id)}"
    config = "${data.template_file.php_config.rendered}"
    app = "${file("appfiles/index.php")}"
  }

  count = "${var.num_webservers}"

  connection {
    bastion_host = "${openstack_compute_floatingip_v2.jumpbox_host_ip.address}"
    bastion_user = "centos"
    bastion_private_key = "${file(var.private_key_file)}"

    user = "${var.ssh_user}"
    private_key = "${file(var.private_key_file)}"
    host = "${element(openstack_compute_instance_v2.web_host.*.access_ip_v4, count.index)}"
  }

  provisioner "file" {
    content = "${data.template_file.php_config.rendered}"
    destination = "/tmp/config.php"
  }

  provisioner "file" {
    content = "${file("appfiles/index.php")}"
    destination = "/tmp/index.php"
  }

  provisioner "file" {
    content = "${file("appfiles/favicon.ico")}"
    destination = "/tmp/favicon.ico"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cp /tmp/config.php /var/www/html/config.php",
      "sudo cp /tmp/index.php /var/www/html/index.php",
      "sudo cp /tmp/favicon.ico /var/www/html/favicon.ico"
    ]
  }

}