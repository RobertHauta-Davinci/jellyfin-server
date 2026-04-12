# Remote Access Setup

This guide covers exposing your Jellyfin server securely to the internet.

## Overview

**Never expose Jellyfin directly to the internet.** Always use a reverse proxy that handles TLS termination and security headers.

## Option 1: Caddy (Recommended for Simplicity)

Caddy provides automatic HTTPS via Let's Encrypt with minimal configuration.

### Caddyfile

```
jellyfin.yourdomain.com {
    reverse_proxy localhost:8096
}
```

That's it. Caddy handles SSL certificates, renewal, and secure defaults automatically.

### Docker Compose Addition

```yaml
services:
  caddy:
    image: caddy:2
    container_name: caddy
    ports:
      - "80:80"
      - "443:443"
      - "443:443/udp"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
      - caddy_config:/config
    restart: unless-stopped

volumes:
  caddy_data:
  caddy_config:
```

## Option 2: Nginx (More Control)

### Nginx Configuration

```nginx
# Strip API keys from access logs
log_format stripsecrets '$remote_addr $host - $remote_user [$time_local] '
                        '"$secretfilter" $status $body_bytes_sent '
                        '"$http_referer" "$http_user_agent"';

map $request $secretfilter {
    ~*^(?<prefix1>.*[\?&]api_key=)([^&]*)(?<suffix1>.*)$  "${prefix1}***$suffix1";
    ~*^(?<prefix1>.*[\?&]ApiKey=)([^&]*)(?<suffix1>.*)$  "${prefix1}***$suffix1";
    default                                               $request;
}

server {
    listen 443 ssl http2;
    server_name jellyfin.yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;
    ssl_protocols TLSv1.3 TLSv1.2;

    client_max_body_size 20M;

    # Security headers
    add_header Strict-Transport-Security "max-age=63072000" always;
    add_header X-Content-Type-Options "nosniff";
    add_header Content-Security-Policy "default-src https: data: blob:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline' https://www.gstatic.com blob:; worker-src 'self' blob:; connect-src 'self'; object-src 'none'; font-src 'self'";

    access_log /var/log/nginx/jellyfin.access.log stripsecrets;

    location / {
        proxy_pass http://127.0.0.1:8096;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $http_host;
        proxy_buffering off;
    }

    # WebSocket support for Jellyfin
    location /socket {
        proxy_pass http://127.0.0.1:8096;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $http_host;
    }
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name jellyfin.yourdomain.com;
    return 301 https://$host$request_uri;
}
```

## Network Configuration

### Port Forwarding

Forward these ports on your router to the server running the reverse proxy:
- **80/tcp** — HTTP (for Let's Encrypt challenges and HTTPS redirect)
- **443/tcp** — HTTPS

Do **not** forward port 8096 directly.

### Dynamic DNS (DDNS)

If you don't have a static IP, use a DDNS service:
- [DuckDNS](https://www.duckdns.org/) (free)
- [Cloudflare DDNS](https://github.com/favonia/cloudflare-ddns) (free with Cloudflare DNS)
- Most router firmware has built-in DDNS support

> **Warning:** Do not enable Cloudflare's proxy (orange cloud) for video streaming — this may violate their Terms of Service for large media content. Use DNS-only mode.

### Jellyfin Network Settings

After setting up the reverse proxy:
1. Go to **Dashboard > Networking**
2. Add your reverse proxy's IP to **Known Proxies** (e.g., `172.17.0.1` for Docker bridge)
3. This ensures Jellyfin correctly reads client IPs from `X-Forwarded-For` headers

## Security Hardening

### Fail2Ban (Optional)

Protect against brute-force login attempts:

```ini
# /etc/fail2ban/jail.d/jellyfin.conf
[jellyfin]
enabled = true
port = http,https
filter = jellyfin
logpath = /path/to/jellyfin/config/log/log_*.log
maxretry = 5
bantime = 3600
findtime = 600
```

```ini
# /etc/fail2ban/filter.d/jellyfin.conf
[Definition]
failregex = ^.*Authentication request for .* has been denied \(IP: "<ADDR>"\)\.
```

### Additional Recommendations

- Keep Jellyfin and the reverse proxy updated
- Use strong passwords for all Jellyfin accounts
- Disable unused features (DLNA, remote control if not needed)
- Monitor access logs for unusual activity
- Consider a VPN (WireGuard/Tailscale) as an alternative to public exposure
