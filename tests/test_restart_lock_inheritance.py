"""Local fixtures execute real launch functions; no router entry point is sourced."""

import fcntl
import json
import os
from pathlib import Path
import re
import shlex
import signal
import subprocess
import sys
import tempfile
import time
import unittest


ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / "fancyss/ss/ssconfig.sh"
BASE = ROOT / "fancyss/scripts/ss_base.sh"


def function(path, name):
    match = re.search(r"^" + re.escape(name) + r"\(\)\s*\{.*?^\}",
                      path.read_text(), re.M | re.S)
    if match is None:
        raise AssertionError(f"Missing production function: {name}")
    return match.group(0)


class RestartLockInheritanceTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="restart-lock-")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        (self.root / "upload").mkdir()
        self.lock = self.root / "koolss.lock"
        self.probe = self.bin / "probe"
        self.executable(self.probe, f"""#!{sys.executable}
import json, os, sys, time
from pathlib import Path
try:
    os.fstat(1000)
    inherited = True
except OSError:
    inherited = False
name = Path(__file__).name
if name == 'probe':
    import sys
    name = sys.argv[1]
Path({str(self.root)!r}, name + '.json').write_text(json.dumps(
    {{'fd_open': inherited, 'pid': os.getpid()}}))
if name != 'sync' and '--once' not in sys.argv:
    while True:
        time.sleep(1)
""")

    def executable(self, path, content):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)
        path.chmod(0o755)

    def source(self, *names):
        source = "\n".join(function(CONFIG, name) for name in names)
        return source.replace("/koolshare", str(self.root / "koolshare")).replace(
            "/tmp/upload", str(self.root / "upload"))

    def start_owner(self, source, body):
        # Python supplies flock on macOS too, using the shell's inherited FD.
        flock_code = "import fcntl,sys; fcntl.flock(int(sys.argv[2]), fcntl.LOCK_UN if sys.argv[1]=='-u' else fcntl.LOCK_EX)"
        prefix = f"""
ulimit -n 2048 || exit 91
LOCK_FILE={shlex.quote(str(self.lock))}
flock(){{ {shlex.quote(sys.executable)} -c {shlex.quote(flock_code)} "$@"; }}
echo_date(){{ :; }}
{function(CONFIG, 'set_lock')}
{function(CONFIG, 'unset_lock')}
{source}
set_lock || exit
{body}
: > {shlex.quote(str(self.root / 'ready'))}
read -r release
unset_lock
"""
        process = subprocess.Popen(
            ["bash", "-c", prefix], stdin=subprocess.PIPE,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
            start_new_session=True,
            env={"PATH": f"{self.bin}:{os.defpath}"},
        )
        self.addCleanup(self.cleanup_owner, process)
        self.wait_file("ready", process)
        return process

    @staticmethod
    def cleanup_owner(process):
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        process.communicate(timeout=5)

    def wait_file(self, name, process=None):
        path = self.root / name
        deadline = time.monotonic() + 5
        while time.monotonic() < deadline:
            if path.exists() and (not name.endswith('.json') or path.stat().st_size):
                return path
            if process is not None and process.poll() is not None:
                stdout, stderr = process.communicate(timeout=1)
                self.fail(f"Owner exited {process.returncode}: {stdout}{stderr}")
            time.sleep(0.01)
        self.fail(f"Missing fixture event: {name}")

    def can_lock(self):
        with self.lock.open("a") as handle:
            try:
                fcntl.flock(handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError:
                return False
            fcntl.flock(handle, fcntl.LOCK_UN)
            return True

    def assert_isolated(self, owner, *names):
        records = [json.loads(self.wait_file(name + ".json").read_text())
                   for name in names]
        self.assertFalse(self.can_lock(), "launch closed/unlocked the owner's lock")
        for name, record in zip(names, records):
            with self.subTest(launch=name):
                self.assertFalse(record["fd_open"], "child inherited FD1000")
        return records

    def test_real_helpers_close_child_fd_but_keep_owner_locked(self):
        source = "\n".join(function(BASE, name)
                           for name in ("run", "run_bg", "run_bg_detached"))
        probe = shlex.quote(str(self.probe))
        owner = self.start_owner(source, f"""
run {probe} sync
run_bg {probe} background
run_bg_detached {probe} detached
""")
        self.assert_isolated(owner, "sync", "background", "detached")

    def test_killed_owner_releases_lock_while_real_helper_daemon_survives(self):
        owner = self.start_owner(function(BASE, "run_bg_detached"),
                                 f"run_bg_detached {shlex.quote(str(self.probe))} survivor")
        record = json.loads(self.wait_file("survivor.json").read_text())
        self.assertFalse(self.can_lock())
        os.kill(owner.pid, signal.SIGKILL)
        owner.wait(timeout=5)
        os.kill(record["pid"], 0)
        self.assertTrue(self.can_lock(), "surviving daemon retained owner's lock")

    def test_real_check_status_isolates_daemon_main_and_dns_children(self):
        scripts = self.root / "koolshare/scripts"
        probe = shlex.quote(str(self.probe))
        self.executable(scripts / "ss_status_daemon.sh", f"#!/bin/sh\n{probe} status-daemon &\n{probe} status-serve &\n")
        self.executable(scripts / "ss_status_main.sh", f"#!/bin/sh\nexec {probe} status-main\n")
        self.executable(self.bin / "dnsclient", f"#!/bin/sh\nexec {probe} \"$7\"\n")
        source = self.source("check_status") + "\n" + function(BASE, "run_bg")
        owner = self.start_owner(source, "dbus(){ :; }; ss_failover_enable=1; check_status")
        self.assert_isolated(owner, "status-daemon", "status-serve", "status-main",
                             "openai.com", "chat.openai.com", "stun.syncthing.net")

    def websocket_source(self, use_ssd):
        websocketd = self.root / "koolshare/bin/websocketd"
        self.executable(websocketd, self.probe.read_text())
        (self.root / "koolshare/ss").mkdir(parents=True)
        (self.root / "koolshare/ss/websocket").touch()
        ssd = self.bin / "start-stop-daemon"
        self.executable(ssd, '#!/bin/sh\nwhile [ "$1" != "-x" ]; do shift; done\nshift\nprogram="$1"\nshift 2\n"$program" "$@" &\n')
        return self.source("start_ws") + f"""
get_ws_master_pid(){{ :; }}
sync_ws_pidfile(){{ :; }}
cleanup_ws_shells_once(){{ :; }}
pick_start_stop_daemon(){{ printf '%s' {shlex.quote(str(ssd) if use_ssd else '')}; }}
WS_PIDFILE={shlex.quote(str(self.root / 'websocket.pid'))}
"""

    def test_real_start_ws_ssd_does_not_inherit_lock(self):
        owner = self.start_owner(self.websocket_source(True), "start_ws")
        self.assert_isolated(owner, "websocketd")

    def test_real_start_ws_fallback_does_not_inherit_lock(self):
        owner = self.start_owner(self.websocket_source(False), "start_ws")
        self.assert_isolated(owner, "websocketd")

    def test_real_obfs_script_call_does_not_inherit_lock(self):
        source = self.source("write_ss_obfs_start_script", "start_ss_obfs_helper")
        self.executable(self.bin / "obfs-local", self.probe.read_text())
        self.executable(self.bin / "netstat", '#!/bin/sh\nprintf "tcp 0 0 127.0.0.1:12345\\n"\n')
        (self.root / "koolshare/ss").mkdir(parents=True)
        owner = self.start_owner(source, f"""
detect_running_status(){{ :; }}
write_ss_obfs_start_script {shlex.quote(str(self.root / 'koolshare/ss/start-obfs.sh'))} example.com 443 12345 http '' ''
start_ss_obfs_helper
""")
        self.assert_isolated(owner, "obfs-local")

    def test_real_user_hooks_do_not_inherit_lock(self):
        hook = self.root / "koolshare/ss/postscripts/P01-fixture"
        self.executable(hook, f'#!/bin/sh\nexec {shlex.quote(str(self.probe))} "hook-$1" --once\n')
        owner = self.start_owner(self.source("ss_post_start", "ss_pre_stop"),
                                 "ss_post_start; ss_pre_stop")
        self.assert_isolated(owner, "hook-start", "hook-stop")

    def test_real_dnsmasq_service_does_not_inherit_lock(self):
        resolv = self.root / "resolv.conf"
        resolv.write_text("nameserver 127.0.0.1\n")
        self.executable(self.bin / "service", self.probe.read_text())
        source = self.source("restart_dnsmasq").replace("/etc/resolv.conf", str(resolv))
        owner = self.start_owner(source, "nvram(){ printf '1'; }; detect_running_status(){ :; }; restart_dnsmasq")
        self.assert_isolated(owner, "service")


if __name__ == "__main__":
    unittest.main()
