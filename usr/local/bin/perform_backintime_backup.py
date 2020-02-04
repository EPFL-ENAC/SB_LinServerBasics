#!/usr/bin/env python3

"""
Does :
+ Do backup with backintime
+ Send metrics to ENAC-IT's graylog
"""

import os
import re
import pprint
import logging
import datetime
import subprocess
from pygelf import GelfTcpHandler

SERVER_HOSTNAME = os.uname()[1]

LOG_FILE = "/tmp/daily_server_backintime_backup.log"
LAST_SNAP_PATH_CMD = ["/usr/bin/nice", "-n", "19", "/usr/bin/ionice", "-c2", "-n7", "/usr/bin/backintime", "last-snapshot-path"]
BKP_CMD = ["/usr/bin/nice", "-n", "19", "/usr/bin/ionice", "-c2", "-n7", "/usr/bin/backintime", "backup"]
BKP_MOUNT_POINT = "/bkp"

GRAYLOG_SERVER = "enacit1sbtest4.epfl.ch"
GRAYLOG_PORT = 12202

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger()
logger.addHandler(GelfTcpHandler(host=GRAYLOG_SERVER, port=GRAYLOG_PORT, include_extra_fields=True))


state = {
    "commands": [],
    "previous_snapshot_path": None,
    "current_snapshot_path": None,
    "incr_size": None,
    "total_size": None,
    "chrono": None,
    "success": None,
}

def run_cmd(cmd):
    bkp_p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
    stdout, stderr = bkp_p.communicate()
    retcode = bkp_p.returncode
    state["commands"].append({
        "cmd": cmd,
        "stdout": stdout,
        "stderr": stderr,
        "retcode": retcode,
    })
    return stdout, stderr, retcode

def get_last_snapshot_path():
    stdout, stderr, retcode = run_cmd(LAST_SNAP_PATH_CMD)
    for l in stdout.split("\n"):
        m = re.match(r"SnapshotPath:\s+(\/.*)$", l)
        if m:
            return m.group(1)
    return None

def do_backup():
    stdout, stderr, retcode = run_cmd(BKP_CMD)

def get_disk_usage():
    stdout, stderr, retcode = run_cmd(["/bin/mount", BKP_MOUNT_POINT])
    if state["current_snapshot_path"] == state["previous_snapshot_path"]:
        state["incr_size"] = 0
    else:
        stdout, stderr, retcode = run_cmd(["/usr/bin/du", "-sk", state["previous_snapshot_path"], state["current_snapshot_path"]])
        for l in stdout.split("\n"):
            if l.endswith(state["current_snapshot_path"]):
                state["incr_size"] = int(re.findall(r"(\d+)", l)[0])
                break
    stdout, stderr, retcode = run_cmd(["/usr/bin/du", "-sk", state["current_snapshot_path"]])
    for l in stdout.split("\n"):
        if l.endswith(state["current_snapshot_path"]):
            state["total_size"] = int(re.findall(r"(\d+)", l)[0])
            break
    stdout, stderr, retcode = run_cmd(["/bin/umount", BKP_MOUNT_POINT])

def report_to_graylog():
    state["success"] = "yes"
    for cmd in state["commands"]:
        if cmd["retcode"] != 0:
            state["success"] = "no"
    logging.info('Backup of ' + SERVER_HOSTNAME, extra=state)
    # pprint.pprint(state)

if __name__ == "__main__":
    start_time = datetime.datetime.now()

    state["previous_snapshot_path"] = get_last_snapshot_path()
    do_backup()
    state["current_snapshot_path"] = get_last_snapshot_path()
    get_disk_usage()

    state["chrono"] = (datetime.datetime.now() - start_time).__str__()

    report_to_graylog()
