#!/bin/bash

ROLE=$1
#HOSTS=$(/usr/local/plattform/sadm/bin/exainfo -role "$ROLE")
HOSTS=$(/usr/local/plattform/sadm/bin/exainfo -role "$ROLE" | sed 's/ /\n/g' | egrep '(suvtwls01|suvtwls06|suvtwls07|suvtwls08)' -v | xargs)
 
cat /home/weblogic/bin/weblogic-headings.csv > "/tmp/$ROLE".csv
for host in ${HOSTS}; do
  ssh -C pdadm@${host} "basestat --csv --weblogic --skip_headings"
done >> "/tmp/$ROLE".csv
scp "/tmp/$ROLE".csv pdadm@suvpmariasys01:/tmp
scp "/tmp/$ROLE".csv pdadm@suvpmariasys02:/tmp

