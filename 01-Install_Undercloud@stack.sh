#!/bin/bash
### https://access.redhat.com/documentation/en/red-hat-openstack-platform/8/director-installation-and-usage/director-installation-and-usage

Net=172.16.0
deployEth=eth0
extNet=192.168.122
extEth=eth1

Vip=vip
Domain=lab.coupel.net

Images=/home/stack/images
mkdir $Images
sudo sed -i "/ admin_vip/d" /etc/hosts
sudo sed -i "/ vip/d" /etc/hosts

echo "$extNet.10 $Vip $Vip.$Domain" |sudo tee -a /etc/hosts
echo "$extNet.11 admin_$Vip admin_$Vip.$Domain" |sudo tee -a /etc/hosts

#sudo ip a add $extNet.10/32 dev $extEth
#sudo ip a add $extNet.11/32 dev $extEth

sudo yum install -y python-rdomanager-oscplugin openstack-utils python-tripleoclient firewalld
cp /usr/share/instack-undercloud/undercloud.conf.sample ~/undercloud.conf


echo "####### generating CA certificat #####"
Subj="/C=FR/ST=IDF/L=Paris/O=$Domain/OU=LAB/CN=*.$Domain/emailAddress=root@coupel.net"

openssl genrsa -out ca.$Domain.key.pem 4096
openssl req  -key ca.$Domain.key.pem -new -x509 -days 7300 -extensions v3_ca -out ca.$Domain.crt.pem -subj $Subj

echo "####### generating SERVER certificat #####"
openssl genrsa -out server.$Domain.key.pem 4096
openssl req  -key server.$Domain.key.pem -new -x509 -days 7300 -extensions v3_ca -out server.$Domain.csr.pem -subj $Subj

echo "####### signing SERVER certificat #####"
openssl ca -extensions v3_req -days 3650 -in server.$Domain.csr.pem -out server.$Domain.crt.pem -cert ca.$Domain.crt.pem -keyfile ca.$Domain.key.pem

echo "####### deploying SERVER CA certificat #####"
cat server.$Domain.crt.pem server.$Domain.key.pem > undercloud.$Domain.pem
sudo mkdir /etc/pki/instack-certs
sudo cp ~/undercloud.$Domain.pem /etc/pki/instack-certs/.
sudo semanage fcontext -a -t etc_t "/etc/pki/instack-certs(/.*)?"
sudo restorecon -R /etc/pki/instack-certs

echo "####### Configuroing Undercloud  #####"
crudini --set ~/undercloud.conf DEFAULT image_path $Images
crudini --set ~/undercloud.conf DEFAULT local_ip $Net.35/24
crudini --set ~/undercloud.conf DEFAULT network_gateway $Net.35
crudini --set ~/undercloud.conf DEFAULT undercloud_public_vip $Net.10
crudini --set ~/undercloud.conf DEFAULT undercloud_admin_vip $Net.11
crudini --set ~/undercloud.conf DEFAULT local_interface $deployEth
crudini --set ~/undercloud.conf DEFAULT network_cidr $Net.0/24
crudini --set ~/undercloud.conf DEFAULT masquerade_network $Net.0/24
crudini --set ~/undercloud.conf DEFAULT dhcp_start $Net.100
crudini --set ~/undercloud.conf DEFAULT dhcp_end $Net.199
crudini --set ~/undercloud.conf DEFAULT inspection_interface br-ctlplane
crudini --set ~/undercloud.conf DEFAULT inspection_iprange $Net.200,$Net.220
crudini --set ~/undercloud.conf DEFAULT discovery_runbench  false
crudini --set ~/undercloud.conf DEFAULT dhcp_domain $Domain
crudini --set ~/undercloud.conf DEFAULT dns_domain $Domain
crudini --set ~/undercloud.conf DEFAULT undercloud_hostname undercloud.$Domain
crudini --set ~/undercloud.conf DEFAULT generate_service_certificate yes
#crudini --set ~/undercloud.conf DEFAULT undercloud_service_certificate undercloud.$Domain.pem 
crudini --set ~/undercloud.conf DEFAULT enable_ui yes

 


echo "####### Undercloud Installation #####"
openstack undercloud install

echo "####### Undercloud Installed #####"
sudo rmdir /var/lib/ironic
sudo mkdir /home/ironic
sudo ln -s /home/ironic /var/lib/ironic
sudo chown nova:nova /home/ironic
sudo chown nova:nova /var/lib/ironic
sudo chmod 777 /home/ironic

echo "####### Undercloud Ready #####"
