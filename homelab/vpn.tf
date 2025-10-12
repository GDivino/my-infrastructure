resource "oci_core_instance" "wireguard" {
  async                                   = null
  availability_domain                     = var.availability_domain
  compartment_id                          = var.compartment_id
  capacity_reservation_id                 = null
  cluster_placement_group_id              = null
  compute_cluster_id                      = null
  dedicated_vm_host_id                    = null
  display_name                            = "homelab-wireguard-server"
  extended_metadata                       = {}
  fault_domain                            = "FAULT-DOMAIN-1"
  instance_configuration_id               = null
  ipxe_script                             = null
  is_ai_enterprise_enabled                = null
  is_pv_encryption_in_transit_enabled     = null
  preserve_boot_volume                    = null
  preserve_data_volumes_created_at_launch = null
  security_attributes                     = {}
  shape                                   = "VM.Standard.A1.Flex"
  shape_config {
    baseline_ocpu_utilization = null
    memory_in_gbs             = 4
    nvmes                     = 0
    ocpus                     = 1
    resource_management       = null
    vcpus                     = 1
  }
  state                       = "RUNNING"
  update_operation_constraint = null
  agent_config {
    are_all_plugins_disabled = false
    is_management_disabled   = false
    is_monitoring_disabled   = false
    plugins_config {
      desired_state = "DISABLED"
      name          = "Vulnerability Scanning"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "Oracle Java Management Service"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "Oracle Autonomous Linux"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "OS Management Service Agent"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "OS Management Hub Agent"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "Management Agent"
    }
    plugins_config {
      desired_state = "ENABLED"
      name          = "Custom Logs Monitoring"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "Compute RDMA GPU Monitoring"
    }
    plugins_config {
      desired_state = "ENABLED"
      name          = "Compute Instance Run Command"
    }
    plugins_config {
      desired_state = "ENABLED"
      name          = "Compute Instance Monitoring"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "Compute HPC RDMA Auto-Configuration"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "Compute HPC RDMA Authentication"
    }
    plugins_config {
      desired_state = "ENABLED"
      name          = "Cloud Guard Workload Protection"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "Block Volume Management"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "Bastion"
    }
  }
  availability_config {
    is_live_migration_preferred = false
    recovery_action             = "RESTORE_INSTANCE"
  }
  create_vnic_details {
    assign_ipv6ip             = false
    assign_private_dns_record = false
    assign_public_ip          = "true"
    defined_tags = {
      "Oracle-Tags.CreatedBy" = "default/giodivino.tech@gmail.com"
      "Oracle-Tags.CreatedOn" = "2024-10-07T15:33:34.565Z"
    }
    display_name = "vnic20241007153338"
    freeform_tags = {
      project = "vpn"
    }
    hostname_label         = null
    nsg_ids                = ["ocid1.networksecuritygroup.oc1.ap-singapore-1.aaaaaaaahivtfx64sazqcscyzkl5rennrllcxffmnoqj4ovbw4ytsaels2fq"]
    private_ip             = "142.0.1.94"
    security_attributes    = {}
    skip_source_dest_check = false
    subnet_id              = "ocid1.subnet.oc1.ap-singapore-1.aaaaaaaaa6lshvr7ozxv26zyv5zyi6k5dsv2xphtmpu4ikan2aghyfvzjiea"
    vlan_id                = null
  }
  instance_options {
    are_legacy_imds_endpoints_disabled = false
  }
  launch_options {
    boot_volume_type                    = "PARAVIRTUALIZED"
    firmware                            = "UEFI_64"
    is_consistent_volume_naming_enabled = true
    is_pv_encryption_in_transit_enabled = true
    network_type                        = "PARAVIRTUALIZED"
    remote_data_volume_type             = "PARAVIRTUALIZED"
  }
  source_details {
    boot_volume_size_in_gbs         = "47"
    boot_volume_vpus_per_gb         = "10"
    is_preserve_boot_volume_enabled = false
    kms_key_id                      = null
    source_id                       = "ocid1.image.oc1.ap-singapore-1.aaaaaaaa4jxocdhtptck3txtsk6am6ufrkf7rbgjw3aaobbhvotvziesdwrq"
    source_type                     = "image"
  }

  defined_tags = {
    "Oracle-Tags.CreatedBy" = "default/giodivino.tech@gmail.com"
    "Oracle-Tags.CreatedOn" = "2024-10-07T15:33:34.427Z"
  }
  freeform_tags = {
    ManagedBy = "terraform"
    TFProject = "github.com/gdivino/my-infrastructure//vpn-vm/"
    project   = "vpn"
  }
}

resource "oci_core_vcn" "wireguard" {
  cidr_block                       = "142.0.0.0/16"
  cidr_blocks                      = ["142.0.0.0/16"]
  compartment_id                   = var.compartment_id
  display_name                     = "homelab-vcn"
  dns_label                        = null
  ipv6private_cidr_blocks          = []
  is_ipv6enabled                   = false
  is_oracle_gua_allocation_enabled = null
  security_attributes              = {}


  defined_tags = {
    "Oracle-Tags.CreatedBy" = "default/giodivino.tech@gmail.com"
    "Oracle-Tags.CreatedOn" = "2024-10-07T15:04:08.317Z"
  }
  freeform_tags = merge(local.default_tags, {
    project = "vpn"
  })
}

resource "oci_core_boot_volume" "wireguard" {
  availability_domain           = var.availability_domain
  compartment_id                = var.compartment_id
  boot_volume_replicas_deletion = null
  cluster_placement_group_id    = null
  display_name                  = "homelab-wireguard-server (Boot Volume)"
  is_auto_tune_enabled          = false
  kms_key_id                    = null
  size_in_gbs                   = "47"
  vpus_per_gb                   = "10"
  xrc_kms_key_id                = null
  source_details {
    id   = "ocid1.image.oc1.ap-singapore-1.aaaaaaaa4jxocdhtptck3txtsk6am6ufrkf7rbgjw3aaobbhvotvziesdwrq"
    type = "bootVolume"
  }

  defined_tags = {
    "Oracle-Tags.CreatedBy" = "default/giodivino.tech@gmail.com"
    "Oracle-Tags.CreatedOn" = "2024-10-07T15:33:34.427Z"
  }
  freeform_tags = merge(local.default_tags, {
    project = "vpn"
  })

  lifecycle {
    ignore_changes = [source_details]
  }
}
