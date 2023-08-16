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

# Install Portainer
docker volume create portainer_data
docker run -d -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ee:latest

# Reboot
systemctl reboot
