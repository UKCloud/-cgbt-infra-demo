variable "OS_TENANT_NAME" {}
variable "OS_TENANT_ID" {}
variable "OS_USERNAME" {}
variable "OS_PASSWORD" {}
variable "OS_REGION" { default = "regionOne" }
variable "OS_AUTH_URL" { default = "https://cor00005.cni.ukcloud.com:13000/v2.0" }
variable "OS_INTERNET_GATEWAY_ID" { default = "893a5b59-081a-4e3a-ac50-1e54e262c3fa" }
variable "OS_INTERNET_NAME" { default = "internet" }

variable "IMAGE_NAME"   { default = "CentOS 7" }
variable "IMAGE_ID"     { default =  "32af054b-ab6d-448f-a4fd-b6b0ed089cc7" }
variable "jumpbox_type" { default = "t1.tiny" }
variable "proxy_type"   { default = "t1.tiny" }
variable "web_type"     { default = "t1.tiny" }
variable "db_type"      { default = "t1.tiny" }

variable "ssh_keypair_name" { default = "terraform-keypair" }
variable "public_key_file"  { default = "~/.ssh/user.pub" }
variable "private_key_file" { default = "~/.ssh/user.private" }

variable "router_name" { default = "InternetGW" }
variable "network_name" { default = "Internal" }
variable "subnet_name" { default = "internal_subnet" }

variable "subnet_cidr"  { default = "10.0.0.0/24" }
variable "domain_name" { default = "example.com" }

variable "ssh_user" { default = "centos" }

variable "num_webservers" { default = "2" }

variable "app_db_name"     { default = "counters" }
variable "app_db_user"     { default = "counters" }
variable "app_db_password" { default = "Secret123#" }
variable "app_environment" { default = "Testing" }