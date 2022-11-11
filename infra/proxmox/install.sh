#!/bin/bash

########################################################################
#     Priviledged user check
########################################################################

echo "$TIMESTAMP - Priviledged user check" | tee $LOGFILE

if [[ $EUID -eq 0 ]] || [[ -z ${SUDO_USER// } ]]
then
  echo "$TIMESTAMP - Not priviledged user, aborting." | tee $LOGFILE
  exit
else

########################################################################
#     vars
########################################################################

LOGFILE="/var/log/mempoule-install.log"
TIMESTAMP=`date "+%Y-%m-%d %H:%M:%S"`

########################################################################
#     LOGFILE check
########################################################################

if [[ -f $LOGFILE ]]
then
  echo "$LOGFILE file found. Aborting"
  exit
fi

priviledged_user="mempoule"
github_name="mempoule"

ssh_client=$(who am i|cut -d"(" -f2 |cut -d")" -f1)
if [[ $(pvesm status | grep -c zfs) -eq 1 ]]
then
  local_storage=$(pvesm status | grep zfspool | cut -d " " -f1)
  is_zfs=1
else
  local_storage=$(pvesm status | grep "local.*.dir" | cut -d " " -f1)
  is_zfs=0
fi
distribution_version=$(grep 'VERSION_CODENAME=' /etc/os-release | cut -d "=" -f2)


########################################################################
#     sources.list
########################################################################

echo "$TIMESTAMP - START - sources.list update" | tee -a $LOGFILE

sed -i 's/^[:alnum]/# /' /etc/apt/sources.list.d/pve-enterprise.list

if [[ $(grep -c download.proxmox.com /etc/apt/sources.list) -eq 0 ]]
then
  echo "Adding nosubscription pve sources.list for ${distribution_version}"
  {
    echo -e "\n# PVE pve-no-subscription repository provided by proxmox.com,"
    echo "# NOT recommended for production use" >> /etc/apt/sources.list
    echo "deb http://download.proxmox.com/debian/pve $(cat /etc/*-release | grep ^VERSION= | cut -d '(' -f2 | cut -d ')' -f1) pve-no-subscription"
  } >> /etc/apt/sources.list
else
  echo "nosubscription pve sources.list already present for ${distribution_version}"
fi

echo "$TIMESTAMP - DONE  - sources.list update" | tee -a $LOGFILE

########################################################################
#     update packages list
########################################################################

echo "$TIMESTAMP - START - update packages list" | tee -a $LOGFILE

apt-get update &> /dev/null
apt-get full-upgrade -y &> /dev/null
echo "Packages updated successfully"

echo "$TIMESTAMP - DONE  - update packages list" | tee -a $LOGFILE


########################################################################
#     install new packages
########################################################################

echo "$TIMESTAMP - START - install new packages" | tee -a $LOGFILE

apt-get install curl unzip wget fail2ban htop sudo vim ifupdown2 net-tools conntrack tree screen qrencode msmtp mutt -y &> /dev/null

echo "$TIMESTAMP - DONE  - install new packages" | tee -a $LOGFILE

########################################################################
#     new user
########################################################################

echo "$TIMESTAMP - START - new user" | tee -a $LOGFILE

if ! [[ -d /home/${priviledged_user} ]]
then
  echo -e "User : ${priviledged_user} non-existent, creating...\n"
  echo "Enter password for new user ${priviledged_user}: "
  read -sr password
  if ! [[ ${password} =~ " " ]]
  then
    pass=$(perl -e 'print crypt($ARGV[0], "password")' "${password}")
    useradd -m -p "${pass}" ${priviledged_user} --shell /bin/bash
    echo "${priviledged_user} successfully created "
  else
    echo "Must provide a valid user / password, exiting"
    exit
  fi
else
  echo "$TIMESTAMP - INFO  - ${priviledged_user} already created" | tee -a $LOGFILE
  echo "Enter password of existing user ${priviledged_user}: "
  read -sr password
  if  [[ ${password} =~ " " ]]
    echo "Must provide a valid user / password, exiting"
    exit
  fi
fi
usermod -aG sudo ${priviledged_user}
# Prereq for nicreporting alias
usermod -aG www-data ${priviledged_user}

echo "$TIMESTAMP - DONE  - new user" | tee -a $LOGFILE

########################################################################
#     IPv6 stop
########################################################################

echo "$TIMESTAMP - START - IPv6 stop" | tee -a $LOGFILE
{
  echo "net.ipv6.conf.all.disable_ipv6 = 1"
  echo "net.ipv6.conf.all.disable_ipv6 = 1"
  echo "net.ipv6.conf.lo.disable_ipv6 = 1"
} >> /etc/sysctl.conf
sysctl -p
echo "IPv6 is now disabled"

echo "$TIMESTAMP - DONE  - IPv6 stop" | tee -a $LOGFILE


########################################################################
#     fail2ban
########################################################################

echo "$TIMESTAMP - START - fail2ban config" | tee -a $LOGFILE

awk '{ printf "# "; print; }' /etc/fail2ban/fail2ban.conf | tee /etc/fail2ban/jail.local &> /dev/null
echo "[DEFAULT]" >> /etc/fail2ban/jail.local
echo "ignoreip = ${ssh_client}" >> /etc/fail2ban/jail.local

echo "$TIMESTAMP - DONE  - fail2ban config" | tee -a $LOGFILE


########################################################################
#     sshd
########################################################################

echo "$TIMESTAMP - START - sshd config" | tee -a $LOGFILE

sed -i '/^PermitRootLogin/c\PermitRootLogin no' /etc/ssh/sshd_config
sed -i '/^#PermitRootLogin/c\PermitRootLogin no' /etc/ssh/sshd_config
sed -i '/^#PasswordAuthentication/c\PasswordAuthentication no' /etc/ssh/sshd_config
sed -i '/^PasswordAuthentication/c\PasswordAuthentication no' /etc/ssh/sshd_config

echo "$TIMESTAMP - DONE  - sshd config" | tee -a $LOGFILE


########################################################################
#     bashrc
########################################################################

echo "$TIMESTAMP - START - bashrc tweaks" | tee -a $LOGFILE

{
  echo "export EDITOR=vim"
  echo -e "alias ll='ls -alF'"
  echo -e "alias iptables='/sbin/iptables'"
  echo -e "alias ifconfig='/sbin/ifconfig'"
} >> /root/.bashrc

{
  echo "export EDITOR=vim"
  echo -e "alias ll='ls -alF'"
  echo -e "alias iptables='/sbin/iptables'"
  echo -e "alias ifconfig='/sbin/ifconfig'"
} >> /home/${priviledged_user}/.bashrc

echo "$TIMESTAMP - DONE  - bashrc tweaks" | tee -a $LOGFILE


########################################################################
#     vimrc
########################################################################

echo "$TIMESTAMP - START - vimrc tweaks" | tee -a $LOGFILE

{
  echo "set nocompatible"
  echo "set mouse-=a"
  echo "set nocompatible"
  echo "set mouse-=a"
  echo "syntax on"
} >> /root/.vimrc

{
  echo "set nocompatible"
  echo "set mouse-=a"
  echo "set nocompatible"
  echo "set mouse-=a"
  echo "syntax on"
} >> /home/${priviledged_user}/.vimrc

echo "$TIMESTAMP - DONE  - vimrc tweaks" | tee -a $LOGFILE


########################################################################
#     nicreport
########################################################################

echo "$TIMESTAMP - START - vimrc tweaks" | tee -a $LOGFILE

echo "alias nicreport='for i in /etc/pve/qemu-server/*.conf; do echo \"\$i\"|rev|cut -d \"/\" -f1|rev;cat \$i | grep ^net;echo \"\"; done'" >> /home/${priviledged_user}/.bashrc
echo "alias nicreport='for i in /etc/pve/qemu-server/*.conf; do echo \"\$i\"|rev|cut -d \"/\" -f1|rev;cat \$i | grep ^net;echo \"\"; done'" >> /root/.bashrc

echo "$TIMESTAMP - DONE - vimrc tweaks" | tee -a $LOGFILE

########################################################################
#     priviledged user to PAM
########################################################################

echo "$TIMESTAMP - START - priviledged user to PAM" | tee -a $LOGFILE

/sbin/pveum user add ${priviledged_user}@pam
/sbin/pveum acl modify / --roles Administrator --users ${priviledged_user}@pam

echo "$TIMESTAMP - DONE  - priviledged user to PAM" | tee -a $LOGFILE


########################################################################
#     Basic iptables rules
########################################################################

echo "$TIMESTAMP - START - Basic iptables rules" | tee -a $LOGFILE

service fail2ban stop
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 8006 -j ACCEPT
iptables -A INPUT -p tcp --dport 3128 -j ACCEPT
iptables -A INPUT -p udp --dport 5404:5405 -j ACCEPT
iptables -A INPUT -p tcp --dport 60000:60050 -j ACCEPT
iptables -A INPUT -j DROP

echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
apt-get -y install iptables-persistent &> /dev/null

echo "$TIMESTAMP - DONE  - Basic iptables rules" | tee -a $LOGFILE

########################################################################
#     SSH key add
########################################################################

echo "$TIMESTAMP - START - SSH key add" | tee -a $LOGFILE

mkdir /home/${priviledged_user}/.ssh 2>/dev/null
chmod 700 /home/${priviledged_user}/.ssh 2>/dev/null
keylist=$(curl -s https://github.com/${github_name}.keys)
keylist_count=0

if [[ $keylist =~ *ssh-rsa* ]]
then
  while IFS= read -r key
  do
    echo "$key" >> /home/${priviledged_user}/.ssh/authorized_keys
    echo "$key" >> /tmp/keys_to_add.pub
    keylist_count=$((keylist_count+1))
  done <<< "$keylist"
  chmod 600 /home/${priviledged_user}/.ssh/authorized_keys
  chown -R ${priviledged_user}:${priviledged_user} /home/${priviledged_user}/.ssh
fi

echo "$TIMESTAMP - DONE  - SSH key add" | tee -a $LOGFILE


########################################################################
#     Stopping and masking systemd-networkd-wait-online
########################################################################

echo "$TIMESTAMP - START - Stopping and masking systemd-networkd-wait-online" | tee -a $LOGFILE

systemctl disable systemd-networkd-wait-online.service
systemctl mask systemd-networkd-wait-online.service

echo "$TIMESTAMP - DONE  - Stopping and masking systemd-networkd-wait-online" | tee -a $LOGFILE


########################################################################
#     Basic ISO get
########################################################################

echo "$TIMESTAMP - START - Basic ISO get" | tee -a $LOGFILE

wget -N https://old-releases.ubuntu.com/releases/18.04.5/ubuntu-18.04.5-live-server-amd64.iso -P /var/lib/vz/template/iso/
wget -N https://releases.ubuntu.com/focal/ubuntu-20.04.5-live-server-amd64.iso -P /var/lib/vz/template/iso/
wget -N https://releases.ubuntu.com/22.04/ubuntu-22.04.1-live-server-amd64.iso -P /var/lib/vz/template/iso/
wget -N https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img -P /var/lib/vz/template/iso/
wget -N https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img -P /var/lib/vz/template/iso/
wget -N https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img -P /var/lib/vz/template/iso/
wget -N https://cloud.debian.org/images/cloud/bullseye/latest/debian-11-genericcloud-amd64.qcow2
wget -N https://releases.ubuntu.com/22.10/ubuntu-22.10-desktop-amd64.iso /var/lib/vz/template/iso/

wget -N https://frafiles.netgate.com/mirror/downloads/pfSense-CE-2.6.0-RELEASE-amd64.iso.gz -P /var/lib/vz/template/iso/
gunzip -f /var/lib/vz/template/iso/pfSense-CE-2.6.0-RELEASE-amd64.iso.gz
rm /var/lib/vz/template/iso/pfSense-CE-2.6.0-RELEASE-amd64.iso.gz

echo "$TIMESTAMP - DONE - Basic ISO get" | tee -a $LOGFILE


########################################################################
#     VMBR autocreate
########################################################################

echo "$TIMESTAMP - START - VMBR autocreate" | tee -a $LOGFILE

for vmbr_id in {1..5}
do
  if [[ $(grep -c "vmbr${vmbr_id}" /etc/network/interfaces) -eq 0 ]]
  then
    echo "YAPA ${vmbr_id}"
    {
      echo -e "\nauto vmbr${vmbr_id}"
      echo "iface vmbr${vmbr_id} inet manual"
      echo "      bridge-ports none"
      echo "      bridge-stp off"
      echo "      bridge-fd 0"
      ifup "vmbr${vmbr_id}"
      sleep 1
    } >> /etc/network/interfaces
  fi

  if [[ $(grep -c "vmbr1${vmbr_id}" /etc/network/interfaces)" -eq 0 ]]
  then
    echo "YAPA 1${vmbr_id}"
    {
      echo -e "\nauto vmbr1${vmbr_id}"
      echo "iface vmbr1${vmbr_id} inet manual"
      echo "      bridge-ports none"
      echo "      bridge-stp off"
      echo "      bridge-fd 0"
      ifup "vmbr1${vmbr_id}"
      sleep 1
    } >> /etc/network/interfaces
  fi
done

echo "$TIMESTAMP - STOP  - VMBR autocreate" | tee -a $LOGFILE


########################################################################
#     Ubuntu 18 cloudimage template
########################################################################

echo "$TIMESTAMP - START - Ubuntu 18 cloudimage template" | tee -a $LOGFILE

distrib_template_ver="18"
distrib_template_prefix="90"
cloudimg_name="bionic-server-cloudimg-amd64.img"

qm create ${distrib_template_prefix}${distrib_template_ver} --memory 2048 --name ubuntu-cloud-${distrib_template_ver} --net0 virtio,bridge=vmbr100
qm importdisk ${distrib_template_prefix}${distrib_template_ver} /var/lib/vz/template/iso/${cloudimg_name} ${local_storage} &> /dev/null
disk_location=$(pvesm list ${local_storage} | grep "^${local_storage}.*.-${distrib_template_prefix}${distrib_template_ver}-.*.raw.*" | cut -d " " -f1)
qm set ${distrib_template_prefix}${distrib_template_ver} --scsihw virtio-scsi-pci --scsi0 ${disk_location}
qm set ${distrib_template_prefix}${distrib_template_ver} --ide2 local:cloudinit
qm set ${distrib_template_prefix}${distrib_template_ver} --boot c -bootdisk scsi0
qm set ${distrib_template_prefix}${distrib_template_ver} --boot c --bootdisk scsi0
qm set ${distrib_template_prefix}${distrib_template_ver} --serial0 socket --vga serial0
qm set ${distrib_template_prefix}${distrib_template_ver} --scsi0 ${disk_location},cache=writethrough,ssd=1
qm set ${distrib_template_prefix}${distrib_template_ver} --ipconfig0 ip=dhcp
qm set ${distrib_template_prefix}${distrib_template_ver} --ciuser ${priviledged_user}
qm set ${distrib_template_prefix}${distrib_template_ver} --cipassword ${password}
qm set ${distrib_template_prefix}${distrib_template_ver} --agent enabled=1
if [ "${keylist_count}" -gt 0 ]
then
  qm set ${distrib_template_prefix}${distrib_template_ver} --sshkey /tmp/keys_to_add.pub
fi
qm template ${distrib_template_prefix}${distrib_template_ver}

echo "$TIMESTAMP - DONE - Ubuntu 18 cloudimage template" | tee -a $LOGFILE


########################################################################
#     Ubuntu 20 cloudimage template
########################################################################

echo "$TIMESTAMP - START - Ubuntu 20 cloudimage template" | tee -a $LOGFILE

distrib_template_ver="20"
distrib_template_prefix="90"
cloudimg_name="focal-server-cloudimg-amd64.img"

qm create ${distrib_template_prefix}${distrib_template_ver} --memory 2048 --name ubuntu-cloud-${distrib_template_ver} --net0 virtio,bridge=vmbr100
qm importdisk ${distrib_template_prefix}${distrib_template_ver} /var/lib/vz/template/iso/${cloudimg_name} ${local_storage} &> /dev/null
disk_location=$(pvesm list ${local_storage} | grep "^${local_storage}.*.-${distrib_template_prefix}${distrib_template_ver}-.*.raw.*" | cut -d " " -f1)
qm set ${distrib_template_prefix}${distrib_template_ver} --scsihw virtio-scsi-pci --scsi0 ${disk_location}
qm set ${distrib_template_prefix}${distrib_template_ver} --ide2 local:cloudinit
qm set ${distrib_template_prefix}${distrib_template_ver} --boot c --bootdisk scsi0
qm set ${distrib_template_prefix}${distrib_template_ver} --serial0 socket --vga serial0
qm set ${distrib_template_prefix}${distrib_template_ver} --scsi0 ${disk_location},cache=writethrough,ssd=1
qm set ${distrib_template_prefix}${distrib_template_ver} --ipconfig0 ip=dhcp
qm set ${distrib_template_prefix}${distrib_template_ver} --ciuser ${priviledged_user}
qm set ${distrib_template_prefix}${distrib_template_ver} --cipassword ${password}
qm set ${distrib_template_prefix}${distrib_template_ver} --agent enabled=1
qm set ${distrib_template_prefix}${distrib_template_ver} --sshkey /tmp/keys_to_add.pub
qm template ${distrib_template_prefix}${distrib_template_ver}

echo "$TIMESTAMP - DONE - Ubuntu 20 cloudimage template" | tee -a $LOGFILE


########################################################################
#     Ubuntu 22 cloudimage template
########################################################################

echo "$TIMESTAMP - START - Ubuntu 22 cloudimage template" | tee -a $LOGFILE

distrib_template_ver="22"
distrib_template_prefix="90"
cloudimg_name="jammy-server-cloudimg-amd64.img"

qm create ${distrib_template_prefix}${distrib_template_ver} --memory 2048 --name ubuntu-cloud-${distrib_template_ver} --net0 virtio,bridge=vmbr100
qm importdisk ${distrib_template_prefix}${distrib_template_ver} /var/lib/vz/template/iso/${cloudimg_name} ${local_storage} &>/dev/null
disk_location=$(pvesm list ${local_storage} | grep "^${local_storage}.*.-${distrib_template_prefix}${distrib_template_ver}-.*.raw.*" | cut -d " " -f1)
qm set ${distrib_template_prefix}${distrib_template_ver} --scsihw virtio-scsi-pci --scsi0 ${disk_location}
qm set ${distrib_template_prefix}${distrib_template_ver} --ide2 local:cloudinit
qm set ${distrib_template_prefix}${distrib_template_ver} --boot c --bootdisk scsi0
qm set ${distrib_template_prefix}${distrib_template_ver} --serial0 socket --vga serial0
qm set ${distrib_template_prefix}${distrib_template_ver} --scsi0 ${disk_location},cache=writethrough,ssd=1
qm set ${distrib_template_prefix}${distrib_template_ver} --ipconfig0 ip=dhcp
qm set ${distrib_template_prefix}${distrib_template_ver} --ciuser ${priviledged_user}
qm set ${distrib_template_prefix}${distrib_template_ver} --cipassword ${password}
qm set ${distrib_template_prefix}${distrib_template_ver} --agent enabled=1
qm set ${distrib_template_prefix}${distrib_template_ver} --sshkey /tmp/keys_to_add.pub
qm template ${distrib_template_prefix}${distrib_template_ver}

echo "$TIMESTAMP - DONE - Ubuntu 22 cloudimage template" | tee -a $LOGFILE


########################################################################
#     Debian 11 cloudimage template
########################################################################

echo "$TIMESTAMP - START - Debian 11 cloudimage template" | tee -a $LOGFILE

distrib_template_ver="11"
distrib_template_prefix="89"
cloudimg_name="debian-11-genericcloud-amd64.qcow2"

qm create ${distrib_template_prefix}${distrib_template_ver} --memory 2048 --name ubuntu-cloud-${distrib_template_ver} --net0 virtio,bridge=vmbr100
qm importdisk ${distrib_template_prefix}${distrib_template_ver} /var/lib/vz/template/iso/${cloudimg_name} ${local_storage} --format qcow2 &>/dev/null
disk_location=$(pvesm list ${local_storage} | grep "^${local_storage}.*.-${distrib_template_prefix}${distrib_template_ver}-.*.raw.*" | cut -d " " -f1)
qm set ${distrib_template_prefix}${distrib_template_ver} --scsihw virtio-scsi-pci --scsi0 ${disk_location}
qm set ${distrib_template_prefix}${distrib_template_ver} --ide2 local:cloudinit
qm set ${distrib_template_prefix}${distrib_template_ver} --boot c --bootdisk scsi0
qm set ${distrib_template_prefix}${distrib_template_ver} --serial0 socket --vga serial0
qm set ${distrib_template_prefix}${distrib_template_ver} --scsi0 ${disk_location},cache=writethrough,ssd=1
qm set ${distrib_template_prefix}${distrib_template_ver} --ipconfig0 ip=dhcp
qm set ${distrib_template_prefix}${distrib_template_ver} --ciuser ${priviledged_user}
qm set ${distrib_template_prefix}${distrib_template_ver} --cipassword ${password}
qm set ${distrib_template_prefix}${distrib_template_ver} --agent enabled=1
qm set ${distrib_template_prefix}${distrib_template_ver} --sshkey /tmp/keys_to_add.pub
qm template ${distrib_template_prefix}${distrib_template_ver}

echo "$TIMESTAMP - DONE  - Debian 11 cloudimage template" | tee -a $LOGFILE


########################################################################
#     mempoule-helper
########################################################################

echo "$TIMESTAMP - START - mempoule-helper" | tee -a $LOGFILE

wget https://raw.githubusercontent.com/mempoule/toolbox/main/infra/proxmox/mempoule-helper -P /usr/local/bin/

echo "$TIMESTAMP - DONE  - mempoule-helper" | tee -a $LOGFILE

########################################################################
#     totp
########################################################################

echo "$TIMESTAMP - START - totp" | tee -a $LOGFILE

wget https://raw.githubusercontent.com/mempoule/toolbox/main/infra/proxmox/totp -P /usr/local/bin/
chmod 700 /usr/local/bin/totp

echo "$TIMESTAMP - DONE  - totp" | tee -a $LOGFILE

########################################################################
#     swap disable if is_zfs=1
########################################################################

echo "$TIMESTAMP - START - swap disable if is_zfs=1" | tee -a $LOGFILE

if [[ ${is_zfs} -eq 1 ]]
then
  echo "vm.swappiness = 0" >> /etc/sysctl.conf
  sed -i '/swap/ s/^#*/# /' /etc/fstab
else
  echo "vm.swappiness = 10" >> /etc/sysctl.conf
fi
sysctl -p

echo "$TIMESTAMP - DONE  - swap disable if is_zfs=1" | tee -a $LOGFILE


########################################################################
#     pfsense ready to fire
########################################################################

echo "$TIMESTAMP - START - pfsense ready to fire" | tee -a $LOGFILE

qm create 100 --memory 1024 --name pfSense --net0 virtio,bridge=vmbr0 --net1 virtio,bridge=vmbr1 --net2 virtio,bridge=vmbr2 --net3 virtio,bridge=vmbr3 --net4 virtio,bridge=vmbr4 --net5 virtio,bridge=vmbr5 --net10 virtio,bridge=vmbr10 --net11 virtio,bridge=vmbr11 --net12 virtio,bridge=vmbr12 --net13 virtio,bridge=vmbr13 --net14 virtio,bridge=vmbr14 --net15 virtio,bridge=vmbr15
qm set 100 --scsihw virtio-scsi-pci --virtio0 local-zfs:20
qm set 100 --ide2 local:iso/pfSense-CE-2.6.0-RELEASE-amd64.iso,media=cdrom
qm set 100 --onboot 1
qm set 100 --startup order=1
qm set 100 --ostype l26
qm set 100 --boot order='ide2;virtio0'

echo "$TIMESTAMP - DONE  - pfsense ready to fire" | tee -a $LOGFILE


########################################################################
#     trashVM GUI ready to fire
########################################################################

echo "$TIMESTAMP - START - trashVM GUI ready to fire" | tee -a $LOGFILE

qm create 101 --memory 2048 --name mempoule-trashgui --net0 virtio,bridge=vmbr10
qm set 101 --scsihw virtio-scsi-pci --virtio0 local-zfs:20
qm set 101 --ide2 local:iso/ubuntu-22.10-desktop-amd64.iso,media=cdrom
qm set 101 --onboot 1
qm set 101 --startup order=1
qm set 101 --ostype l26
qm set 101 --boot order='ide2;virtio0'
qm set 101 --vga qxl

echo "$TIMESTAMP - DONE  - trashVM GUI ready to fire" | tee -a $LOGFILE


########################################################################
#     Cleaning install temp files
########################################################################

echo "$TIMESTAMP - START - Cleaning install temp files" | tee -a $LOGFILE

rm /tmp/keys_to_add.pub &> /dev/null

echo "$TIMESTAMP - STOP - Cleaning install temp files" | tee -a $LOGFILE
