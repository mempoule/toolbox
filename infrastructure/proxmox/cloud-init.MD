# Cloud-init template prep

Alternatively, you can just use [template_gen.sh](template_gen.sh), **don't forget it to adapt it ! and use your set of keys**

## Useful commands

```pvesm status```

Will show the storage name, to be used in `qm importdisk`

*qm importdisk 9000 /var/lib/vz/template/iso/jammy-server-cloudimg-amd64.img* **local**

---

```pvesm list local```

Will show the exact disk location for `qm set`

*qm set 9000 --scsihw virtio-scsi-pci --scsi0* **local:9000/vm-9000-disk-0.raw**

---

## Create the VM

    qm create 9000 --memory 2048 --name ubuntu-cloud --net0 virtio,bridge=vmbr1
    qm importdisk 9000 /var/lib/vz/template/iso/jammy-server-cloudimg-amd64.img local
    qm set 9000 --scsihw virtio-scsi-pci --scsi0 local:9000/vm-9000-disk-0.raw

## Cloudinit conf

    qm set 9000 --ide2 local:cloudinit
    qm set 9000 --boot c -bootdisk scsi0
    qm set 9000 --boot c --bootdisk scsi0
    qm set 9000 --serial0 socket --vga serial0
    qm set 9000 --scsi0 local:9000/vm-9000-disk-0.raw,cache=writethrough,ssd=1
    qm set 9000 --ipconfig0 ip=dhcp
    qm set 9000 --ciuser poulinit
    qm set 9000 --cipassword zesecurepassword
    qm set 9000 --agent enabled=1
    qm template 9000
    

## Create the template

**DO NOT START THE MACHINE**

    qm template 9000

# Template cloning into VM

    qm clone 9000 500 --name datcoolname --full

# Useful commands

    qm resize 500 scsi0 +15G
    cat /etc/pve/qemu-server/110.conf | grep net

