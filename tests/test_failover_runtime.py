"""Fixture-only failover regressions; never source or run router entry points."""

import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import tempfile
import time
import unittest


ROOT = Path(__file__).resolve().parents[1]
CONFIG = "fancyss/ss/ssconfig.sh"
STATUS = "fancyss/scripts/ss_status_main.sh"


def function(path, name):
    return re.search(r"^" + re.escape(name) + r"\(\)\s*\{.*?^\}",
                     (ROOT / path).read_text(), re.M | re.S).group(0)


class FailoverRuntimeTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="failover-fixture-")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.env = dict(PATH=os.defpath, FIXTURE=str(self.root), PYTHON=sys.executable)

    def start_shell(self, source, body, **env):
        process = subprocess.Popen(
            ["bash", "-c", source + "\n" + body],
            env=dict(self.env, **env), stdin=subprocess.PIPE,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
            start_new_session=True,
        )
        self.addCleanup(self.stop_shell, process)
        return process

    @staticmethod
    def stop_shell(process):
        if process.poll() is None:
            os.killpg(process.pid, signal.SIGKILL)
        process.communicate(timeout=5)

    def wait_for(self, *names):
        deadline = time.monotonic() + 5
        while time.monotonic() < deadline:
            for name in names:
                if (self.root / name).exists():
                    return name
            time.sleep(0.01)
        self.fail(f"No fixture event within five seconds: {names}")

    def release(self, process):
        process.stdin.write("release\n")
        process.stdin.flush()
        stdout, stderr = process.communicate(timeout=5)
        self.assertEqual(process.returncode, 0, stdout + stderr)
        return stdout

    def lock_source(self):
        # Use the inherited descriptor, just like the router's flock applet.
        # The nonblocking probe records actual contention before blocking.
        bridge = self.root / "flock.py"
        bridge.write_text('''import fcntl
import os
from pathlib import Path
import sys

fd = int(sys.argv[2])
if sys.argv[1] == "-u":
    fcntl.flock(fd, fcntl.LOCK_UN)
else:
    try:
        fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        (Path(os.environ["FIXTURE"]) / (os.environ["ROLE"] + ".queued")).touch()
        fcntl.flock(fd, fcntl.LOCK_EX)
''')
        return "\n".join((
            'ulimit -n 2048 || exit 91',
            'LOCK_FILE="$FIXTURE/koolss.lock"',
            'flock(){ "$PYTHON" "$FIXTURE/flock.py" "$@"; }',
            function(CONFIG, "set_lock"), function(CONFIG, "unset_lock"),
        ))

    def test_unlock_preserves_inode_and_closes_fd(self):
        process = self.start_shell(self.lock_source(), '''
set_lock || exit
: > "$FIXTURE/A.held"
read -r release
unset_lock || exit
if "$PYTHON" -c 'import os; os.fstat(1000)' 2>/dev/null; then
    printf 'fd-open\n'
else
    printf 'fd-closed\n'
fi
''', ROLE="A")
        self.wait_for("A.held")
        inode = (self.root / "koolss.lock").stat().st_ino
        stdout = self.release(process)
        with self.subTest("persistent lock pathname"):
            self.assertTrue((self.root / "koolss.lock").exists())
            self.assertEqual((self.root / "koolss.lock").stat().st_ino, inode)
        with self.subTest("descriptor closed"):
            self.assertEqual(stdout.strip(), "fd-closed")

    def test_queued_waiter_keeps_new_caller_blocked_after_unlock(self):
        source = self.lock_source()
        body = '''
set_lock || exit
: > "$FIXTURE/$ROLE.held"
read -r release
unset_lock
'''
        a = self.start_shell(source, body, ROLE="A")
        self.wait_for("A.held")
        b = self.start_shell(source, body, ROLE="B")
        self.wait_for("B.queued")
        self.assertFalse((self.root / "B.held").exists())
        self.release(a)
        self.wait_for("B.held")
        c = self.start_shell(source, body, ROLE="C")
        event = self.wait_for("C.queued", "C.held")
        self.assertEqual(event, "C.queued", "C entered while queued B still held the lock")
        self.assertFalse((self.root / "C.held").exists())
        self.release(b)
        self.wait_for("C.held")
        self.release(c)

    def test_busy_iterations_skip_work_and_resume_without_advancing_count(self):
        (self.root / "upload").mkdir()
        source = function(STATUS, "main").replace(
            "/tmp/upload", str(self.root / "upload")
        ).replace("/koolshare", str(self.root / "koolshare"))
        body = '''
ITER=0
COUNT=3
LOGTIME1=fixture
LOGFILE_F="$FIXTURE/upload/ssf_status.txt"
TRACE="$FIXTURE/trace"
usleep(){
    if [ "$1" = 2000000 ]; then
        ITER=$((ITER + 1))
        printf 'loop:%s:count:%s\n' "$ITER" "$COUNT" >> "$TRACE"
        [ "$ITER" -lt 4 ] || exit 0
    fi
}
dbus(){
    case "$*" in
    'export ss_failover') printf 'ss_failover_enable=1; ss_failover_s5=2000\n' ;;
    'get ss_basic_enable') printf '1\n' ;;
    *) exit 92 ;;
    esac
}
ps(){
    printf '123 %s/koolshare/bin/status-tool daemon\n' "$FIXTURE"
    [ "$ITER" -gt 2 ] || printf '456 sh ssconfig.sh restart\n'
}
sh(){ exit 93; }
clean_f_log(){ :; }
clean_c_log(){ :; }
fss_get_current_node_id(){ printf '7\n'; }
get_node_name_by_id(){ printf 'fixture-node\n'; }
refresh_status_cache_files(){ printf 'refresh:%s:count:%s\n' "$ITER" "$COUNT" >> "$TRACE"; }
heath_check(){ printf 'health:%s:count:%s\n' "$ITER" "$COUNT" >> "$TRACE"; }
_get_interval(){ printf '0-1000\n'; }
shuf(){ printf '1\n'; }
main
'''
        process = self.start_shell(source, body)
        stdout, stderr = process.communicate(timeout=5)
        self.assertEqual(process.returncode, 0, stdout + stderr)
        self.assertEqual(stderr, "")
        self.assertEqual((self.root / "trace").read_text().splitlines(), [
            "loop:1:count:3",
            "loop:2:count:3",
            "loop:3:count:3",
            "refresh:3:count:3",
            "health:3:count:3",
            "loop:4:count:4",
        ])

    def test_web_entry_preserves_the_shared_restart_lock(self):
        for name in ("pre_start", "pre_stop"):
            with self.subTest(entry=name):
                lock = self.root / "koolss.lock"
                lock.write_text("held\n")
                inode = lock.stat().st_ino
                source = function("fancyss/scripts/ss_config.sh", name).replace(
                    "/var/lock/koolss.lock", str(lock)
                ).replace("/var/lock/fancyss.lock", str(self.root / "fancyss.lock"))
                process = self.start_shell(source, '''
ps(){ :; }
dbus(){ :; }
SCHEMA2_POSTSAVE_IDS_KEY=fixture
''' + name)
                stdout, stderr = process.communicate(timeout=5)
                self.assertEqual(process.returncode, 0, stdout + stderr)
                self.assertTrue(lock.exists(), "web entry unlinked the shared lock")
                self.assertEqual(lock.stat().st_ino, inode)


if __name__ == "__main__":
    unittest.main()
