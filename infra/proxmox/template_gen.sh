#!/bin/bash

echo "Autotemplate script start."

existing_flag=$(qm list | grep -c " 9000 ")

if [ "${existing_flag}" != "0" ]
then
   echo "Potential VM ID already used, aborting"
   exit
fi


echo "Enter user name : "
read -r username
echo "Enter password : "
read -rs password

if ! [[ "${username}" =~ [^[:alnum:]]+ ]] && ! [[ ${password} =~ " " ]]
then
  echo "Username and password valid, creating the template..."
else
  echo "Must provide a valid user / password"
  exit
fi

wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img -O /var/lib/vz/template/iso/jammy-server-cloudimg-amd64.img

qm create 9000 --memory 2048 --name ubuntu-cloud --net0 virtio,bridge=vmbr1
qm importdisk 9000 /var/lib/vz/template/iso/jammy-server-cloudimg-amd64.img local
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local:9000/vm-9000-disk-0.raw
qm set 9000 --ide2 local:cloudinit
qm set 9000 --boot c -bootdisk scsi0
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --serial0 socket --vga serial0
qm set 9000 --scsi0 local:9000/vm-9000-disk-0.raw,cache=writethrough,ssd=1
qm set 9000 --ipconfig0 ip=dhcp
qm set 9000 --ciuser ${username}
qm set 9000 --cipassword ${password}
qm set 9000 --agent enabled=1

keylist=$(curl -s https://github.com/mempoule.keys)
while IFS= read -r key
do
  echo "$key" >> /tmp/keys_to_add.pub
done <<< "$keylist"

qm set 9000 --sshkey /tmp/keys_to_add.pub
rm /tmp/keys_to_add.pub

qm template 9000

echo "Template available, exiting."
