# AlmaLinux Post-Installation Script

## Introduction

postAlma is a bash script that automates various tasks to set up a secure and optimized system after a bare metal installation of AlmaLinux on OVH. The script is designed to be run immediately after the preliminary installation process is completed.

## Features

- Updates the system to the latest version
- Installs necessary packages, including `vim`, `htop`, `iotop`, `iftop`, `net-tools`, `bind-utils`, and `ncdu`
- Installs and configures firewalld for enhanced security
- Installs CrowdSec, a security tool that blocks malicious traffic in real-time
- Adds a `tmpfs` partition for `/tmp` to improve performance
- Installs Docker and Docker Compose to allow for containerized applications
- Hardens the system for improved security

## Requirements

- Access to the OVH portal for bare metal installations
- Adequate disk space available at the end of the preliminary installation process

## Usage

To run postAlma, simply enter the URL of the script in the "Script d'installation (url) :" field in the OVH portal during the bare metal installation process. The URL for the script is:

```bash
https://raw.githubusercontent.com/nribault/postAlma/main/postAlma.sh
```

Once the installation process is completed and the system has been rebooted, the script will automatically run and perform the necessary tasks. The installation process will conclude with a message on the console informing you that the installation is complete.

## Conclusion

postAlma streamlines the process of setting up a secure and optimized system after a bare metal installation of AlmaLinux on OVH. By automating various tasks, postAlma saves time and effort compared to manually configuring the system. Try it out today to take advantage of its features!
