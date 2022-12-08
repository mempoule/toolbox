#!/bin/bash

########################################################################
# Breaking OVH defaukt raid0
########################################################################

loc_mapper_name=$(df -h | grep mapper | cut -d ' ' -f1)
loc_vg_name=$(/sbin/pvs --separator "," | grep dev | xargs | cut -d "," -f2)
lsblk | grep -v '^loop' 1>&2
echo "Please specify the disk to add to existing vg" 1>&2
read loc_unused_disk
if ! [[ "${loc_unused_disk}" =~ [^[:alnum:]]+ ]]
then
  echo "/sbin/wipefs /dev/${loc_unused_disk}" 1>&2
  echo "/sbin/pvcreate /dev/${loc_unused_disk} -f" 1>&2
  echo "/sbin/vgextend ${loc_vg_name} /dev/${loc_unused_disk}" 1>&2
  echo "/sbin/lvresize --extents +100%FREE --resizefs ${loc_mapper_name}" 1>&2
else
   echo "Must provide a valid disk" 1>&2
   exit
fi
