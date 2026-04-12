output "server_ip" {
  description = "Public IPv4 address of the Jellyfin server"
  value       = hcloud_server.jellyfin.ipv4_address
}

output "server_status" {
  description = "Current server status"
  value       = hcloud_server.jellyfin.status
}

output "ssh_command" {
  description = "SSH command to connect to the server"
  value       = "ssh jellyfin@${hcloud_server.jellyfin.ipv4_address}"
}
