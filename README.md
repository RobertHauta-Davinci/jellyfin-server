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

## Production Deployment

Use the production override file:

```bash
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

See `docker-compose.prod.yml` for PVC/Kubernetes volume configuration notes.

## Remote Access

See [docs/remote-access.md](docs/remote-access.md) for setting up remote access with a reverse proxy.
