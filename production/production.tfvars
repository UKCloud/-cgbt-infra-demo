OS_AUTH_URL = "https://cor00005.cni.ukcloud.com:13000/v2.0"
OS_TENANT_NAME = "UKCloudDevOpsDemo"
OS_TENANT_ID = "7a90558f6e2e40f2a4f95708da6408ac"
OS_INTERNET_GATEWAY_ID = "893a5b59-081a-4e3a-ac50-1e54e262c3fa"
OS_INTERNET_NAME = "internet"
IMAGE_NAME = "CentOS 7"
jumpbox_type = "t1.small"
proxy_type = "t1.small"
web_type = "t1.small"
db_type = "t1.small"
public_key_file = "~/.ssh/root.pub"
private_key_file = "~/.ssh/root.private"
domain_name = "devops-consultant.com"
ssh_keypair_name = "terraform-prod"
app_environment = "Production"
num_webservers = "4"
router_name = "ProductionGW"
network_name = "prod_network" 
subnet_name = "prod_subnet"
subnet_cidr = "10.50.2.0/24"