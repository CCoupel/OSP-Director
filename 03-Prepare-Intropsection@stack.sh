#!/bin/bash
. /home/stack/stackrc

echo '###### Workaround for KVM ######'
#### /httpboot/inspector.ipxe
##!ipxe
#
#dhcp
#
#kernel http://172.16.0.35:8088/agent.kernel ipa-inspection-callback-url=http://172.16.0.35:5050/v1/continue ipa-inspection-collectors=default,extra-hardware,logs systemd.journald.forward_to_console=yes BOOTIF=${mac} ipa-debug=1
#initrd http://172.16.0.35:8088/agent.ramdisk
#boot

sudo systemctl stop bootif-fix
cat << EOF > /tmp/bootif-fix
#!/usr/bin/env bash
while true;
do find /httpboot/ -type f ! -iname "kernel" ! -iname "ramdisk" ! -iname "*.kernel" ! -iname "*.ramdisk" -exec sed -i 's|{mac|{net0/mac|g' {} +;
done
EOF


cat << EOF > /tmp/bootif-fix.service
[Unit]
Description=Automated fix for incorrect iPXE BOOFIF
[Service]
Type=simple
ExecStart=/usr/bin/bootif-fix
[Install]
WantedBy=multi-user.target
EOF

sudo cp /tmp/bootif-fix.service /usr/lib/systemd/system/bootif-fix.service
sudo cp /tmp/bootif-fix /usr/bin/bootif-fix
sudo chmod a+x /usr/bin/bootif-fix

sudo systemctl daemon-reload
sudo systemctl enable bootif-fix
sudo systemctl restart bootif-fix

echo '###### Optimization for KVM ######'

sudo crudini --set /etc/nova/nova.conf DEFAULT rpc_response_timeout 600
sudo crudini --set /etc/nova/nova.conf DEFAULT scheduler_max_attempts 3
sudo crudini --set /etc/nova/nova.conf DEFAULT executor_thread_pool_size 64
sudo crudini --set /etc/nova/nova.conf DEFAULT dhcp_domain "lab.coupel.net"
sudo crudini --set /etc/ironic/ironic DEFAULT rpc_response_timeout 600
sudo crudini --set /etc/ironic/ironic DEFAULT rpc_conn_pool_size 1
sudo systemctl restart openstack-nova-*
sudo systemctl restart openstack-ironic-*

echo '###### Update DNS ######'******
subnet_id=$(neutron subnet-list | awk '/172.16.0.0/ {print $2;}'
)
neutron subnet-update $subnet_id --dns-nameserver 192.168.122.1


