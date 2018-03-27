#!/bin/bash
. /home/stack/stackrc

echo '###### Clean UP nodes ######'********
for i in `openstack baremetal node list|grep "None"|awk '{print $2};'` 
do
	openstack baremetal node power off "$i"
	openstack baremetal node delete "$i"
done
openstack baremetal node list

echo '###### Add new nodes ######'*****
INSTACK=instack-new
VirshSRV=ccoupel@192.168.122.1
ssh-copy-id -o StrictHostKeyChecking=no $VirshSRV
scp $VirshSRV:.ssh/* .ssh

for SRV in `virsh --connect qemu+ssh://$VirshSRV/system list --all|grep Overcloud|cut -c8-38`
do
	i=$(virsh --connect qemu+ssh://$VirshSRV/system domiflist "$SRV" | grep -i Deploy | awk '{print $5};'|head -1)
	prof=$(echo "$SRV"|sed "s/.*-\(.*\)/\1/g")
echo "****** adding $SRV ($i) as $prof *********"
        INSTACKnode=$INSTACK-$SRV.json
	KEY=`cat ~/.ssh/id_rsa|sed 's/  //g;s/$/\\\\n/g;s/END RSA PRIVATE KEY-----.*/END RSA PRIVATE KEY-----/g'|tr -d '\n'`
#            "pm_password":"-----BEGIN RSA PRIVATE KEY-----\nMIIEpAIBAAKCAQEA0YN/3isgnjXD7kNMdFhygmRlRGuWwZvIiA9Z9SxJ5QrU36yC\ns/EDJ15OYfs5JAf+q+yjLK+qEinK06AQoWT0uffRar1MeNwTEps0bOeMVEuffNVA\nU7YSDCNwuVVjc5vEqfIDQ0k4Gg1WIDYVOD9PozDFmaR9PN5MBTTfWNoilLStlpzF\nvigXfLbaptsDR+c8D/rIQTZJFJY1Iy2TIO8lN/PSX3Yrz2KVu1XYqv53qNXTq5YM\nzSt9hBm8Yh7IdzAcmuhzFh4sfUNgQzLMHxSr7ESAab4qlB37rwV96b8WfEpJF/2z\nld86GHy6HdKlMsU2X3YdqutdhND6xio4Rl4kyQIDAQABAoIBAG6FvBJrFc3f9vfd\nsJs/fUijxXgOeXywvVxpHL9lGaYlzJ4h1uEtpshBy3+Mk1wai5IORxXvpPvn6AMz\nURKSuzbPMD3qlki7b6RFE6bPjwt4yS2FIWYHigW1PGXIUapO5bPw4x+/pES5/FEJ\ntq/xVgV0WQjv6NEPQ3MLrTal+9ANe39o4Bck6CqflkM/yHXVJk3BgFEDdTS7rCU5\n8vDEkDoZ5nEBtpmCsAtoKDcHjQCaMe8u4wo678tlN9rOikmNAkq1yGAR0xO7STE/\nYWXQbhwgtJt8NgpyDpeX1muUnvJapbyuxgraXOpWUgpc4hlHYLkmX18qpc5mddu1\nz0PBsAECgYEA7tiX3zal2djCdAS4BlaMYABtmgg1VCA7tamWFqO7j2ZCO26oREfs\nPUlxHJ8lInisXpmR8M6l1nbJxH1C3bRvyd8pzaEP8aGUukYxhObac7W0wAECa3aZ\n+NVmPPQPueTMoDDtJnN2Gx+4k4uB1R74Z61CYinM952YT6F/zu5ZyEkCgYEA4I+a\nVXQhXGsd80ZNMqF1qgMc4NacJVJMsFcZbNR2uZRdrIqOo/GMm5ORtt5xuVwQUkHn\nijMU75olFcebZeM/t5beOjEfRHF6uAXEoLhvn7LxInKexHyBEjXWt0OAi15IurVy\nzuCX69f0IZcmzySkewwS6QwqpzxYayY86pdOeIECgYEA7M0xRc0YgfO2VvCWwzHr\n2wKRp7WbqdyLVoDcnXWX74SjBemgSpJEVj8KNiZS2uppeyEm4GkBYrBDOtw1/zl1\n29+1wnl9JUPeARC25905mJ7+pZ5al9DutxZcVvJi5RtDBU980DKJVjsM9LvL7VDX\nV3Mf7dMjtBw7djfYT4Fg4oECgYAV059qoukDNJ4qoTCrtSncpoTODc4Lip5NnYmp\nHFWV4Cfit2z53maOUJ+fKKvhGmOzuxgoRKLKTy8/mLEwDBCLZayf91pUqrsE2/qq\nrIKdASWS9ZUdAAUDohwGoBcEdNuY2j4YgZgConDmOuzYwXUDSL8ly7rxmln1wDe3\njZFhAQKBgQDons3FQgY0RtDe6x1ZG3YF2kiZRoO58mQpOZRpD2ypqno9ZgtiMYzW\nwVg9R7vD/sYt953OPm7pkxzuHTy45H3Xh5aNLL4hzoylq2Z4DvNHNAq5QzE4qycA\nrAdryBO0gWTDK/rxDifZ6sCiBL4i7rAN7prfIcJJT96YK+weHZwUog==\n-----END RSA PRIVATE KEY-----\n",
	cat > ~/$INSTACKnode << EOF
{
    "nodes":[
        {
            "mac":[
		"$i"
            ],
            "name":"$SRV",
            "capabilities":"profile:$prof,boot_option:local",
            "pm_type":"pxe_ssh",
            "pm_user":"ccoupel",
	    "pm_password":"$KEY",
            "pm_addr":"192.168.122.1"
        }
    ]
}
EOF
	openstack baremetal import --json ~/$INSTACKnode
	#openstack baremetal node set --property root_device='{"name":"/dev/sda"}' $SRV
done
echo '###### Introspection ######'
ironic node-list
openstack baremetal configure boot

pause=10


function introspectByOne()
{
for UUID in $(ironic node-list|awk '/None/{print $2};')
do
	echo "**** starting $UUID *****"
	openstack baremetal node manage $UUID
	openstack overcloud node introspect  $UUID --provide
time	while [ $(openstack baremetal introspection status $UUID|awk '/finished/ {print $4;}') == "False" ] ; do echo "waiting $pause s to finish"; openstack baremetal introspection status $UUID; sleep $pause;done
done
}

function introspectBulk()
{
  echo "***** Starting BULK introspection *****"
  for node in $(openstack baremetal node list -f value -c UUID) ; do openstack baremetal node manage $node ; done
  time openstack overcloud node introspect  $UUID --provide --all-manageable 
}

introspectBulk
#introspectByOne

