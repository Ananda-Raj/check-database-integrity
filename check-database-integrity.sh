#!/bin/bash

# Script to check daily database backup integrity
# Author: Ananda Raj
# Date: 31 Jan 2020
# Version 1.31012020


echo "###################################################"
echo "$(date +%H:%M:%S) Execution Started"
echo "###################################################"

##### Create work directory if doesn't exist
if [ ! -f /usr/local/mysql-temp/ ]; then
	echo "$(date +%H:%M:%S) Created work directory /usr/local/mysql-temp/"
        mkdir /usr/local/mysql-temp
fi


##### Checking individual backup files for completion.
check-backup()	
{
	echo "$(date +%H:%M:%S) Entered function check-backup for array index $i and value ${dbarray[i]}"
	if zgrep -q "Dump completed on" ${dbarray[i]}; then 
		echo "$(date +%H:%M:%S) Dump Complete for ${dbarray[i]}" >> /usr/local/mysql-temp/$(date +%d)-dump-complete.log
	else
		echo "$(date +%H:%M:%S) Dump Not Complete for ${dbarray[i]}" >> /usr/local/mysql-temp/$(date +%d)-dump-not-complete.log
	fi
}


##### Create list of backup files.
find /home/mysqlbackup/ -name "*.sql.gz" -type f -mtime -1 > /usr/local/mysql-temp/$(date +%d)-database-list.log


##### Declare array.
declare -a dbarray


##### Load file into array.
readarray dbarray < /usr/local/mysql-temp/$(date +%d)-database-list.log


##### Perform operation. 
let i=0

while (( ${#dbarray[@]} > i )); do
echo "$(date +%H:%M:%S) Entered WHILE loop, starting operation..."
JOBS=$(jobs | wc -l)
echo "$(date +%H:%M:%S) Current number of jobs = $JOBS"

# Change value depending on core
	if [ $JOBS -lt 30 ]
		then
			echo "$(date +%H:%M:%S) Entered IF loop, checking file ${dbarray[i]}..."
	    		check-backup &
			i=$i+1
        else
			echo "$(date +%H:%M:%S) Entered ELSE loop, waiting for jobs to complete..."
			JOBS=$(jobs | wc -l)
			while [ $JOBS -ge 30 ]
				do 
			                echo "$(date +%H:%M:%S) Waiting 10 seconds..."
			                sleep 10
		              		JOBS=$(jobs | wc -l)
					echo "$(date +%H:%M:%S) Number of jobs after sleep = $JOBS"
                		done
			echo "$(date +%H:%M:%S) Checking file from ELSE loop..."
    			check-backup &
			i=$i+1
        fi
done


##### Checking any running jobs

JOBS=$(jobs | wc -l)
while [ $JOBS -gt 0 ]
        do
                echo "$(date +%H:%M:%S) $JOBS jobs waiting to be completed..."
		JOBS=$(jobs | wc -l)
            	jobs
                sleep 10
        done


##### Removing old log files

res=$(echo "$(date +%d) - 5" | bc)
find /usr/local/mysql-temp/ -name $res*.log -type f -exec rm -rf {} \;
echo "$(date +%H:%M:%S) Removed logs older than 5 days"


##### Alerting to Slack channel r1soft-mysql-backups

completed=$(echo "$(cat /usr/local/mysql-temp/$(date +%d)-dump-complete.log | wc -l) / 2" | bc)
ncompleted=$(echo "$(cat /usr/local/mysql-temp/$(date +%d)-dump-not-complete.log | wc -l) / 2" | bc)
list=$(cat /usr/local/mysql-temp/$(date +%d)-dump-not-complete.log)

#To Slack
curl -X POST --data-urlencode "payload={\"channel\": \"#mysql-backups-alert\", \"text\": \"\n\n\n*Failed MySQL Database Report:*\n\n$list\n\n\"}" https://hooks.slack.com/services/xxxxxxxxx/xxxxxxxxx/xxxxxxxxxxxxxxxxxxxxxxxx

curl -X POST --data-urlencode "payload={\"channel\": \"#mysql-backups-alert\", \"text\": \"\n\n\n*Total Complete database backups:* $completed\n\n*Total Incomplete database backups:* $ncompleted\n\n\"}" https://hooks.slack.com/services/xxxxxxxxx/xxxxxxxxx/xxxxxxxxxxxxxxxxxxxxxxxx


echo "###################################################"
echo "$(date +%H:%M:%S) Execution Completed"
echo "Total Complete database backups: $completed\nTotal Incomplete database backups: $ncompleted"
echo "###################################################"
