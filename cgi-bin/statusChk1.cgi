#!/bin/sh
#ssh -F /var/www/.ssh/config -v rasp@172.16.10.2 /home/rasp/RASP/RUN/status.sh 2>&1 > /tmp/status.out
ssh 172.16.10.2 /home/rasp/RASP/RUN/status1.sh
