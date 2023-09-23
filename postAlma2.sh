#!/bin/bash

### Installation des paquets
dnf install -y epel-release
dnf update -y
dnf install -y nano neovim vim bash-completion htop iotop iftop net-tools bind-utils ncdu
dnf install -y langpacks-en glibc-all-langpacks
dnf autoremove -y


### Ajouter une partition tmpfs
echo "tmpfs /tmp tmpfs defaults,nosuid,nodev,noexec,size=1g 0 0" | tee -a /etc/fstab
echo "tmpfs /var/tmp tmpfs defaults,nosuid,nodev,noexec,size=1g 0 0" | tee -a /etc/fstab
systemctl daemon-reload
rm -fr /tmp/* && mount /tmp
rm -fr /var/tmp/* && mount /var/tmp

### Ajout d'un fichier de swap
dd if=/dev/zero of=/swapfile bs=1M count=1024
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo "/swapfile swap swap defaults 0 0" | tee -a /etc/fstab
systemctl daemon-reload

## Activation de SELinux
sed -i 's/SELINUX=disabled/SELINUX=enforcing/g' /etc/selinux/config
sed -i 's/SELINUXTYPE=targeted/#SELINUXTYPE=targeted/g' /etc/selinux/config
setenforce 1

## Installer et activer Firewalld

dnf install -y firewalld
systemctl enable firewalld
systemctl start firewalld
firewall-cmd --permanent --zone=public --set-target=DROP
firewall-cmd --permanent --zone=public --remove-service=cockpit
firewall-cmd --reload

## Install and configure Crowdsec
curl -s https://packagecloud.io/install/repositories/crowdsec/crowdsec/script.rpm.sh | bash
dnf install -y crowdsec
systemctl enable --now crowdsec
dnf install -y crowdsec-firewall-bouncer-nftables
systemctl enable --now crowdsec-firewall-bouncer
sed -i 's/  type: sqlite/  type: sqlite\n  use_wal: false/g' /etc/crowdsec/config.yaml
systemctl restart crowdsec

# Install Docker
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
systemctl enable docker.service
systemctl start docker.service
usermod -aG docker admin

# Install Portainer et Nginx Proxy Manager
docker volume create portainer_data
docker volume create npm_data
docker volume create npm_letsencrypt
docker volume create npm_db

docker network create npm

mkdir -p /root/portainer && cd /root/portainer

cat <<EOF > /root/portainer/docker-compose.yml
version: '3.8'
services:
  npm:
    image: 'jc21/nginx-proxy-manager:latest'
    container_name: npm
    restart: unless-stopped
    ports:
      - '80:80'
      - '443:443'
      - '81:81'
    environment:
      TZ: "Europe/Paris"
      X_FRAME_OPTIONS: "sameorigin"
      DB_MYSQL_HOST: "db"
      DB_MYSQL_PORT: 3306
      DB_MYSQL_USER: "\${MYSQL_USER}"
      DB_MYSQL_PASSWORD: "\${MYSQL_PASSWORD}"
      DB_MYSQL_NAME: "\${MYSQL_DATABASE}"
    volumes:
      - npm_data:/data
      - npm_letsencrypt:/etc/letsencrypt
    depends_on:
      - db
  db:
    image: 'jc21/mariadb-aria:latest'
    container_name: npm-db
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: "\${MYSQL_ROOT_PASSWORD}"
      MYSQL_DATABASE: "\${MYSQL_DATABASE}"
      MYSQL_USER: "\${MYSQL_USER}"
      MYSQL_PASSWORD: "\${MYSQL_PASSWORD}"
    volumes:
      - npm_db:/var/lib/mysql
  portainer:
    image: portainer/portainer-ee:latest
    container_name: portainer
    restart: always
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data

volumes:
  npm_data:
  npm_letsencrypt:
  npm_db:
  portainer_data:

networks:
  default:
    external: true
    name: npm
EOF

cat <<EOF > /root/portainer/.env
MYSQL_ROOT_PASSWORD=`openssl rand -base64 32 | sha256sum  | head -c 18 ; echo`
MYSQL_DATABASE=`openssl rand -base64 32 | sha256sum  | head -c 18 ; echo`
MYSQL_USER=`openssl rand -base64 32 | sha256sum  | head -c 18 ; echo`
MYSQL_PASSWORD=`openssl rand -base64 32 | sha256sum  | head -c 18 ; echo`
EOF

docker compose up -d

# Anonymise login messages
rm -f /etc/motd && touch /etc/motd
rm -f /etc/issue && touch /etc/issue
rm -f /etc/issue.net && touch /etc/issue.net
touch /root/.hushlogin
touch /home/admin/.hushlogin

# Reboot
systemctl reboot
