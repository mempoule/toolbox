# Proxmox

## Install

### 1) Clone or Create install.sh

Clone this repo and/or Paste directly the content of [install.sh](install.sh) into the install file and save it.

### 2) Make it executable

`chmod +x install.sh`

### 3) Launch it as priviledged user

`sudo ./install.sh`

## Template prep

    apt update && apt -y upgrade && apt -y autoremove && apt clean
    truncate -s0 /etc/hostname
    hostnamectl set-hostname localhost

## IPV4 default netplan

    network:
      version: 2
      renderer: networkd
      ethernets:
        ens18:
          dhcp4: true


