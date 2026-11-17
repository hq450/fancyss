"""Run the actual cleanup function against disposable processes and files."""

from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import unittest

from test_anytls_integration import ROOT


class AnyTLSTestCleanup(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory(prefix="webtest cleanup ")
        self.addCleanup(tmp.cleanup)
        self.root = Path(tmp.name)
        for directory in ("cache", "work/pids", "work/conf", "proc", "koolshare/bin"):
            (self.root / directory).mkdir(parents=True, exist_ok=True)
        self.binary = self.root / "koolshare/bin/anytls-zig"
        self.binary.symlink_to(Path(sys.executable).resolve())

    @staticmethod
    def stop_process(process):
        if process.poll() is None:
            process.terminate()
        process.wait(timeout=3)

    def client(self, password, listen="127.0.0.1:19007", *, anytls=True, argv=None):
        if anytls:
            args = [str(self.binary), "-c", "import time; time.sleep(60)"]
            args += argv if argv is not None else ["--password-file", str(password), "-l", listen]
            executable = self.binary.resolve()
        else:
            executable = Path(shutil.which("sleep")).resolve()
            args = [str(executable), "60"]
        process = subprocess.Popen(args)
        self.addCleanup(self.stop_process, process)
        proc = self.root / "proc" / str(process.pid)
        proc.mkdir()
        (proc / "exe").symlink_to(executable)
        (proc / "cmdline").write_bytes(b"\0".join(arg.encode() for arg in args) + b"\0")
        return process

    def cleanup(self, *, record_kills=False):
        # Extract definitions only; never execute the router entry point.
        source = "\n".join(re.findall(
            r"^wt_(?:anytls_pid_matches|runtime_cleanup)\(\)\s*\{.*?^\}",
            (ROOT / "fancyss/scripts/ss_webtest.sh").read_text(), re.M | re.S,
        ))
        source = source.replace("/proc/", str(self.root / "proc") + "/").replace(
            "/koolshare/", str(self.root / "koolshare") + "/")
        script = source + """
FSS_WEBTEST_CACHE_NODE_DIR="$1/cache"
TMP2="$1/work"
FIXTURE_KILLS="$1/kills"
# Keep machine-wide cleanup outside the disposable-process fixture.
killall() { return 0; }
ps() { return 0; }
"""
        if record_kills:
            # Never let baseline code signal PID 0, 1, or a process group.
            script += 'kill() { printf "%s\\n" "$*" >> "$FIXTURE_KILLS"; }\n'
        script += "wt_runtime_cleanup\n"
        result = subprocess.run(["bash", "-c", script, "fixture", str(self.root)],
                                capture_output=True, text=True, timeout=5)
        self.assertEqual(result.returncode, 0, result.stderr)

    def assert_alive(self, process):
        with self.assertRaises(subprocess.TimeoutExpired, msg="unowned process was signaled"):
            process.wait(timeout=0.1)

    def test_cleanup_stops_current_and_legacy_owned_clients(self):
        for filename in ("anytls_7.pid", "7_anytls.pid"):
            with self.subTest(filename=filename):
                pidfile = (self.root / "work/pids" if filename.startswith("anytls_")
                           else self.root / "cache") / filename
                password = (self.root / "work/conf/7_anytls.pass" if filename.startswith("anytls_")
                            else self.root / "cache/7_anytls.pass")
                owned = self.client(password)
                unrelated = self.client(password, anytls=False)
                pidfile.write_text(str(owned.pid) + "\n")
                other = self.root / "work/pids/other_7.pid"
                other.write_text(str(unrelated.pid) + "\n")
                self.cleanup()
                owned.wait(timeout=3)
                self.assertFalse(pidfile.exists())
                self.assert_alive(unrelated)
                self.assertTrue(other.exists())

    def test_matching_pidfile_does_not_kill_reused_non_anytls_pid(self):
        process = self.client(self.root / "work/conf/7_anytls.pass", anytls=False)
        pidfile = self.root / "work/pids/anytls_7.pid"
        pidfile.write_text(str(process.pid) + "\n")
        self.cleanup()
        self.assert_alive(process)
        self.assertFalse(pidfile.exists())

    def test_matching_pidfile_does_not_kill_different_password_client(self):
        process = self.client(self.root / "work/conf/8_anytls.pass")
        pidfile = self.root / "work/pids/anytls_7.pid"
        pidfile.write_text(str(process.pid) + "\n")
        self.cleanup()
        self.assert_alive(process)
        self.assertFalse(pidfile.exists())

    def test_matching_pidfile_does_not_kill_production_or_nonloopback_listener(self):
        for listen in ("127.0.0.1:23456", "[::1]:23456", "0.0.0.0:19007", "example.test:19007"):
            with self.subTest(listen=listen):
                process = self.client(self.root / "work/conf/7_anytls.pass", listen)
                pidfile = self.root / "work/pids/anytls_7.pid"
                pidfile.write_text(str(process.pid) + "\n")
                self.cleanup()
                self.assert_alive(process)
                self.assertFalse(pidfile.exists())

    def test_invalid_pids_never_reach_kill(self):
        for index, pid in enumerate(("-123", "0", "1", "", "not-a-pid", "12\n34")):
            (self.root / "work/pids" / f"anytls_{index}.pid").write_text(pid)
        self.cleanup(record_kills=True)
        self.assertFalse((self.root / "kills").exists(), "invalid PID reached kill")
        self.assertEqual(list((self.root / "work/pids").iterdir()), [])


if __name__ == "__main__":
    unittest.main()
