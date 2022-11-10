# Proxmox

---

## File structure

```
.
├── cloud-init.md               Instructions to prepare a cloud-init template
├── install.sh                  Install script
├── mempoule-helper.sh          Command reminder placed in /usr/bin
├── README.md                   
├── template_gen.sh             Template creation script (Adapt it!)
├── ZFS.md                      Installation steps on rescue mode
```

---

## Web Auto Install

- The install script should be ran as priviledged user

>Note : The installer is supposed to be ran **once**

    curl -sf -L https://raw.githubusercontent.com/mempoule/toolbox/main/infra/proxmox/install.sh | sudo bash

---

## Manual Install

- The install script should be ran as priviledged user

>Note : The installer is supposed to be ran **once**

### 1) Create install.sh

Paste directly the content of [install.sh](install.sh) into `install.sh` file via vim/nano and save it.

### 2) Make it executable

`chmod +x install.sh`

### 3) Launch it as **priviledged user**

`sudo ./install.sh`

---

## Network configuration

### Proxmox Node

```auto lo
iface lo inet loopback

iface eno1 inet manual

auto vmbr0
iface vmbr0 inet static
        address XXX.XXX.XXX.XXX/24
        gateway XXX.XXX.XXX.254
        bridge-ports eno1
        bridge-stp off
        bridge-fd 0
        hwaddress XX:XX:XX:XX:XX:XX
```

---

### VM's

#### IPV4 default netplan - DHCP

```sudo vi /etc/netplan/config.yaml```


    network:
      version: 2
      renderer: networkd
      ethernets:
        ens18:
          dhcp4: true

#### IPV4 default netplan - static

```sudo vi /etc/netplan/config.yaml```

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

