#!/bin/bash
# Bancal Samuel
# 2016-09-23

###
### + MySQL DUMP with DAY_NUMBER
### + keep last 31
###

host=$(hostname)
filename_prefix="${host}"
log_file="/tmp/daily_server_mysql_backup.log"

db_user="root"
db_name="--all-databases"

mnt_folder="/bkp_db"
bkp_folder="/bkp_db/mysql_dump/"
today_file=${filename_prefix}_$(date +"%j").dump

nb_dumps_to_keep=31
file_to_remove=${filename_prefix}_$(date --date="${nb_dumps_to_keep} days ago" +"%j").dump

email_the_admin=false

function r {
    status_expected=$1
    echo "___ RUN ___" >> ${log_file}
    echo "${@:2}" >> ${log_file}
    "${@:2}" >> ${log_file} 2>&1
    status=$?
    if [ ${status} -ne ${status_expected} ]; then
        echo "___ ERROR, it returned ${status} ___" >> ${log_file}
        email_the_admin=true
    else
        echo "___ OK, it returned ${status} ___" >> ${log_file}
    fi
    echo >> ${log_file}
    return ${status}
}

# Clear log file
cat /dev/null > ${log_file}

# Mount
r 0 mount ${mnt_folder}

# Create dest dir
r 0 mkdir -p ${bkp_folder}

# Dump
r 0 mysqldump -u ${db_user} --events ${db_name} -r ${bkp_folder}${today_file}

# Cleanup
r 0 rm -f ${bkp_folder}${file_to_remove}

# uMount
r 0 umount ${mnt_folder}

# Central-Log
if [ "${email_the_admin}" = true ]; then
    /usr/local/bin/enacit1logs.py -t server_mysqldump -t notify -f ${log_file}
else
    /usr/local/bin/enacit1logs.py -t server_mysqldump -f ${log_file}
fi
