# CloudFlare Tunnel

mkdir -p ~/docker/cloudflared
cd ~/docker/cloudflared

sudo docker network create -d bridge cloudflare

cat << EOF | tee docker-compose.yml
---
version: "3.9"
services:
  tunnel:
    container_name: cloudflared-tunnel
    image: cloudflare/cloudflared
    restart: unless-stopped
    command: tunnel run
    environment:
      - TUNNEL_TOKEN=<token>
    cap_drop:
      - ALL

networks:
  default:
    external:
      name: cloudflare
EOF

sudo docker-compose up -d && sudo docker-compose logs -f