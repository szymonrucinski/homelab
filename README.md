# Homelab

Self-hosted homelab running on Docker Compose, organized into independent stacks for media automation, AI inference, photo management, and system monitoring. All services route through a WireGuard VPN gateway for privacy, with autoheal ensuring containers recover from failures automatically. Secrets are kept out of version control via `.env` files and a pre-commit hook that blocks accidental credential leaks. Three stacks leverage NVIDIA GPU acceleration for hardware transcoding, machine learning, and LLM inference. Run `./setup.sh` to initialize the repo, install git hooks, and scaffold `.env` files from the provided templates.

## Architecture

```mermaid
graph TB
    subgraph VPN["arr-stack (VPN Gateway)"]
        Gluetun["Gluetun<br/>WireGuard VPN"]
        Prowlarr["Prowlarr<br/>Indexer Manager"]
        Sonarr["Sonarr<br/>TV Shows"]
        Radarr["Radarr<br/>Movies"]
        Bazarr["Bazarr<br/>Subtitles"]
        qBit["qBittorrent<br/>Downloads"]
        Flare["FlareSolverr<br/>Captcha Bypass"]
        Jellyseerr["Jellyseerr<br/>Media Requests"]

        Gluetun --> Prowlarr
        Gluetun --> Sonarr
        Gluetun --> Radarr
        Gluetun --> Bazarr
        Gluetun --> qBit
        Gluetun --> Flare
        Prowlarr --> Sonarr
        Prowlarr --> Radarr
        Sonarr --> qBit
        Radarr --> qBit
    end

    subgraph Media["jellyfin"]
        Jellyfin["Jellyfin<br/>Media Server<br/>GPU"]
    end

    subgraph AutoColl["jellyfin-auto-collections"]
        JAC["Auto Collections<br/>Cron Job"]
    end

    subgraph AI["ai-stack"]
        Ollama["Ollama<br/>LLM Server<br/>GPU"]
        OpenWebUI["Open WebUI<br/>Chat Interface"]
        OpenWebUI --> Ollama
    end

    subgraph Photos["immich"]
        ImmichSrv["Immich Server"]
        ImmichML["Immich ML<br/>GPU"]
        Redis["Redis"]
        Postgres["PostgreSQL<br/>+ pgvecto.rs"]
        ImmichSrv --> Redis
        ImmichSrv --> Postgres
        ImmichML --> Redis
    end

    subgraph Monitoring["glances"]
        Glances["Glances<br/>System Monitor"]
    end

    subgraph Infra["Infrastructure"]
        Portainer["Portainer<br/>Container Management"]
        Autoheal["Autoheal<br/>Auto-Restart"]
    end

    Jellyseerr --> Jellyfin
    Jellyseerr --> Sonarr
    Jellyseerr --> Radarr
    JAC --> Jellyfin
    Sonarr --> Jellyfin
    Radarr --> Jellyfin
    Autoheal --> Gluetun
```

## Stacks

| Stack | Services | GPU | Description |
|-------|----------|-----|-------------|
| **arr-stack** | Gluetun, Prowlarr, Sonarr, Radarr, Bazarr, qBittorrent, FlareSolverr, Jellyseerr | - | Full media automation pipeline behind a WireGuard VPN. Prowlarr manages indexers, Sonarr/Radarr grab content, qBittorrent downloads, and Bazarr fetches subtitles. |
| **jellyfin** | Jellyfin | NVIDIA | Media server with NVIDIA GPU hardware transcoding for smooth playback across devices. |
| **jellyfin-auto-collections** | Auto Collections | - | Cron job that automatically organizes Jellyfin libraries into curated collections daily at 4 AM. |
| **ai-stack** | Ollama, Open WebUI | NVIDIA | Local LLM inference with full GPU passthrough. Open WebUI provides a ChatGPT-like interface on top of Ollama. |
| **immich** | Immich Server, Immich ML, Redis, PostgreSQL | NVIDIA | Self-hosted Google Photos alternative. The ML service uses CUDA for face recognition, object detection, and smart search. |
| **glances** | Glances | - | Lightweight system monitoring dashboard with Docker container visibility. |
| **portainer** | Portainer CE | - | Web-based Docker management UI exposed on ports 9000/9443. |
| **autoheal** | Autoheal | - | Monitors containers with the `autoheal-app` label and restarts them if health checks fail. |

## Quick Start

```bash
git clone git@github.com:szymonrucinski/homelab.git
cd homelab
chmod +x setup.sh && ./setup.sh
# Edit each stack's .env file with your values, then:
cd arr-stack && docker compose up -d
```
