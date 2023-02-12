# Plex

mkdir -p ~/docker/plex/config
cd ~/docker/plex/

sudo docker volume create --name=torrents

cat << EOF | tee docker-compose.yml
---
version: "2.1"
services:
  plex:
    image: lscr.io/linuxserver/plex:latest
    container_name: plex
    environment:
      - TZ=Europe/Paris
      - VERSION=docker
      - PLEX_CLAIM=<claim tocken>
    volumes:
      - ./config:/config
      - torrents:/torrents
    restart: unless-stopped

volumes:
    torrents:
        external: true

networks:
  default:
    external:
      name: cloudflare
EOF

sudo docker-compose up -d && sudo docker-compose logs -f

sudo firewall-cmd --zone=public --add-port=32400/tcp --permanent
sudo firewall-cmd --zone=public --add-port=32400/tcp
