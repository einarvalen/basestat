#!/bin/bash

ROLE=$1
HOSTS=$(/usr/local/plattform/sadm/bin/exainfo -role "$ROLE")
 
for host in ${HOSTS}; do
  ssh -C pdadm@${host} "basestat --splunk"
done > "/tmp/$ROLE".txt
