#!/bin/bash

ROLE=$1
HOSTS=$(/usr/local/plattform/sadm/bin/exainfo -role "$ROLE")
 
skip_headings=''
for host in ${HOSTS}; do
  ssh -C pdadm@${host} "basestat --csv --tomcat ${skip_headings}"
  skip_headings='--skip_headings'
done > "/tmp/$ROLE".csv
scp "/tmp/$ROLE".csv pdadm@zqxumariasys01:/tmp
scp "/tmp/$ROLE".csv pdadm@zqxumariasys02:/tmp
scp "/tmp/$ROLE".csv pdadm@zqxtmariasys01:/tmp
scp "/tmp/$ROLE".csv pdadm@zqxtmariasys02:/tmp
scp "/tmp/$ROLE".csv pdadm@zqxpmariasys01:/tmp
scp "/tmp/$ROLE".csv pdadm@zqxpmariasys02:/tmp

