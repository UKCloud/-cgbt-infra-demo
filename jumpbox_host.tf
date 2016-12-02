# Deploy and configure the Jumpbox server

data "template_file" "jumpbox_config" {
  template = "${file("templates/init.tpl")}"
  
  vars {
    hostname = "jump01"
    fqdn     = "jump01.${var.domain_name}"
  }
}

resource "openstack_compute_floatingip_v2" "jumpbox_host_ip" {
  region = ""
  pool = "${var.OS_INTERNET_NAME}"
}

resource "openstack_compute_instance_v2" "jumpbox_host" {
  name        = "jump01.${var.domain_name}"
  image_name  = "${var.IMAGE_NAME}"
  flavor_name = "${var.jumpbox_type}"
  key_pair    = "${openstack_compute_keypair_v2.ssh-keypair.name}"
  security_groups = ["${openstack_networking_secgroup_v2.any_ssh.name}"]

  user_data = "${data.template_file.jumpbox_config.rendered}"

  network {
    name = "${openstack_networking_network_v2.internal.name}"
    fixed_ip_v4 = "${cidrhost(var.subnet_cidr, 5)}"
    floating_ip = "${openstack_compute_floatingip_v2.jumpbox_host_ip.address}"
  }

  connection {
    user = "${var.ssh_user}"
    private_key = "${file(var.private_key_file)}"
    host = "${openstack_compute_floatingip_v2.jumpbox_host_ip.address}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum -y install epel-release yum-plugin-priorities nmap-ncat",
      "mkdir -p ~/.ssh"
    ]
  }

  provisioner "file" {
    content = "${file(var.private_key_file)}"
    destination = "~/.ssh/id_rsa"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod go-rwx ~/.ssh/id_rsa"
    ]
  }
}

resource "null_resource" "jumpbox_hosts_file" {
  depends_on = [ "openstack_compute_instance_v2.jumpbox_host" ]

  triggers {
    hosts = "${data.template_file.hosts_file.rendered}"
  }
  
  connection {
    user = "${var.ssh_user}"
    private_key = "${file(var.private_key_file)}"
    host = "${openstack_compute_floatingip_v2.jumpbox_host_ip.address}"
  }

  provisioner "file" {
    content = "${data.template_file.hosts_file.rendered}"
    destination = "/tmp/dynamic_hosts"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo sed -i '/### Generated by Terraform/,/### End of Generated by Terraform/c\\' /etc/hosts",
      "cat /tmp/dynamic_hosts | sudo tee -a /etc/hosts"
    ]
  }
}
