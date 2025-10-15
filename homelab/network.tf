resource "oci_core_vcn" "wireguard" {
  cidr_block              = "142.0.0.0/16"
  cidr_blocks             = ["142.0.0.0/16"]
  compartment_id          = var.compartment_id
  display_name            = "homelab-vcn"
  ipv6private_cidr_blocks = []
  is_ipv6enabled          = false
  security_attributes     = {}


  defined_tags = {
    "Oracle-Tags.CreatedBy" = "default/giodivino.tech@gmail.com"
    "Oracle-Tags.CreatedOn" = "2024-10-07T15:04:08.317Z"
  }
  freeform_tags = merge(local.default_tags, {
    project = "vpn"
  })
}

# ========== Public ==========
resource "oci_core_internet_gateway" "wireguard" {
  display_name   = "homelab-wireguard-internet-gateway"
  compartment_id = var.compartment_id
  enabled        = true
  route_table_id = null
  vcn_id         = oci_core_vcn.wireguard.id

  defined_tags = {
    "Oracle-Tags.CreatedBy" = "default/giodivino.tech@gmail.com"
    "Oracle-Tags.CreatedOn" = "2024-10-07T15:15:01.859Z"
  }
  freeform_tags = merge(local.default_tags, {
    project = "vpn"
  })
}

resource "oci_core_route_table" "public_route_table" {
  display_name   = "homelab-wireguard-public-route-table"
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.wireguard.id
  route_rules {
    description       = null
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.wireguard.id
    route_type        = "STATIC"
  }

  defined_tags = {
    "Oracle-Tags.CreatedBy" = "default/giodivino.tech@gmail.com"
    "Oracle-Tags.CreatedOn" = "2024-10-07T15:04:08.317Z"
  }
  freeform_tags = merge(local.default_tags, {
    project = "vpn"
  })
}

resource "oci_core_security_list" "public_security_list" {
  display_name   = "homelab-wireguard-public-security-list"
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.wireguard.id

  # Allow wg-easy traffic from anywhere
  ingress_security_rules {
    description = null
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false
    tcp_options {
      min = 51821
      max = 51821
    }
  }

  # Allow Wireguard traffic (UDP) from anywhere
  ingress_security_rules {
    description = null
    protocol    = "17"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false
    udp_options {
      min = 51820
      max = 51820
    }
  }

  # SSH from anywhere
  ingress_security_rules {
    description = null
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false
    tcp_options {
      max = 22
      min = 22
    }
  }

  # Allow all egress traffic
  egress_security_rules {
    description      = null
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
    stateless        = false
  }

  defined_tags = {
    "Oracle-Tags.CreatedBy" = "default/giodivino.tech@gmail.com"
    "Oracle-Tags.CreatedOn" = "2024-10-07T15:04:08.317Z"
  }
  freeform_tags = merge(local.default_tags, {
    project = "vpn"
  })
}

resource "oci_core_subnet" "public_subnet" {
  display_name               = "homelab-wireguard-public-subnet"
  availability_domain        = var.availability_domain
  compartment_id             = var.compartment_id
  cidr_block                 = "142.0.1.0/24"
  dhcp_options_id            = "ocid1.dhcpoptions.oc1.ap-singapore-1.aaaaaaaa6mkgesqdpjjqyasbfslnplimf5lbbntdvi4oxer7r63djmpvc4ua"
  dns_label                  = null
  ipv6cidr_block             = null
  ipv6cidr_blocks            = []
  prohibit_internet_ingress  = false
  prohibit_public_ip_on_vnic = false
  route_table_id             = oci_core_route_table.public_route_table.id
  security_list_ids          = [oci_core_security_list.public_security_list.id]
  vcn_id                     = oci_core_vcn.wireguard.id

  defined_tags = {
    "Oracle-Tags.CreatedBy" = "default/giodivino.tech@gmail.com"
    "Oracle-Tags.CreatedOn" = "2024-10-07T15:06:32.614Z"
  }
  freeform_tags = merge(local.default_tags, {
    project = "vpn"
  })
}

# ========== Private ==========
resource "oci_core_nat_gateway" "wireguard" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.wireguard.id
  display_name   = "homelab-wireguard-nat"

  freeform_tags = merge(local.default_tags, {
    project = "vpn"
  })
}

resource "oci_core_route_table" "private_route_table" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.wireguard.id
  display_name   = "homelab-wireguard-private-route-table"
  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_nat_gateway.wireguard.id
  }

  freeform_tags = merge(local.default_tags, {
    project = "vpn"
  })
}

resource "oci_core_security_list" "private_security_list" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.wireguard.id
  display_name   = "homelab-wireguard-private-security-list"

  # Allow n8n traffic ONLY from within the VCN
  ingress_security_rules {
    protocol  = "6" # TCP
    source    = "142.0.0.0/16"
    stateless = false
    tcp_options {
      min = 5678 # n8n default port
      max = 5678
    }
  }

  # Allow SSH ONLY from within the VCN
  ingress_security_rules {
    protocol  = "6" # TCP
    source    = "142.0.0.0/16"
    stateless = false
    tcp_options {
      min = 22
      max = 22
    }
  }

  # Allow all egress traffic
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
    stateless   = false
  }

  freeform_tags = merge(local.default_tags, {
    project = "vpn"
  })
}

resource "oci_core_subnet" "private_subnet" {
  # availability_domain        = var.availability_domain
  compartment_id             = var.compartment_id
  cidr_block                 = "142.0.2.0/24"
  dhcp_options_id            = "ocid1.dhcpoptions.oc1.ap-singapore-1.aaaaaaaa6mkgesqdpjjqyasbfslnplimf5lbbntdvi4oxer7r63djmpvc4ua"
  display_name               = "homelab-wireguard-private-subnet"
  dns_label                  = null
  ipv6cidr_block             = null
  ipv6cidr_blocks            = []
  prohibit_internet_ingress  = true
  prohibit_public_ip_on_vnic = true
  route_table_id             = oci_core_route_table.private_route_table.id
  security_list_ids          = [oci_core_security_list.private_security_list.id]
  vcn_id                     = oci_core_vcn.wireguard.id

  defined_tags = {
    "Oracle-Tags.CreatedBy" = "default/giodivino.tech@gmail.com"
    "Oracle-Tags.CreatedOn" = "2024-10-07T15:10:43.893Z"
  }
  freeform_tags = {
    project = "homelab"
  }
}
