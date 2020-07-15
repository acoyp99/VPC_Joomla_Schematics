
data "ibm_resource_group" "group" {
  name = "${var.resource_group}"
}

resource "ibm_is_ssh_key" "sshkey" {
  name       = "keysshfortomcat"
  public_key = "${var.ssh_public}"
}

resource "ibm_is_vpc" "vpcfortomcat" {
  name = "vpctomcat"
  resource_group = "${data.ibm_resource_group.group.id}"
}

resource "ibm_is_subnet" "subnettomcat" {
  name            = "subnettomcat"
  vpc             = "${ibm_is_vpc.vpcfortomcat.id}"
  zone            = "us-south-1"
  total_ipv4_address_count= "256"
}

resource "ibm_is_security_group" "securitygroupfortomcat" {
  name = "securitygroupfortomcat"
  vpc  = "${ibm_is_vpc.vpcfortomcat.id}"
  resource_group = "${data.ibm_resource_group.group.id}"
}


resource "ibm_is_instance" "vsi1" {
  name    = "tomcat-mysql"
  image   = "7eb4e35b-4257-56f8-d7da-326d85452591"
  profile = "b-2x8"
  resource_group = "${data.ibm_resource_group.group.id}"


  primary_network_interface {
    subnet = "${ibm_is_subnet.subnettomcat.id}"
    security_groups = ["${ibm_is_security_group.securitygroupfortomcat.id}"]
  }

  vpc       = "${ibm_is_vpc.vpcfortomcat.id}"
  zone      = "us-south-1"
  keys = ["${ibm_is_ssh_key.sshkey.id}"]
}

resource "ibm_is_security_group_rule" "testacc_security_group_rule_all" {
  group     = "${ibm_is_security_group.securitygroupfortomcat.id}"
  direction = "inbound"
  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "testacc_security_group_rule_tomcat" {
  group     = "${ibm_is_security_group.securitygroupfortomcat.id}"
  direction = "inbound"
  tcp {
    port_min = 8080
    port_max = 8080
  }
}

resource "ibm_is_security_group_rule" "testacc_security_group_rule_icmp" {
  group     = "${ibm_is_security_group.securitygroupfortomcat.id}"
  direction = "inbound"
  icmp {
    type = 8
  }
}

resource "ibm_is_security_group_rule" "testacc_security_group_rule_out" {
  group     = "${ibm_is_security_group.securitygroupfortomcat.id}"
  direction = "outbound"
}

resource "ibm_is_floating_ip" "ipf1" {
  name   = "ipfortomcat"
  target = "${ibm_is_instance.vsi1.primary_network_interface.0.id}"
  resource_group = "${data.ibm_resource_group.group.id}"
}

output sshcommand {
  value = "ssh -i <name_of_sshkey_priv> root@${ibm_is_floating_ip.ipf1.address}"
}
