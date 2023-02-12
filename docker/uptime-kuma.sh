# Uptime-Kuma

mkdir -p ~/docker/uptime-kuma/

sudo docker volume create uptime-kuma

cd ~/docker/uptime-kuma/

cat << EOF | tee docker-compose.yml
---
version: "2"

services:
  uptime-kuma:
    image: louislam/uptime-kuma:latest
    container_name: uptime-kuma
    environment:
      - TZ=Europe/Paris
    volumes:
      - uptime-kuma:/app/data
      - /var/run/docker.sock:/var/run/docker.sock:ro
    restart: unless-stopped

volumes:
    uptime-kuma:
        external: true

networks:
  default:
    external:
      name: cloudflare
EOF

sudo docker-compose up -d && sudo docker-compose logs -f
