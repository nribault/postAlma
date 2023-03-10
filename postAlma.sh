#!/bin/bash

# This script is called at the end of the AlmaLinux installation process.
# It principally updates the system and installs the necessary packages.
# It installs also Docker and Docker Compose and creates the minimal docker services.
# At the end, it hardens the system.

# Update the system

cat << EOF | sudo tee -a /etc/dnf/dnf.conf
fastestmirror=1
max_parallel_downloads=8
EOF

sudo dnf --refresh update -y
sudo dnf upgrade -y
sudo dnf autoremove -y

sudo dnf install -y epel-release
sudo dnf install -y vim bash-completion htop iotop iftop net-tools bind-utils ncdu
sudo dnf install -y langpacks-en glibc-all-langpacks  

sudo dnf clean all

# Add a tmpfs partition for /tmp
echo "tmpfs /tmp tmpfs defaults,nosuid,nodev,noexec,size=1g 0 0" | sudo tee -a /etc/fstab
sudo rm -fr /tmp/* && sudo mount /tmp

# Install Firewalld
sudo dnf install -y firewalld

sudo systemctl enable firewalld
sudo systemctl start firewalld

sudo firewall-cmd --permanent --zone=public --set-target=DROP
sudo firewall-cmd --permanent --zone=public --remove-service=cockpit
sudo firewall-cmd --reload

# Install CrowdSec
curl -s https://packagecloud.io/install/repositories/crowdsec/crowdsec/script.rpm.sh | sudo bash
sudo dnf install -y crowdsec
sudo systemctl enable --now crowdsec
sudo dnf install -y crowdsec-firewall-bouncer-nftables
sudo systemctl enable --now crowdsec-firewall-bouncer
sudo BOUNCER_CONFIG_PATH=/etc/crowdsec/bouncers/crowdsec-blocklist-mirror.yaml dnf install -y crowdsec-blocklist-mirror
sudo systemctl enable --now crowdsec-blocklist-mirror

sudo sed -i 's/  type: sqlite/  type: sqlite\n  use_wal: false/g' /etc/crowdsec/config.yaml
sudo systemctl restart crowdsec

# Create a new partition for docker
sudo lvcreate -y --wipesignatures y -n docker vg -l 100%VG
sudo mkfs.xfs /dev/vg/docker
cat << EOF | sudo tee -a /etc/fstab
/dev/vg/docker /var/lib/docker xfs rw,seclabel,relatime,attr2,inode64,logbufs=8,logbsize=32k,noquota,nodev,nosuid 0 0
EOF
sudo mkdir -p /var/lib/docker
sudo mount -a

# Install Docker
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io

mkdir -p /etc/docker

cat << EOF | sudo tee /etc/docker/daemon.json
{
  "data-root": "/var/lib/docker",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "exec-opts": ["native.cgroupdriver=systemd"],
}
EOF

sudo systemctl enable docker
sudo systemctl start docker

# Install Docker Compose
sudo dnf install -y python3-pip
sudo -H pip install --upgrade docker-compose

cat << EOF | sudo tee -a /etc/sudoers.d/custom_path
Defaults secure_path="/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin:/usr/local/sbin"
EOF

# Install Watchtower to update the containers

mkdir -p ~/docker/watchtower
cd ~/docker/watchtower

cat << EOF | tee docker-compose.yml
---
version: "3"
services:
  watchtower:
    image: containrrr/watchtower
    container_name: watchtower
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /etc/localtime:/etc/localtime:ro
    environment:
        - TZ=Europe/Paris
    command: --interval 14400 --cleanup --include-restarting --include-stopped
    restart: unless-stopped

EOF

sudo docker-compose up -d

# Write a message to the console to inform the user that the installation is complete
echo "Installation complete."