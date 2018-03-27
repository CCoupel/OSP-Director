#!/bin/bash
. /home/stack/stackrc
TMUXorig=$TMUX
unset TMUX

templatesDir=/home/stack/templates/
NewTemplates=/home/stack/new_templates/

GLOBAL="--templates $templatesDir --ntp-server 10.5.26.10 --neutron-tunnel-types vxlan --neutron-network-type vxlan"
#MODEL="-e $templatesDir/network-environement.yaml -e $templatesDir/environments/network-isolation.yaml -e $templatesDir/environments/external-loadbalancer-vip.yaml"

NETWORK="-e $templatesDir/environments/network-environment.yaml -e $templatesDir/environments/network-isolation.yaml"
# -e $NewTemplates/firstboot_environment.yaml"
# -e $templatesDir/environments/network-isolation.yaml"
STORAGE=""

echo '###### Deploy Controler ######'
CONTROLER=" --control-scale 1 --control-flavor control"

echo '###### Deploy Compute ######'
COMPUTE=" --compute-scale 1 --compute-flavor compute"


tmux kill-window -t OSPdeploy

. /home/stack/stackrc
tmux new-window -d -n OSPdeploy "time openstack overcloud deploy $GLOBAL $NETWORK $STORAGE  $COMPUTE $CONTROLER -e $NewTemplates/infra-env.yaml $*|tee deploy.log;read"



#tmux new-window -n Watch-Logs "tail -f deploy.log"
  #tmux split -v -l 50 "watch \"openstack  stack list --nested|grep -v COMPL\""
  #tmux split -v -l 30 "watch \"openstack stack  resource list -n3 overcloud|grep -v COMPL\""
  ##H=$(($(tmux display -p '#{pane_height}') - 10 ))
  #tmux split -v -l 10 "watch nova list"
  #tmux split -h -p 55 "watch ironic node-list"

./Watch_Deploy.sh
 
TMUX=$TMUXorig
