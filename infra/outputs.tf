output "server_ip" {
  description = "Public IP address of the Jellyfin server"
  value       = oci_core_instance.jellyfin.public_ip
}

output "server_status" {
  description = "Current instance lifecycle state"
  value       = oci_core_instance.jellyfin.state
}

output "ssh_command" {
  description = "SSH command to connect to the server"
  value       = "ssh ubuntu@${oci_core_instance.jellyfin.public_ip}"
}

output "media_volume_id" {
  description = "OCID of the media block volume (persists independently of the instance)"
  value       = oci_core_volume.media.id
}
