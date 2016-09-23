# Configure the OpenStack Provider
provider "openstack" {
    user_name   = "${var.OS_USERNAME}"
    tenant_name = "${var.OS_TENANT_NAME}"
    password    = "${var.OS_PASSWORD}"
    auth_url    = "${var.OS_AUTH_URL}"
    insecure    = "true"
}

resource "openstack_networking_router_v2" "internet_gw" {
  region = ""
  name   = "InternetGW"
  external_gateway = "${var.OS_INTERNET_GATEWAY_ID}"
}

resource "openstack_networking_network_v2" "dmz" {
  name = "DMZ"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "dmz_subnet" {
  name       = "dmz_network"
  network_id = "${openstack_networking_network_v2.dmz.id}"
  cidr       = "${var.DMZ_Subnet}"
  ip_version = 4
  enable_dhcp = "true"
  allocation_pools = { start = "${cidrhost(var.DMZ_Subnet, 50)}"
                       end = "${cidrhost(var.DMZ_Subnet, 200)}" } 
  dns_nameservers  = [ "8.8.8.8" ]
}

resource "openstack_networking_router_interface_v2" "gw_if_1" {
  region = ""
  router_id = "${openstack_networking_router_v2.internet_gw.id}"
  subnet_id = "${openstack_networking_subnet_v2.dmz_subnet.id}"
}

resource "openstack_compute_keypair_v2" "ssh-keypair" {
  name       = "${var.ssh_keypair_name}"
  public_key = "${file(var.public_key_file)}"
}

data "template_file" "hosts_file" {
  template = "${file("hosts.tpl")}"

  vars {
    HOST_LIST = "${join("\n", formatlist("%s   %s", concat(list(openstack_compute_instance_v2.jumpbox_host.access_ip_v4, openstack_compute_instance_v2.proxy_host.access_ip_v4), openstack_compute_instance_v2.web_host.*.access_ip_v4), concat(list(openstack_compute_instance_v2.jumpbox_host.name, openstack_compute_instance_v2.proxy_host.name), openstack_compute_instance_v2.web_host.*.name) ))}"
  }
}
