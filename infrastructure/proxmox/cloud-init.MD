# Cloud-init template prep

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
    qm set -boot c -bootdisk scsi0
    qm set 9000 --boot c --bootdisk scsi0
    qm set 9000 --serial0 socket --vga serial0
    qm set 9000 --scsi0 local:9000/vm-9000-disk-0.raw,cache=writethrough,ssd=1
    qm set 9000 --ipconfig0 ip=dhcp
    qm set 9000 --ciuser poulinit
    qm set 9000 --cipassword zesecurepassword
    qm template 9000
    

## Create the template

**DO NOT START THE MACHINE**

    qm template 9000