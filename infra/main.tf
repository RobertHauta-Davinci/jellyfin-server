terraform {
  required_version = ">= 1.5"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 6.0"
    }
  }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.api_key_fingerprint
  private_key_path = var.api_private_key_path
  region           = var.region
}

# --- Networking ---

resource "oci_core_vcn" "jellyfin" {
  compartment_id = var.compartment_ocid
  display_name   = "jellyfin-vcn"
  cidr_blocks    = ["10.0.0.0/16"]
  dns_label      = "jellyfin"
}

resource "oci_core_internet_gateway" "jellyfin" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.jellyfin.id
  display_name   = "jellyfin-igw"
  enabled        = true
}

resource "oci_core_route_table" "jellyfin" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.jellyfin.id
  display_name   = "jellyfin-rt"

  route_rules {
    network_entity_id = oci_core_internet_gateway.jellyfin.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}

resource "oci_core_security_list" "jellyfin" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.jellyfin.id
  display_name   = "jellyfin-security-list"

  # Allow all egress
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  # SSH
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    tcp_options {
      min = 22
      max = 22
    }
  }

  # HTTP (Let's Encrypt ACME + redirect)
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 80
      max = 80
    }
  }

  # HTTPS
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 443
      max = 443
    }
  }

  # HTTPS (HTTP/3 / QUIC)
  ingress_security_rules {
    protocol = "17" # UDP
    source   = "0.0.0.0/0"
    udp_options {
      min = 443
      max = 443
    }
  }
}

resource "oci_core_subnet" "jellyfin" {
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.jellyfin.id
  display_name      = "jellyfin-subnet"
  cidr_block        = "10.0.1.0/24"
  dns_label         = "jellyfin"
  route_table_id    = oci_core_route_table.jellyfin.id
  security_list_ids = [oci_core_security_list.jellyfin.id]
}

# --- Compute (ARM Ampere A1 — Always Free) ---

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

data "oci_core_images" "ubuntu_arm" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "24.04"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

resource "oci_core_instance" "jellyfin" {
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name        = "jellyfin"
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    ocpus         = var.instance_ocpus
    memory_in_gbs = var.instance_memory_gb
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu_arm.images[0].id
    boot_volume_size_in_gbs = var.boot_volume_size_gb
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.jellyfin.id
    assign_public_ip = true
    display_name     = "jellyfin-vnic"
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
    user_data           = base64encode(file("${path.module}/cloud-init.yml"))
  }

  freeform_tags = {
    service = "jellyfin"
    managed = "terraform"
  }
}

# --- Block Volume (Media Storage — Always Free: 200 GB) ---

resource "oci_core_volume" "media" {
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name        = "jellyfin-media"
  size_in_gbs         = var.media_volume_size_gb

  freeform_tags = {
    service = "jellyfin"
    purpose = "media-storage"
    managed = "terraform"
  }
}

resource "oci_core_volume_attachment" "media" {
  attachment_type = "paravirtualized"
  instance_id     = oci_core_instance.jellyfin.id
  volume_id       = oci_core_volume.media.id
  display_name    = "jellyfin-media-attachment"
}
