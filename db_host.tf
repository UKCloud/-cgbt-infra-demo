# Deploy Database Server

data "template_file" "db_config" {
  template = "${file("templates/init.tpl")}"
  
  vars {
    hostname = "db01"
    fqdn     = "db01.${var.domain_name}"
  }
}

data "template_file" "schema_sql" {
  template = "${file("templates/schema_sql.tpl")}"
  
  vars {
    APP_DB       = "${var.app_db_name}"
    APP_USER     = "${var.app_db_user}"
    APP_PASSWORD = "${var.app_db_password}"
  }
}

resource "openstack_compute_instance_v2" "db_host" {
  name        = "db01.${var.domain_name}"
  image_name  = "${var.IMAGE_NAME}"
  flavor_name = "${var.db_type}"
  key_pair    = "${openstack_compute_keypair_v2.ssh-keypair.name}"
  security_groups = ["${openstack_networking_secgroup_v2.internal_ssh.name}",
                     "${openstack_networking_secgroup_v2.internal_mysql.name}"]

  user_data = "${data.template_file.db_config.rendered}"

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

  provisioner "file" {
    content = "${data.template_file.schema_sql.rendered}"
    destination = "/tmp/schema.sql"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum -y install epel-release yum-plugin-priorities  mariadb-server mariadb",
      "sudo systemctl enable mariadb.service",
      "sudo systemctl start mariadb.service",
      "cat /tmp/schema.sql | sudo mysql"
    ]
  }
}
