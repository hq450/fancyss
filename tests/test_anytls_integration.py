"""Fixture-only packaging/runtime integration; never source production scripts."""

import os
from pathlib import Path
import re
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
PLATFORMS = {
    "mtk": "aarch64", "hnd_v8": "aarch64", "ipq64": "aarch64",
    "ipq32": "armv7a", "hnd": "armv7hf", "qca": "armv7a", "arm": "armv5te",
}


def functions(path):
    # Only top-level definitions: nested function closing braces are indented.
    # Excludes metadata commands on load and the build entry point at EOF.
    return "\n".join(re.findall(
        r"^[A-Za-z_][A-Za-z_0-9]*\(\)\s*\{.*?^\}",
        (ROOT / path).read_text(), re.M | re.S,
    ))


def function(path, name):
    return re.search(r"^" + re.escape(name) + r"\(\)\s*\{.*?^\}",
                     (ROOT / path).read_text(), re.M | re.S).group(0)


class PackagingTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="anytls fixture ")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        for tool in ("anytls-zig", "anytls-go"):
            path = self.root / "tool" / tool / "VERSION"
            path.parent.mkdir(parents=True)
            path.write_text("0.1.0\n")
        for platform, arch in PLATFORMS.items():
            (self.root / "fancyss" / f"bin-{platform}").mkdir(parents=True)
            self.asset(f"binaries/anytls-zig/anytls-zig-v0.1.0-linux-{arch}", f"zig-{arch}")
            self.asset(f"tool/anytls-go/dist/anytls-go-v0.1.0-linux-{arch}", f"go-{arch}")
        self.asset("tool/anytls-go/scripts/build-release.sh", "#!/bin/sh\nprintf '%s\\n' \"$*\" >> \"$BUILD_LOG\"\nexit ${BUILD_EXIT:-0}\n")

    def asset(self, path, content):
        file = self.root / path
        file.parent.mkdir(parents=True, exist_ok=True)
        file.write_text(content)
        file.chmod(0o755)

    def run_shell(self, body, backend=None, **extra):
        env = dict(os.environ, BUILD_LOG=str(self.root / "build.log"), **extra)
        env.pop("ANYTLS_BACKEND", None)
        if backend is not None:
            env["ANYTLS_BACKEND"] = backend
        return subprocess.run(["bash", "-c", functions("build.sh") + '\nCURR_PATH="$1"\n' + body,
                               "fixture", str(self.root)], env=env, capture_output=True, text=True)

    def assert_mapping(self, backend):
        for platform, arch in PLATFORMS.items():
            expected = "zig" if backend == "zig" or platform == "arm" else "go"
            self.assertEqual((self.root / "fancyss" / f"bin-{platform}" / "anytls-zig").read_text(),
                             f"{expected}-{arch}")

    def test_default_mapping_and_one_build(self):
        result = self.run_shell("sync_anytls_binaries && verify_anytls_binaries")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assert_mapping("go")
        calls = (self.root / "build.log").read_text().splitlines()
        self.assertEqual(len(calls), 1)
        self.assertEqual(set(calls[0].split()), {"aarch64", "armv7a", "armv7hf", "--no-upx"})

    def test_zig_opt_out_never_builds_go(self):
        result = self.run_shell("sync_anytls_binaries && verify_anytls_binaries", "zig")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assert_mapping("zig")
        self.assertFalse((self.root / "build.log").exists())

    def test_invalid_backend_and_build_failure_stop(self):
        for backend, extra in (("typo", {}), ("go", {"BUILD_EXIT": "3"})):
            with self.subTest(backend=backend):
                result = self.run_shell("sync_anytls_binaries", backend, **extra)
                self.assertNotEqual(result.returncode, 0)
                self.assertFalse((self.root / "fancyss/bin-mtk/anytls-zig").exists())

    def test_verification_detects_wrong_backend_and_missing_executable(self):
        for mutation in ('printf stale > "$CURR_PATH/fancyss/bin-hnd/anytls-zig"',
                         'chmod -x "$CURR_PATH/fancyss/bin-qca/anytls-zig"',
                         'ANYTLS_BACKEND=zig'):
            with self.subTest(mutation=mutation):
                result = self.run_shell("sync_anytls_binaries || exit; " + mutation + "; verify_anytls_binaries")
                self.assertNotEqual(result.returncode, 0)

    def test_sync_binary_propagates_go_build_failure(self):
        result = self.run_shell("sync_binary", BUILD_EXIT="3")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(len((self.root / "build.log").read_text().splitlines()), 1)

    def test_full_verifier_uses_selected_backend(self):
        for tool in ("geotool", "xapi-tool", "sub-tool", "node-tool", "ws-tool", "status-tool", "webtest-tool"):
            self.asset(f"tool/{tool}/VERSION", "0.1.0\n")
            names = {"ws-tool": ("websocketd",), "status-tool": ("status-tool", "statusctl"),
                     "webtest-tool": ("webtest-tool", "webtestctl")}.get(tool, (tool,))
            for platform, arch in PLATFORMS.items():
                if tool == "xapi-tool" and platform == "arm":
                    continue
                for name in names:
                    self.asset(f"binaries/{names[0]}/{name}-v0.1.0-linux-{arch}", name + arch)
                    self.asset(f"fancyss/bin-{platform}/{name}", name + arch)
        result = self.run_shell("sync_anytls_binaries && verify_zig_tool_binaries")
        self.assertEqual(result.returncode, 0, result.stderr)
        result = self.run_shell('printf stale > "$CURR_PATH/fancyss/bin-hnd/anytls-zig"; verify_zig_tool_binaries')
        self.assertNotEqual(result.returncode, 0)


class LaunchTests(unittest.TestCase):
    def test_loaded_dns_bootstrap_survives_refresh(self):
        with tempfile.TemporaryDirectory() as tmp:
            bootstrap = Path(tmp) / "bootstrap"
            source = function("fancyss/ss/ssconfig.sh", "refresh_node_direct_domain_file")
            script = source + '''
fss_require_base_dns(){ :; }
fss_refresh_node_direct_cache(){ :; }
fss_airport_dns_override_load(){ AIRPORT_DNS_ACTIVE=1; printf bootstrap > "$BOOTSTRAP"; }
fss_refresh_airport_special_runtime_domain_files(){ rm "$BOOTSTRAP"; }
FSS_NODE_DIRECT_RUNTIME_OTHER_FILE="$BOOTSTRAP.other"
FSS_NODE_DIRECT_RUNTIME_FILE="$BOOTSTRAP.runtime"
refresh_node_direct_domain_file
'''
            result = subprocess.run(["bash", "-c", script],
                                    env=dict(os.environ, BOOTSTRAP=str(bootstrap)),
                                    capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(bootstrap.read_text(), "bootstrap")

    def test_password_write_failure_prevents_launch(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "bin").mkdir()
            (root / "bin/anytls-zig").touch()
            (root / "password").mkdir()
            source = function("fancyss/ss/ssconfig.sh", "anytls_hostport") + "\n" + function("fancyss/ss/ssconfig.sh", "start_anytls")
            source = source.replace("/koolshare", tmp).replace("/tmp/anytls_pass", str(root / "password"))
            script = source + '''
run(){ echo 'anytls-go 0.1.0'; }
echo_date(){ :; }
close_in_five(){ :; }
run_bg_detached(){ touch "$FIXTURE/launched"; }
start_anytls
'''
            env = dict(os.environ, FIXTURE=tmp, ss_basic_anytls_server="example.test",
                       ss_basic_anytls_pass="fixture secret")
            result = subprocess.run(["bash", "-c", script], env=env, capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertFalse((root / "launched").exists())
            self.assertNotIn("fixture secret", result.stdout + result.stderr)

    def test_detached_launch_has_null_stdin_and_ignores_hup(self):
        with tempfile.TemporaryDirectory() as tmp:
            report = Path(tmp) / "report"
            script = functions("fancyss/scripts/ss_base.sh") + '\nrun_bg_detached bash -c \'if read -r value; then echo leaked > "$1"; fi; trap -p HUP >> "$1"; kill -HUP $$; echo done >> "$1"\' fixture "$1"\nwait\n'
            result = subprocess.run(["bash", "-c", script, "fixture", str(report)],
                                    input="must-not-be-read\n", text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("done", report.read_text())
            self.assertNotIn("leaked", report.read_text())

    def test_production_anytls_arguments_and_private_password(self):
        for insecure, sni in (("0", ""), ("1", "tls.example")):
            with self.subTest(insecure=insecure, sni=sni), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                (root / "bin").mkdir()
                (root / "bin/anytls-zig").touch()
                original = root / "original"
                original.write_text("do not overwrite")
                password = root / "password"
                password.symlink_to(original)
                source = function("fancyss/ss/ssconfig.sh", "anytls_hostport") + "\n" + function("fancyss/ss/ssconfig.sh", "start_anytls")
                # Redirect only filesystem paths; run the actual production function.
                source = source.replace("/koolshare", str(root)).replace("/tmp/anytls_pass", str(password))
                script = source + '''
run(){ echo 'anytls-go 0.1.0'; }
echo_date(){ :; }
close_in_five(){ exit 90; }
detect_running_status2(){ :; }
detect_running_status3(){ :; }
run_bg(){ exit 91; }
count=0
run_bg_detached(){ count=$((count + 1)); printf '%s\\n' "$@" > "$FIXTURE/args$count"; }
start_anytls
'''
                secret = "fixture password ' $ &"
                env = dict(os.environ, FIXTURE=tmp, ss_basic_anytls_server="2001:db8::1",
                           ss_basic_anytls_port="443", ss_basic_anytls_pass=secret,
                           ss_basic_anytls_ai=insecure, ss_basic_anytls_sni=sni)
                result = subprocess.run(["bash", "-c", script], env=env, capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(password.stat().st_mode & 0o777, 0o600)
                self.assertFalse(password.is_symlink())
                self.assertEqual(password.read_text(), secret)
                self.assertEqual(original.read_text(), "do not overwrite")
                self.assertEqual((root / "args1").read_text().splitlines(),
                                 ["ipt2socks", "-p", "23456", "-l", "3333", "-b", "0.0.0.0", "-B", "::", "-n", "10000", "-R"])
                expected = [str(root / "bin/anytls-zig"), "-server", "[2001:db8::1]:443",
                            "--password-file", str(password), "-l", "127.0.0.1:23456"]
                if sni:
                    expected += ["-sni", sni]
                expected += ["--insecure" if insecure == "1" else "--verify"]
                self.assertEqual((root / "args2").read_text().splitlines(), expected)
                self.assertNotIn(secret, result.stdout + result.stderr + (root / "args2").read_text())


if __name__ == "__main__":
    unittest.main()
