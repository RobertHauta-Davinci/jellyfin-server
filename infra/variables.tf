variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key for server access"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "server_type" {
  description = "Hetzner server type (e.g., cx23, cx33, ccx13)"
  type        = string
  default     = "cx33"
}

variable "location" {
  description = "Hetzner data center location"
  type        = string
  default     = "fsn1" # Falkenstein, Germany
}
