#!/bin/bash
. /home/stack/stackrc

echo '###### Clean UP flavor ######'********

for i in ` openstack flavor list|grep -v "ID"|awk '{print $2};'` 
do
	nova flavor-delete "$i"
done
openstack flavor list

#sudo rm -f /var/lib/ironic-inspector/inspector.sqlite
(for i in $(echo ".tables"|sudo sqlite3 /var/lib/ironic-inspector/inspector.sqlite);do echo delete from $i";";done)|sudo sqlite3 /var/lib/ironic-inspector/inspector.sqlite

sudo systemctl restart openstack-ironic-inspector

echo '###### Flavor creation ######'
#openstack flavor create --id auto --ram 4096 --disk 8 --vcpus 4 baremetal
openstack flavor create --id auto --ram 1000 --disk 4 --vcpus 1 baremetal
openstack flavor create --id auto --ram 1000 --disk 8 --vcpus 1 control
openstack flavor create --id auto --ram 1000 --disk 8 --vcpus 1 compute


openstack flavor set --property "cpu_arch"="x86_64" --property "capabilities:boot_option"="local" baremetal
openstack flavor set --property "cpu_arch"="x86_64" --property "capabilities:boot_option"="local" --property "capabilities:profile"="control" control
openstack flavor set --property "cpu_arch"="x86_64" --property "capabilities:boot_option"="local" --property "capabilities:profile"="compute" compute

