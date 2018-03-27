#!/bin/bash
. /home/stack/stackrc
pause=10

echo "##### Cleaning stack #####"
#heat stack-delete -y overcloud
openstack stack delete --yes --wait overcloud
#while [ "$(heat stack-list|awk '/overcloud/ {print $6;}')" == "DELETE_IN_PROGRESS" ] ; do echo "waiting $pause s to finish"; heat stack-list; sleep $pause;done
#while [ "$(openstack stack list|awk '/overcloud/ {print $6;}')" == "DELETE_IN_PROGRESS" ] ; do echo "waiting $pause s to finish"; heat stack-list; sleep $pause;done

echo "##### Cleaning deployment #####"
#heat deployment-delete overcloud
openstack software deployment delete overcloud
#while [ "$(heat deployment-list|awk '/overcloud/ {print $6;}')" == "DELETE_IN_PROGRESS" ] ; do echo "waiting $pause s to finish"; heat deployment-list; sleep $pause;done
while [ "$(openstack stack list|awk '/overcloud/ {print $6;}')" == "DELETE_IN_PROGRESS" ] ; do echo "waiting $pause s to finish"; heat deployment-list; sleep $pause;done


echo "##### Stetting KeyPair #####"
nova keypair-delete default
nova keypair-add --pub-key ~/.ssh/id_rsa.pub default

openstack stack list
openstack baremetal list
