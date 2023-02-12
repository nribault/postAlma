# Transmission BT

mkdir -p ~/docker/transmission/config
mkdir -p ~/docker/transmission/watch

sudo docker volume create --name=torrents

cd ~/docker/transmission

cat << EOF | tee docker-compose.yml
---
version: "2.1"

services:
  transmission:
    image: lscr.io/linuxserver/transmission:latest
    container_name: transmission
    environment:
      - TZ=Europe/Paris
      - USER=<user>
      - PASS=<pass>
      - PEERPORT=51413
    volumes:
      - ./config:/config
      - ./watch:/watch
      - torrents:/downloads
    ports:
      - 51413:51413
      - 51413:51413/udp
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
