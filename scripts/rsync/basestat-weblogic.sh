#!/bin/bash

ROLE=$1
#HOSTS=$(/usr/local/plattform/sadm/bin/exainfo -role "$ROLE")
HOSTS=$(/usr/local/plattform/sadm/bin/exainfo -role "$ROLE" | sed 's/ /\n/g' | egrep '(zqxtwls01|zqxtwls06|zqxtwls07|zqxtwls08)' -v | xargs)
 
cat /home/weblogic/bin/weblogic-headings.csv > "/tmp/$ROLE".csv
for host in ${HOSTS}; do
  ssh -C pdadm@${host} "basestat --csv --weblogic --skip_headings"
done >> "/tmp/$ROLE".csv
scp "/tmp/$ROLE".csv pdadm@zqxpmariasys01:/tmp
scp "/tmp/$ROLE".csv pdadm@zqxpmariasys02:/tmp

