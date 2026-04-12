# --- OCI Authentication ---

variable "tenancy_ocid" {
  description = "OCID of your OCI tenancy (found in OCI Console > Tenancy Details)"
  type        = string
}

variable "user_ocid" {
  description = "OCID of the OCI user (found in OCI Console > Profile > User Settings)"
  type        = string
}

variable "api_key_fingerprint" {
  description = "Fingerprint of the OCI API signing key"
  type        = string
}

variable "api_private_key_path" {
  description = "Path to OCI API signing private key (.pem file)"
  type        = string
  default     = "~/.oci/oci_api_key.pem"
}

variable "compartment_ocid" {
  description = "OCID of the compartment to deploy into (use tenancy OCID for root compartment)"
  type        = string
}

variable "region" {
  description = "OCI region (e.g., us-toronto-1, ca-montreal-1, us-ashburn-1)"
  type        = string
  default     = "ca-toronto-1"
}

# --- SSH ---

variable "ssh_public_key_path" {
  description = "Path to SSH public key for server access"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

# --- Instance ---

variable "instance_ocpus" {
  description = "Number of OCPUs for the ARM instance (free tier: up to 4)"
  type        = number
  default     = 4
}

variable "instance_memory_gb" {
  description = "Memory in GB for the ARM instance (free tier: up to 24)"
  type        = number
  default     = 24
}

variable "boot_volume_size_gb" {
  description = "Boot volume size in GB (free tier: up to 200 total across all instances)"
  type        = number
  default     = 50
}

# --- Storage ---

variable "media_volume_size_gb" {
  description = "Block volume size in GB for media storage (free tier: up to 200 total)"
  type        = number
  default     = 150
}
