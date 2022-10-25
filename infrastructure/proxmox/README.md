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

## IPV4 default netplan - DHCP

    network:
      version: 2
      renderer: networkd
      ethernets:
        ens18:
          dhcp4: true

## IPV4 default netplan - static
    network:
      version: 2
      renderer: networkd
      ethernets:
        ens18:
          dhcp4: no
          addresses: [XX.XX.X.X/24]
          gateway4: X.X.X.254
          nameservers:
            addresses: [1.1.1.1, 1.0.0.1]

