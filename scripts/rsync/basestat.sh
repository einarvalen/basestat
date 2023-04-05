#!/bin/bash

ROLE=$1
HOSTS=$(/usr/local/plattform/sadm/bin/exainfo -role "$ROLE")
 
skip_headings=''
for host in ${HOSTS}; do
  ssh -C pdadm@${host} "basestat --csv --tomcat ${skip_headings}"
  skip_headings='--skip_headings'
done > "/tmp/$ROLE".csv
scp "/tmp/$ROLE".csv pdadm@suvumariasys01:/tmp
scp "/tmp/$ROLE".csv pdadm@suvumariasys02:/tmp
scp "/tmp/$ROLE".csv pdadm@suvtmariasys01:/tmp
scp "/tmp/$ROLE".csv pdadm@suvtmariasys02:/tmp
scp "/tmp/$ROLE".csv pdadm@suvpmariasys01:/tmp
scp "/tmp/$ROLE".csv pdadm@suvpmariasys02:/tmp

