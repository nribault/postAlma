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

# Create a new partition for docker
sudo lvcreate --wipesignatures y -n docker vg -l 100%VG
sudo mkfs.xfs /dev/vg/docker
cat << EOF | sudo tee -a /etc/fstab
/dev/vg/docker /var/lib/docker xfs rw,seclabel,relatime,attr2,inode64,logbufs=8,logbsize=32k,noquota,nodev,nosuid 0 0
EOF
sudo mkdir -p /var/lib/docker
sudo mount -a

# Add Doceker repository
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Install Docker
sudo dnf install -y docker-ce docker-ce-cli containerd.io

# Add the current user to the docker group
sudo usermod -aG docker $USER

# Start Docker
sudo systemctl enable docker
sudo systemctl start docker

# Install Docker Compose
pip install --upgrade docker-compose

# Allow docker network to access the internet
sudo firewall-cmd --zone=docker --add-masquerade --permanent
sudo firewall-cmd --reload
