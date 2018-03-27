#!/bin/bash
export NODE_DIST=rhel7
#export DIB_LOCAL_IMAGE=rhel7-guest.qcow2
export USE_DELOREAN_TRUNK=0
export RHOS=1
export DIB_YUM_REPO_CONF="/etc/yum.repos.d/rhos-release-7-director-rhel-7.1.repo /etc/yum.repos.d/rhos-release-7-rhel-7.1.repo"
echo "##### Removing old images #####"
. stackrc
cd ~stack/images
rm *
sudo rm /httpboot/agent* 
#time openstack overcloud image build --all 2>&1 | tee openstack_image_build.log
#https://access.redhat.com/downloads/content/191/ver=8/rhel---7/8/x86_64/product-software
#curl -# -o deploy-7.3.1.tar https://access.cdn.redhat.com//content/origin/files/sha256/ff/ffb2050e05050e75602a973f9fe0dfcecb11cc019bdf85acb840e95c941b2bae/deploy-ramdisk-ironic-7.3.1-39.tar?_auth_=1460626799_917ae22e9af83c6d4fd32fffcea9795e
#curl -# -o Discovery-7.3.1.tar https://access.cdn.redhat.com//content/origin/files/sha256/b6/b61b0d9ef599a1ae3ef3d01e9352c0945b35ba153acfc106ed6489e4a8a0bb85/discovery-ramdisk-7.3.1-59.tar?_auth_=1460626799_bd31652fd43ab268797f2d8eaf3737f1
#curl -# -o Overcloud.7.3.1.tar https://access.cdn.redhat.com//content/origin/files/sha256/b0/b04930515017127636b1d7c0f0d80244c46bb973bab02bd13aaddfe17a9b6ddc/overcloud-full-7.3.1-59.tar?_auth_=1460626799_aa122a736a40bbea7f2f4522b057cb60

echo "##### removing images #####"
for i in `openstack image list|grep -v ID|awk '{print $2};'`
do
	echo $i
	openstack image delete "$i"
done

sudo yum install -y rhosp-director-images rhosp-director-images-ipa

for i in /usr/share/rhosp-director-images/overcloud-full.tar /usr/share/rhosp-director-images/ironic-python-agent.tar
do
	tar xvf "$i"
done

echo "###### Customizing Images ######"
sudo yum -y install libguestfs-tools guestfish
sudo systemctl restart libvirtd
sudo umount /tmp/guestfish
mkdir /tmp/guestfish
guestmount -a overcloud-full.qcow2 -m /dev/sda --rw /tmp/guestfish

echo "###### Setting Log on TTY12 ######"
cat <<EOF|tee /tmp/guestfish/etc/systemd/system/journal@tty12.service 
# by running journalctl -af on it.
# Install by:
#  - Saving this as /etc/systemd/system/journal@tty12.service
#  - Running systemctl enable journal@tty12
#  - Running systemctl start journal@tty12
# journald can also log on console itself, but current Debian version won't
# show timestamps and color-coding.
# systemd is under LGPL2.1 etc, this is inspired by getty@.service.

[Unit]
Description=Journal tail on %I
Documentation=man:journalctl(1)
After=systemd-user-sessions.service plymouth-quit-wait.service systemd-journald.service
After=rc-local.service

# On systems without virtual consoles, don't start any getty. (Note
# that serial gettys are covered by serial-getty@.service, not this
# unit
ConditionPathExists=/dev/tty0

[Service]
# the VT is cleared by TTYVTDisallocate
ExecStart=/bin/sh -c "exec /bin/journalctl -af > /dev/%I"
Type=idle
Restart=always
RestartSec=1
UtmpIdentifier=%I
TTYPath=/dev/%I
TTYReset=yes
TTYVHangup=yes
#TTYVTDisallocate=yes
TTYVTDisallocate=no
KillMode=process
IgnoreSIGPIPE=no

# Unset locale for the console getty since the console has problems
# displaying some internationalized messages.
Environment=LANG= LANGUAGE= LC_CTYPE= LC_NUMERIC= LC_TIME= LC_COLLATE= LC_MONETARY= LC_MESSAGES= LC_PAPER= LC_NAME= LC_ADDRESS= LC_TELEPHONE= LC_MEASUREMENT= LC_IDENTIFICATION=

[Install]
Alias=getty.target.wants/journal@tty12.service

EOF

sync

sudo umount /tmp/guestfish
rmdir /tmp/guestfish
sync
sleep 2


echo "##### Setting root Password #####"
guestfish --progress-bars --rw -a overcloud-full.qcow2 --mount /dev/sda <<EOF
command "systemctl enable journal@tty12"
command "sed -i s/root:.*/root:::0:999:7:::/g /etc/shadow"
EOF
#cf http://log.or.cz/?p=327 pour log sur TTY
 
echo "##### Uploading images #####"
openstack overcloud image upload
openstack image list
