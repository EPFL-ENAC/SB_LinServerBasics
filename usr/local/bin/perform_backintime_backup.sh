#!/bin/bash
# Bancal Samuel
# 2016-09-23

log_file="/tmp/daily_server_backintime_backup.log"

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

# Backup
r 0 /usr/bin/nice -n 19 /usr/bin/ionice -c2 -n7 /usr/bin/backintime backup-job

# Central-Log
if [ "${email_the_admin}" = true ]; then
    /usr/local/bin/enacit1logs.py -t server_backintime -t notify -f ${log_file}
else
    /usr/local/bin/enacit1logs.py -t server_backintime -f ${log_file}
fi
