# check-database-integrity
Check if given compressed MySQL Database dumps are complete.

The script will take the list of one day old databases files (compressed gz) from specified location (/home/mysqlbackup/), first to a file and then loaded to an array. 
The database is checked for the string "Dump completed on" and then written to a log file. 
The execution is done as jobs, to enable multiple databases to be checked concurrently, decreasing execution time. (Here the value is 30)
All logs are stored in a location (/usr/local/mysql-temp/) and logs older than 5 days are removed. 
The results are pushed into slack. 

Execution time:
For 10 1.6GB compressed (gz) database dump files, it will take ~2 minutes when all the 10 are executed concurrently. 


You can add a cronjob similar to below to check this regularly.

0 12 * * * /bin/bash /root/check-db-integrity.sh > /usr/local/mysql-temp/\`date "+\%d"\`-check-db-integrity-execution.log 2> /usr/local/mysql-temp/\`date "+\%d"\`-check-db-integrity-execution-err.log
