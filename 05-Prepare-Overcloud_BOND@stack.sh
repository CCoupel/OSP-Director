#!/bin/bash
. /home/stack/stackrc
pause=10
BaseTemplate=/home/stack/templates
NewTemplates=/home/stack/new_templates
TypeTemplate=bond-with-vlans

echo "#### Templating ####"
rm -rf $BaseTemplate
cp -rp /usr/share/openstack-tripleo-heat-templates $BaseTemplate
#cd $BaseTemplate
rm -rf $NewTemplates
mkdir $NewTemplates

#sed -i "s/\#OS::TripleO::Controller::Ports::ManagementPor/OS::TripleO::Controller::Ports::ManagementPor/g" $BaseTemplate/environments/external-loadbalancer-vip.yaml

#cp $BaseTemplate/environments/network-environment.yaml $BaseTemplate/environments/network-environment.yaml.orig
ipUndercloud=172.16.0.35
baseOvercloud=10.0

cat <<EOF > $NewTemplates/infra-env.yaml
resource_registry:
  OS::TripleO::NodeUserData: $NewTemplates/firstboot.yaml
  #OS::TripleO::NodeExtraConfigPost:  $NewTemplates/postdeploy.yaml

#  OS::TripleO::BlockStorage::Net::SoftwareConfig: $OrigTemplate/cinder-storage.yaml
#  OS::TripleO::Compute::Net::SoftwareConfig: $BaseTemplate/network/config/$TypeTemplate/compute.yaml
#  OS::TripleO::Controller::Net::SoftwareConfig: $BaseTemplate/network/config/$TypeTemplate/controller.yaml
#  OS::TripleO::ObjectStorage::Net::SoftwareConfig: $OrigTemplate/swift-storage.yaml
#  OS::TripleO::CephStorage::Net::SoftwareConfig: $OrigTemplate/ceph-storage.yaml

  OS::TripleO::Compute::Net::SoftwareConfig: $NewTemplates/compute.yaml
  OS::TripleO::Controller::Net::SoftwareConfig: $NewTemplates/controller.yaml

parameter_defaults:
  #TimeZone: 'Europe/Paris'
  #CloudDomain: "lab.coupel.net"
  #CloudName: "192.168.122.35"
  #ControllerHostnameFormat: controler-%index%
  #ComputeHostnameFormat: compute-%index%
  #CephStorageHostnameFormat: ceph-%index%


  # Set to the router gateway on the external network
  # ExternalInterfaceDefaultRoute: 192.168.122.1
  # Gateway router for the provisioning network (or Undercloud IP)
  ControlPlaneDefaultRoute: $ipUndercloud
  ControlPlaneSubnetCidr: "24"
  DnsServers: ["192.168.122.35"]

  # The IP address of the EC2 metadata server. Generally the IP of the Undercloud
  EC2MetadataIp: $ipUndercloud
  # Define the DNS servers (maximum 2) for the overcloud nodes
  DnsServers: ["$ipUndercloud"]
  # Set to "br-ex" if using floating IPs on native VLAN on bridge br-ex
  NeutronExternalNetworkBridge: "''"
  #BondInterfaceOvsOptions: "bond_mode=active-backup"

  ExternalNetCidr: 192.168.122.0/24
  ExternalAllocationPools: [{'start': '192.168.122.10', 'end': '192.168.122.50'}]
  ExternalInterfaceDefaultRoute: 192.168.122.1
  ExternalNetworkVlanID: 0

  InternalApiNetCidr: $baseOvercloud.10.0/24
  InternalApiAllocationPools: [{'start': '$baseOvercloud.10.10', 'end': '$baseOvercloud.10.200'}]
  InternalApiNetworkVlanID: 110

  StorageNetCidr: $baseOvercloud.20.0/24
  StorageAllocationPools: [{'start': '$baseOvercloud.20.10', 'end': '$baseOvercloud.20.200'}]
  StorageNetworkVlanID: 120

  StorageMgmtNetCidr: $baseOvercloud.30.0/24
  StorageMgmtAllocationPools: [{'start': '$baseOvercloud.30.10', 'end': '$baseOvercloud.30.200'}]
  StorageMgmtNetworkVlanID: 130

  TenantNetCidr: $baseOvercloud.40.0/24
  TenantAllocationPools: [{'start': '$baseOvercloud.40.10', 'end': '$baseOvercloud.40.200'}]
  TenantNetworkVlanID: 140

#  ManagementPortNetCidr: $baseOvercloud.50.0/24
#  ManagementPortAllocationPools: [{'start': '$baseOvercloud.50.10', 'end': '$baseOvercloud.50.200'}]
#  ManagementPortNetworkVlanID: 50

  #PublicVirtualFixedIPs: [{'ip_address':'192.168.122.14'}]
  #ControllerIPs:
      #external:
      #- 192.168.122.11
      #- 192.168.122.12
      #- 192.168.122.13 


EOF
cat << EOF >$NewTemplates/firstboot.yaml
heat_template_version: 2014-10-16

outputs:
  OS::stack_id:
    value: {get_resource: userdata}

resources:
  userdata:
    type: OS::Heat::MultipartMime
    properties:
      parts:
### add new block here ###


EOF
cat << EOF >$NewTemplates/postdeploy.yaml
heat_template_version: 2014-10-16

parameters:
  servers:
    type: json
  controller_servers:
    type: json
  compute_servers:
    type: json
  blockstorage_servers:
    type: json
  objectstorage_servers:
    type: json
  cephstorage_servers:
    type: json
resources:
EOF

cp -rp $BaseTemplate/network/config/$TypeTemplate/controller.yaml $NewTemplates/controller.yaml
cp -rp $BaseTemplate/network/config/$TypeTemplate/compute.yaml $NewTemplates/compute.yaml

patch $NewTemplates/controller.yaml << EOF
*** templates/network/config/bond-with-vlans/controller.yaml	2016-03-28 17:42:18.000000000 +0200
--- new_templates/controller.yaml	2016-06-20 12:12:35.994341163 +0200
***************
*** 108,111 ****
--- 108,130 ----
                members:
                  -
+                   type: interface
+                   name: nic4
+ #                -
+ #                  type: vlan
+ #                  device: nic4
+ #                  vlan_id: {get_param: ExternalNetworkVlanID}
+               addresses:
+                 -
+                   ip_netmask: {get_param: ExternalIpSubnet}
+               routes:
+                 -
+                   default: true
+                   next_hop: {get_param: ExternalInterfaceDefaultRoute}
+             -
+               type: ovs_bridge
+               name: br_prov
+               dns_servers: {get_param: DnsServers}
+               members:
+                 -
                    type: ovs_bond
                    name: bond1
***************
*** 121,135 ****
                  -
                    type: vlan
-                   device: bond1
-                   vlan_id: {get_param: ExternalNetworkVlanID}
-                   addresses:
-                     -
-                       ip_netmask: {get_param: ExternalIpSubnet}
-                   routes:
-                     -
-                       default: true
-                       next_hop: {get_param: ExternalInterfaceDefaultRoute}
-                 -
-                   type: vlan
                    device: bond1
                    vlan_id: {get_param: InternalApiNetworkVlanID}
--- 140,143 ----

EOF
