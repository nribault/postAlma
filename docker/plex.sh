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
    ports:
      - 32400:32400
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
