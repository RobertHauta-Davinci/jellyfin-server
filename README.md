# Jellyfin Media Server

Personal Jellyfin instance for streaming movies and media on any device.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and Docker Compose v2+
- WSL2 (for Windows development) with Docker Desktop or Docker Engine inside WSL

## Quick Start

1. **Clone the repo:**
   ```bash
   git clone git@github.com:RobertHauta-Davinci/jellyfin-server.git
   cd jellyfin-server
   ```

2. **Create your environment file:**
   ```bash
   cp .env.example .env
   ```

3. **Start the server:**
   ```bash
   docker compose up -d
   ```

4. **Open Jellyfin:** Navigate to [http://localhost:8096](http://localhost:8096) and complete the setup wizard.

5. **Stop the server:**
   ```bash
   docker compose down
   ```

## Uploading Media

Media is stored in a Docker volume (`jellyfin-media`). To add files:

```bash
# Copy a movie into the volume
docker compose cp "/path/to/Movie Name (2024)/Movie Name (2024).mkv" jellyfin:/media/movies/

# Or use a helper container to manage the volume directly
docker run --rm -v jellyfin-media:/media -v /path/to/local/files:/source alpine \
  cp -r /source/. /media/movies/
```

### Media Naming Conventions

Jellyfin relies on folder and file naming to fetch metadata correctly.

**Movies:**
```
/media/movies/
  Movie Name (Year)/
    Movie Name (Year).mkv
```

**TV Shows:**
```
/media/tv/
  Show Name/
    Season 01/
      Show Name S01E01.mkv
      Show Name S01E02.mkv
```

**Music:**
```
/media/music/
  Artist Name/
    Album Name/
      01 - Track Title.flac
```

Always include the year in movie folder names to avoid incorrect metadata matches.

## Hardware Transcoding (Intel Quick Sync)

This setup passes `/dev/dri` into the container for Intel QSV hardware transcoding.

**To enable in Jellyfin:**
1. Go to **Dashboard > Playback > Transcoding**
2. Set **Hardware acceleration** to `Intel QuickSync (QSV)`
3. Enable the codecs you want to accelerate (H.264, HEVC, etc.)

**Verify the device is accessible:**
```bash
docker compose exec jellyfin ls -la /dev/dri
```

> **Note:** Hardware transcoding via Docker is only supported on Linux hosts. On Windows, Docker Desktop runs inside a VM and cannot pass through the GPU. For WSL2 development, transcoding falls back to software mode unless you configure GPU passthrough in WSL.

## Cloud Deployment (Hetzner)

The production setup runs on a Hetzner Cloud CX33 VM with a Storage Box for media.

### Architecture

```
[Hetzner CX33 VM]
├── Caddy (reverse proxy, auto-HTTPS)
├── Jellyfin (Docker container)
├── /opt/jellyfin/config/   → Local NVMe SSD
├── /opt/jellyfin/cache/    → Local NVMe SSD
└── /mnt/media/             → Hetzner Storage Box (SMB mount, read-only)
```

### Initial Setup

1. **Prerequisites:**
   - Hetzner Cloud account + API token
   - Hetzner Storage Box (BX11 or larger)
   - Domain name with DNS pointed to your server
   - Terraform installed locally

2. **Provision the server:**
   ```bash
   cd infra
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your Hetzner API token and SSH key path
   terraform init
   terraform apply
   ```

3. **Configure Storage Box mount** on the server (SSH in and set up `/etc/fstab`).

4. **Deploy Jellyfin:**
   ```bash
   ssh jellyfin@<server-ip>
   cd /opt/jellyfin
   cp .env.example .env
   # Edit .env with your domain
   docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
   ```

5. **Set up GitHub Secrets** for CI/CD (see below).

### CI/CD

Pushes to `main` auto-deploy via GitHub Actions.

**Required GitHub Secrets:**
- `HCLOUD_TOKEN` — Hetzner API token
- `SSH_PRIVATE_KEY` — SSH key for server access
- `SERVER_IP` — Hetzner VM IP

**Required GitHub Variables:**
- `DOMAIN` — your domain (e.g., `media.yourdomain.com`)
- `SERVER_USER` — SSH user (default: `jellyfin`)

### Pre-Transcoding

To avoid expensive cloud transcoding, pre-transcode media locally before uploading:

```bash
# Transcode a movie to H.264 MP4 (uses Intel QSV if available)
./scripts/transcode.sh "input.mkv" "./output/"

# Upload to Storage Box
./scripts/upload.sh "./output/Movie Name (2024)" movies
```

### Backups

Config is backed up daily to the Storage Box:

```bash
./scripts/backup.sh
```

### Estimated Monthly Cost

| Resource | Cost |
|----------|------|
| Hetzner CX33 (4 vCPU, 8 GB RAM) | ~EUR 6.49 |
| Hetzner Storage Box BX11 (1 TB) | ~EUR 3.20 |
| **Total** | **~EUR 10/mo (~$15 CAD)** |

## Security

- HTTPS enforced via Caddy with automatic Let's Encrypt certificates
- Hetzner firewall blocks all ports except 22, 80, 443
- SSH key-only authentication (password auth disabled)
- Fail2Ban protects against brute-force login attempts
- Media mounted read-only in the container
- See [docs/remote-access.md](docs/remote-access.md) for additional hardening options

## Remote Access

See [docs/remote-access.md](docs/remote-access.md) for reverse proxy details, DDNS, and Fail2Ban configuration.
