Basestat
========
    Reports current config and runtime info from Tomcat and Weblogic appserver instances.

Build server
------------

	  ssh zqxpastools01

Git
---

    git clone https://<yourUserId>@git.somesite.no/scm/pas/basestat.git
	  cd  basestat

Build
-----

### Start docker image 

	  ./docker-run.sh

### Build and test basestat inside docker container 

	  #Build and run unittests
	  make clean test

	  #Build for production
	  make clean prod

	  #Exit docker
	  exit

Distribute
----------

	  scp basestat zqxpasdrift01:/tmp
	  ssh zqxpassdrift01
    su -

### Test-run as pdadm

	  su - pdadm 
    /tmp/basestat --help"
	  /tmp/basestat --json --name=maria
	  /tmp/basestat --csv --tomcat
    exit

### Test-run on a small selection of servers

	  su - weblogic
	  scp /tmp/basestat pdadm@zqxutomcat07:/tmp
	  scp /tmp/basestat zqxujapp29:/tmp
	  ssh pdadm@zqxutomcat07 -C /tmp/basestat
	  ssh zqxujapp29 -C /tmp/basestat

### Update sadm

	  cd /usr/local/plattform/sadm/bin
	  cp basestat old-basestat
	  cp /tmp/basestat .
	
### Dist

    cd /usr/local/plattform/
    make {weblogic-server|revproxy-server|revproxy-sn4-server|tomcat-server|tomcat-sn4-server}
    ex: make weblogic-server tomcat-server

### Verify
	
	  ssh pdadm@zqxutomcat07 -C basestat
	  ssh pdadm@zqxujapp29 -C basestat

	  test-basestat.sh 
	  test-basestat-wls.sh

	  ssh pdadm@zqxusn3tc07 -C "basestat --json --name=kanal"
	  ssh pdadm@zqxusn3tc08 -C "basestat --splunk"
	  ssh pdadm@zqxusn1tc04 -C "basestat --csv --tomcat --skip_headings"

	  basestat.sh tomcat-test-server
	  basestat.sh tomcat-utv-server
	  basestat.sh tomcat-prod-server

Scripts
-------

	  zqxpasdrift01:/home/weblogic/bin/basestat.sh
	  zqxpasdrift01:/home/weblogic/bin/basestat_splunk.sh

Cron
----

	  ssh zqxpasdrift01
	  su - weblogic

	  crontab -l
	  */15 * * * * /home/weblogic/bin/basestat.sh tomcat-utv-server
	  */15 * * * * /home/weblogic/bin/basestat.sh tomcat-test-server
	  */15 * * * * /home/weblogic/bin/basestat.sh tomcat-prod-server
	  21 * * * * /home/weblogic/bin/basestat_splunk.sh tomcat-utv-server
	  22 * * * * /home/weblogic/bin/basestat_splunk.sh tomcat-test-server
	  23 * * * * /home/weblogic/bin/basestat_splunk.sh tomcat-prod-server
	  ...

Maria URL
---------

	  http://146.2.218.107:16000/maria/baseinfo/download-text-file?filename=/tmp/tomcat-utv-server.csv
	  http://146.2.218.107:16000/maria/baseinfo/download-text-file?filename=/tmp/tomcat-test-server.csv
	  http://146.2.218.107:16000/maria/baseinfo/download-text-file?filename=/tmp/tomcat-prod-server.csv

Wiki pages
----------

	  https://www.somesite.no/wiki/display/Drift/Baseoversikt
	  https://www.somesite.no/wiki/display/Drift/Domeneoversikt

