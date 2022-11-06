# ZFS Proxmox Instructions

---
## Prerequisites

 - [x] VT-x cpu
 - [x] IP Failover compatible (SoYouStart minimum)

---

## Installation 

### 1. Preparation

 - [OVH](https://www.ovhcloud.com) &rarr; Bare Metal Cloud &rarr; nsXXXXXX
 - Disable Monitoring
 - Boot in Rescue Mode
 - Reboot the Server
 - Get SSH [credentials](https://www.ovh.com/manager/#/dedicated/useraccount/emails)

---

### II - Rescue Mode - Info gathering

- Connect to the node via SSH
- Confirm VT-x compatibility 
  
      lscpu | grep Virtualization
   
   >*root@rescue:~# lscpu | grep Virtualization  
   >Virtualization: **VT-x***

  
- Verify nested virt is activated
   
      cat /sys/module/kvm_intel/parameters/nested

   >*root@rescue:~# cat /sys/module/kvm_intel/parameters/nested*  
   >**Y**

- *Optional* - Activate nested virt

       modprobe -r kvm_intel  
       modprobe kvm_intel nested=1

- Get list of disks
  
      lsscsi -s

  >*root@rescue:~# lsscsi -s  
  >[0:0:0:0]    disk    ATA      INTEL SSDSC2KB48 0150*  **/dev/sda**    *480GB  
  >[1:0:0:0]    disk    ATA      INTEL SSDSC2KB48 0150*  **/dev/sdb**    *480GB*


- Get NIC name and **HW_Address**

      ip link | grep eth[0-9] -A1

  >*root@rescue:~# ip link | grep eth[0-9]  
  >6:* **eth0**: *<BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP mode DEFAULT group default qlen 1000*  
  >*link/ether* **{HW_Address}** *brd ff:ff:ff:ff:ff:ff*

 
- Get **IPv4_Address**

      ip -4 addr show eth0

  >*root@rescue:~# ip -4 addr show eth0  
  >6: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000  
  >inet* **{IPv4_Address}** *brd XXX.XXX.XXX.255 scope global eth0  
  >valid_lft forever preferred_lft forever*


- Get IPV4 **Default_Gateway**

      ip -4 route

  >*root@rescue:~# ip -4 route  
  >default via* **{Default_Gateway}** *dev eth0  
  >188.165.192.0/24 dev eth0  proto kernel  scope link  src {IPv4_Address}*

---

### III - Rescue Mode - Proxmox Install

- Reconnect with SSH tunnel on port 5900 (vnc)

      ssh -L5900:127.0.0.1:5900 root@{IPv4_Address}

- Download Proxmox ISO

      wget http://download.proxmox.com/iso/proxmox-ve_7.2-1.iso

- QEMU VM launch

      qemu-system-x86_64 -enable-kvm -vnc {IPv4_Address}:0,password=on -cpu host -smp 4 -net nic -net user -m 4096M -hda /dev/sda -hdb /dev/sdb --drive id=cdrom1,if=none,format=raw,readonly=on,file=proxmox-ve_7.2-1.iso -device virtio-scsi-pci,id=scsi0 -device scsi-cd,bus=scsi0.0,drive=cdrom1 -monitor stdio
      change vnc password

- Connect with VNC and begin the installation process, the only important point is to specify **valid DNS**.

- Once the installation process is finished, Proxmox will reboot, connect back with VNC and login

- Configure the NIC
  
      nano /etc/network/interfaces
 
  <!-- tsk -->

      iface lo inet loopback

      iface eno1 inet manual

      auto vmbr0
      iface vmbr0 inet static
              address {IPv4_Address}
              gateway {Default_Gateway}
              bridge-ports eno1
              bridge-stp off
              bridge-fd 0
              hwaddress {HW_Address}


- Save the network configuration
- Shutdown Proxmox
- Stop the QEMU
- Shutdown the rescue system
- Back to [OVH](https://www.ovh.com/manager/#/dedicated/server) server, change back the boot from `rescue` to `Hard Drive` then `reboot`

- Log in your proxmox server to check your network settings are OK : https://{IPv4_Address}:8006/
---

### III - Proxmox Configuration

- Log in via SSH


