#!/bin/bash

tmux new-window -n Watch-Logs "tail -f deploy.log"
  tmux split -v -l 50 ". ~/stackrc;watch \"openstack  stack list --nested|grep -v COMPL\""
  tmux split -v -l 30 ". ~/stackrc;watch \"openstack stack  resource list -n3 overcloud|grep -v COMPL\""
  #H=$(($(tmux display -p '#{pane_height}') - 10 ))
  tmux split -v -l 10 ". ~/stackrc;watch nova list"
  tmux split -h -p 55 ". ~/stackrc;watch ironic node-list"

