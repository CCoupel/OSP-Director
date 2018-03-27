#!/bin/bash
### https://access.redhat.com/documentation/en/red-hat-openstack-platform/8/director-installation-and-usage/director-installation-and-usage

OpenstackVersion=beta
OpenstackVersion=10
#OpenstackVersion=9
# add rsyslog et ntp
hostnamectl --static set-hostname undercloud.coupel.net
hostnamectl --transient set-hostname undercloud.coupel.net
sed -i "s/.*127.0.0.1*//g" /etc/hosts
echo "127.0.0.1 undercloud.coupel.net undercloud localhost localhost.localdomain localhost4 localhost4.localdomain4" >> /etc/hosts

echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/99-undercloud.conf
systemctl restart systemd-sysctl

useradd -m stack
echo stack|passwd --stdin stack
echo 'stack ALL=(root) NOPASSWD:ALL' | tee -a /etc/sudoers.d/stack
chmod 0440 /etc/sudoers.d/stack
cp -r ~/.ssh /home/stack
chown -R stack:stack /home/stack/.ssh
echo "Enter redhat Subscription password"

subscription-manager register --username=rh-gs-ccoupel
PoolID=$(subscription-manager list --available|grep -v "^ "|grep -m1 -A 5 "Employee SKU"|awk -F: '/ool/{print $2}'|sed "s/ //g")
subscription-manager attach --pool=$PoolID
#--pool=8a85f9843e3d687a013e3ddd471a083e

subscription-manager repos --disable=*
if [ "$OpenstackVersion" == "beta" ]
then
  baseVersionRPMS=" --enable=rhel-7-server-beta-rpms --enable=rhel-7-server-extras-rpms --enable=rhel-7-server-rh-common-rpms --enable=rhel-ha-for-rhel-7-server-beta-rpms --enable=rhel-7-server-openstack-beta-rpms --enable rhel-7-fast-datapath-rpms"
else
  baseVersionRPMS="--enable=rhel-7-server-rpms --enable=rhel-7-server-openstack-$OpenstackVersion-rpms "
fi

subscription-manager repos $baseVersionRPMS --enable=rhel-7-server-extras-rpms --enable rhel-7-server-rh-common-rpms


yum -y update
yum -y install rsyslog ntp gpm bash-completion screen deltarpm crudini tmux
systemctl enable rsyslog ntpd gpm
systemctl start rsyslog ntpd gpm

cat > ~stack/.tmux.conf << EOF
set -g prefix C-a

unbind-key C-b
bind-key C-a send-prefix

set -g mode-mouse on
set -g mouse-resize-pane on
set -g mouse-select-pane on
set -g mouse-select-window on
set-option -g pane-active-border-fg red
set-window-option -g window-status-current-bg blue
set -g status-bg white

EOF

echo "###### Preparation finished, REBOOT ######"
