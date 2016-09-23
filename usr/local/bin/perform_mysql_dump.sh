#!/bin/bash
# Bancal Samuel
# 2014.03.31

###
### + MySQL DUMP with DAY_NUMBER
### + keep only 7 localy
### + copy to backup server
### + keep 31 on backup server
###

host=$(hostname)
filename_prefix="${host}"
log_file="/tmp/daily_server_mysql_backup.log"

db_user="root"
db_name="--all-databases"

local_dst_folder="/mysql_dump/"
today_file=${filename_prefix}_$(date +"%j").dump

remote_server="enacit1bkp.epfl.ch"
remote_dst_folder="/bkp_storage/h_${host}/mysql_dump/"

local_nb_dumps_to_keep=7
remote_nb_dumps_to_keep=31
local_file_to_remove=${filename_prefix}_$(date --date="${local_nb_dumps_to_keep} days ago" +"%j").dump
remote_file_to_remove=${filename_prefix}_$(date --date="${remote_nb_dumps_to_keep} days ago" +"%j").dump

ssh_key=/root/.ssh/id_rsa_backups_${host}

email_the_admin=false

function r {
    status_expected=$1
    echo "___ RUN ___" >> ${log_file}
    echo "${@:2}" >> ${log_file}
    "${@:2}" >> ${log_file} 2>&1
    status=$?
    if [ $status -ne $status_expected ]; then
        echo "___ ERROR, it returned $status ___" >> ${log_file}
        email_the_admin=true
    else
        echo "___ OK, it returned $status ___" >> ${log_file}
    fi
    echo >> ${log_file}
    return $status
}

# Clear log file
cat /dev/null > ${log_file}

# Dump
r 0 mysqldump -u ${db_user} --events ${db_name} -r ${local_dst_folder}${today_file}

# Local Cleanup
r 0 rm -f ${local_dst_folder}${local_file_to_remove}

# Copy to backup server
r 0 ssh -i ${ssh_key} h_${host}@${remote_server} mkdir -p ${remote_dst_folder}
r 0 scp -i ${ssh_key} ${local_dst_folder}${today_file} h_${host}@${remote_server}:${remote_dst_folder}

# Remote Cleanup
r 0 ssh -i ${ssh_key} h_${host}@${remote_server} rm -f ${remote_dst_folder}${remote_file_to_remove}

if [ "$email_the_admin" = true ]; then
    /usr/local/bin/enacit1logs.py -t server_mysqldump -t notify_bancal -f ${log_file}
else
    /usr/local/bin/enacit1logs.py -t server_mysqldump -f ${log_file}
fi
