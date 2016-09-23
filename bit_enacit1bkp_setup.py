#!/usr/bin/env python3

# Bancal Samuel

"""
Script to setup Backup of server (as root) on enacit1bkp.epfl.ch
"""

import os
import grp
import sys
import json
import socket
import random
import hashlib
# import pprint
import getpass
import platform
import subprocess
from functools import partial

USER = getpass.getuser()
OS_DISTRIB, OS_VERSION = platform.linux_distribution()[:2]
SUPPORTED_OS = (
    ("Ubuntu", "14.04"),
    ("Ubuntu", "16.04"),
)
HOSTNAME = socket.gethostname()

class Section():
    """
        Displays nice section with trailing [OK] or [FAILED]
    """
    def __init__(self, name):
        self.name = name
        self.status = "OK"

    def __enter__(self):
        print("* {}".format(self.name), end=": ")
        return self

    def __exit__(self, typ, value, traceback):
        colors = {
            "OK": 32,  # Green
            "FAILED": 31,  # Red
        }
        if typ is not None:
            self.status = "FAILED"
        print("... [\033[01;{}m{}\033[00m]".format(colors[self.status], self.status))

    def say(self, msg):
        "Display msg in current section"
        print(msg, end=" ")

    def fatal_error(self, msg=""):
        "remember error status, display msg if provided and exit(1)"
        self.status = "FAILED"
        if msg != "":
            print("ERROR: " + msg, end="")
        sys.exit(1)

def requisite_checks():
    """
        Check :
        + user root
        + Ubuntu supported
    """
    with Section("User is root") as sect:
        if USER != "root":
            sect.fatal_error("You have to run this as root")

    with Section("Os is supported"):
        if (OS_DISTRIB, OS_VERSION) not in SUPPORTED_OS:
            sect.fatal_error("{} {} is not supported.".format(OS_DISTRIB, OS_VERSION))

def install_package():
    """
    Install packages
    + backintime-common from PPA for Ubuntu 14.04
    + backintime-common from official repos
    """
    if OS_DISTRIB == "Ubuntu" and OS_VERSION == "14.04":
        with Section("apt-add-repository -y ppa:bit-team/stable") as sect:
            if os.path.exists("/etc/apt/sources.list.d/bit-team-stable-trusty.list"):
                sect.say("already done")
            else:
                return_code = subprocess.call(["apt-add-repository", "-y", "ppa:bit-team/stable"])
                if return_code != 0:
                    sect.fatal_error("Error while adding PPA")
        with Section("apt-get update") as sect:
            return_code = subprocess.call(["apt-get", "update"])
            if return_code != 0:
                sect.fatal_error("Error while apt-get update")
        with Section("apt-get -y install backintime-common") as sect:
            return_code = subprocess.call(["apt-get", "-y", "install", "backintime-common"])
            if return_code != 0:
                sect.fatal_error("Error while apt-get -y install backintime-common")
    elif OS_DISTRIB == "Ubuntu" and OS_VERSION == "16.04":
        with Section("apt update") as sect:
            return_code = subprocess.call(["apt", "update"])
            if return_code != 0:
                sect.fatal_error("Error while apt update")
        with Section("apt -y install backintime-common sshfs") as sect:
            return_code = subprocess.call(["apt", "-y", "install", "backintime-common", "sshfs"])
            if return_code != 0:
                sect.fatal_error("Error while apt -y install backintime-common")


def ssh_setup():
    """
        Setup ssh pub/priv keys
    """
    ssh_private_key = "/root/.ssh/id_rsa_backups_{}".format(HOSTNAME)
    with Section("Generate public/private ssh key {}".format(ssh_private_key)) as sect:
        if os.path.exists(ssh_private_key):
            sect.say("already done")
        else:
            return_code = subprocess.call(["ssh-keygen", "-t", "rsa", "-N", "", "-C", "Backups {}".format(HOSTNAME), "-f", ssh_private_key])
            if return_code != 0:
                sect.fatal_error("Error while ssh-keygen")

    with Section("Save enacit1bkp host public keys to known hosts") as sect:
        try:
            output = subprocess.check_output(["ssh-keyscan", "enacit1bkp.epfl.ch"], stderr=subprocess.DEVNULL, universal_newlines=True)
            if output == "":
                with open("/root/.ssh/id_rsa_backups_{}.pub".format(HOSTNAME), "r") as f:
                    lines = f.readlines()
                sect.fatal_error("Could not get enacit1bkp ssh public key.\n"
                                 "Please open firewall and add the following "
                                 "pub key to h_{}@enacit1bkp : \n{}\n".format(HOSTNAME, "".join(lines)))
            key_entries = output.strip().split("\n")
            with open("/root/.ssh/known_hosts", mode="a") as f:
                pass
            with open("/root/.ssh/known_hosts", mode="r+") as f:
                for line in f.readlines():
                    line = line.strip()
                    if line in key_entries:
                        key_entries.remove(line)
                if len(key_entries) == 0:
                    sect.say("All keys already present.")
                else:
                    for line in key_entries:
                        f.write(line + "\n")
        except subprocess.CalledProcessError:
            with open("/root/.ssh/id_rsa_backups_{}.pub".format(HOSTNAME), "r") as f:
                lines = f.readlines()
            sect.fatal_error("Could not get enacit1bkp ssh public key.\n"
                             "Please open firewall and add the following pub "
                             "key to h_{}@enacit1bkp : \n{}\n".format(HOSTNAME, "".join(lines)))

def bit_config():
    """
    Create config file for BackInTime
    """

    def path_type(path):
        "return 0 for folder, 1 for file"
        if not os.path.exists(path):
            return 0
        elif os.path.isdir(path):
            return 0
        else:
            return 1

    conf_include = """\
profile1.snapshots.include.{num}.type={type}
profile1.snapshots.include.{num}.value={path}
"""
    conf_exclude = """\
profile1.snapshots.exclude.{num}.value={path}
"""
    conf = """\
profile1.snapshots.automatic_backup_day=1
profile1.snapshots.automatic_backup_mode=0
profile1.snapshots.automatic_backup_time=0
profile1.snapshots.automatic_backup_weekday=7
profile1.snapshots.backup_on_restore.enabled=true
profile1.snapshots.bwlimit.enabled=false
profile1.snapshots.bwlimit.value=3000
profile1.snapshots.check_for_changes=true
profile1.snapshots.continue_on_errors=true
profile1.snapshots.copy_links=false
profile1.snapshots.copy_unsafe_links=false
profile1.snapshots.cron.ionice=true
profile1.snapshots.cron.nice=true
profile1.snapshots.custom_backup_time=8,12,18,23
profile1.snapshots.dont_remove_named_snapshots=true
{excludes}
profile1.snapshots.exclude.size={nb_excludes}
profile1.snapshots.full_rsync=false
{includes}
profile1.snapshots.include.size={nb_includes}
profile1.snapshots.local_encfs.path=
profile1.snapshots.log_level=3
profile1.snapshots.min_free_space.enabled=true
profile1.snapshots.min_free_space.unit=20
profile1.snapshots.min_free_space.value=1
profile1.snapshots.mode=ssh
profile1.snapshots.no_on_battery=false
profile1.snapshots.notify.enabled=true
profile1.snapshots.path=
profile1.snapshots.path.auto=true
profile1.snapshots.path.host={hostname}
profile1.snapshots.path.profile=1
profile1.snapshots.path.user={username}
profile1.snapshots.preserve_acl=false
profile1.snapshots.preserve_xattr=false
profile1.snapshots.remove_old_snapshots.enabled=true
profile1.snapshots.remove_old_snapshots.unit=80
profile1.snapshots.remove_old_snapshots.value=10
profile1.snapshots.smart_remove=true
profile1.snapshots.smart_remove.keep_all=2
profile1.snapshots.smart_remove.keep_one_per_day=7
profile1.snapshots.smart_remove.keep_one_per_month=24
profile1.snapshots.smart_remove.keep_one_per_week=4
profile1.snapshots.ssh.cipher=default
profile1.snapshots.ssh.host=enacit1bkp.epfl.ch
profile1.snapshots.ssh.password.save=false
profile1.snapshots.ssh.password.use_cache=true
profile1.snapshots.ssh.path=/bkp_storage/h_{hostname}/
profile1.snapshots.ssh.port=22
profile1.snapshots.ssh.private_key_file=/root/.ssh/id_rsa_backups_{hostname}
profile1.snapshots.ssh.user=h_{hostname}
profile1.snapshots.use_checksum=false
profile1.snapshots.user_backup.ionice=false
profiles.version=1
"""
    with Section("Parsing config in ./bit_enacit1bkp_conf.json") as sect:
        with open("./bit_enacit1bkp_conf.json", "r") as f:
            user_conf = json.load(f)
        if "include" not in user_conf:
            sect.fatal_error("Missing include definition in config file")
        if "exclude" not in user_conf:
            sect.fatal_error("Missing exclude definition in config file")

    print("-> Going to include: {}".format(user_conf["include"]))
    print("-> Going to exclude: {}".format(user_conf["exclude"]))

    with Section("Saving config to /root/.config/backintime/config"):
        os.makedirs("/root/.config/backintime", exist_ok=True)
        includes = ""
        excludes = ""
        i = 1
        for path in user_conf["include"]:
            includes += conf_include.format(path=path, type=path_type(path), num=i)
            i += 1
        i = 1
        for path in user_conf["exclude"]:
            excludes += conf_exclude.format(path=path, num=i)
            i += 1
        with open("/root/.config/backintime/config", "w") as f:
            f.write(conf.format(
                includes=includes.strip(), nb_includes=len(user_conf["include"]),
                excludes=excludes.strip(), nb_excludes=len(user_conf["exclude"]),
                hostname=HOSTNAME, username=USER))

def user_root():
    "Check that root belongs to group fuse"

    if OS_DISTRIB == "Ubuntu" and OS_VERSION == "14.04":
        with Section("Check root belongs to group fuse") as sect:
            group_fuse = grp.getgrnam("fuse")
            if "root" not in group_fuse.gr_mem:
                return_code = subprocess.call(["adduser", "root", "fuse"])
                if return_code != 0:
                    sect.fatal_error("Error while adding fuse membership to root")
                sect.fatal_error("Please logout & login again in order root belongs to fuse group.")

def check_ssh():
    "Check ssh to server can be established"
    with Section("Check ssh connection to server") as sect:
        try:
            return_code = subprocess.call([
                "ssh", "h_{}@enacit1bkp.epfl.ch".format(HOSTNAME),
                "-o", "BatchMode=yes",
                "-i", "/root/.ssh/id_rsa_backups_{}".format(HOSTNAME), "id"], stdout=subprocess.DEVNULL, timeout=2)
            if return_code != 0:
                with open("/root/.ssh/id_rsa_backups_{}.pub".format(HOSTNAME), "r") as f:
                    lines = f.readlines()
                sect.fatal_error("Error connecting through ssh to enacit1bkp\nPlease add the following pub key to h_{}@enacit1bkp : \n{}\n".format(HOSTNAME, "".join(lines)))
        except subprocess.TimeoutExpired:
            with open("/root/.ssh/id_rsa_backups_{}.pub".format(HOSTNAME), "r") as f:
                lines = f.readlines()
            sect.fatal_error("Error connecting through ssh to enacit1bkp\nPlease add the following pub key to h_{}@enacit1bkp : \n{}\n".format(HOSTNAME, "".join(lines)))

def set_cron():
    "setup cron for a daily backup"
    with Section("Set cron backup in /etc/cron.d/backintime") as sect:
        if os.path.exists("/etc/cron.d/backintime"):
            sect.say("cron file already exists -> skip")
        else:
            hour = random.randrange(0, 4, 1)
            minute = random.randrange(0, 60, 1)
            sect.say("Will occur daily at {hour}:{minute}:00".format(hour=hour, minute=minute))
            with open("/etc/cron.d/backintime", "w") as f:
                f.write("""\
# m h dom mon dow user  command
{minute} {hour} * * * root /usr/bin/nice -n 19 /usr/bin/ionice -c2 -n7 /usr/bin/backintime backup-job >/dev/null
""".format(hour=hour, minute=minute))

def patch_bit():
    "Patch bug in "

    def md5(filename):
        "Returns a md5 hash of file content"
        md5_hash = hashlib.md5()
        with open(filename, "rb") as f:
            for chunk in iter(partial(f.read, 4096), b""):
                md5_hash.update(chunk)
        return md5_hash.hexdigest()

    corrections = [
        {
            "filename": "/usr/share/backintime/common/tools.py",
            "md5": "2fd0128058b440b369efef0f902de5cf",
            "patch": """\
--- /usr/share/backintime/common/tools.py.orig	2015-11-24 09:19:24.441153752 +0100
+++ /usr/share/backintime/common/tools.py	2015-11-24 09:20:37.189647756 +0100
@@ -745,6 +745,9 @@
             return (cookie, bus, dbus_props)
         except dbus.exceptions.DBusException:
             pass
+    if isRoot():
+        logger.debug("Inhibit Suspend failed because BIT was started as root.")
+        return
     logger.warning('Inhibit Suspend failed.')

 def unInhibitSuspend(cookie, bus, dbus_props):
"""
        }
    ]

    for corr in corrections:
        with Section("patching {} {}".format(corr["filename"], corr["md5"])) as sect:
            if os.path.exists(corr["filename"]) and md5(corr["filename"]) == corr["md5"]:
                try:
                    proc = subprocess.Popen(["patch", "-f", "-p0"], stdin=subprocess.PIPE, cwd="/")
                    proc.communicate(input=corr["patch"].encode("utf-8"), timeout=2)
                    if proc.returncode != 0:
                        sect.fatal_error("Could not patch file")
                except subprocess.TimeoutExpired:
                    sect.fatal_error("Could not patch file")
            else:
                sect.say("not needed")

def check_bit_config():
    "Check BackInTime config"
    with Section("BackInTime check config") as sect:
        return_code = subprocess.call(["backintime", "check-config"])
        if return_code != 0:
            sect.fatal_error("Error!")


if __name__ == "__main__":
    requisite_checks()
    install_package()
    ssh_setup()
    bit_config()
    user_root()
    check_ssh()
    set_cron()
    patch_bit()
    check_bit_config()
    sys.exit(0)
