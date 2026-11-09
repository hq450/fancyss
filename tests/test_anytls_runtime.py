"""Loopback-only AnyTLS CLI regressions (Python 3.11+, openssl on PATH).

Run with ANYTLS_BIN=/path/to/client python3.11 tests/test_anytls_runtime.py -v.
The default binary is resolved relative to this repository, not the working
directory. No remote node, DNS lookup, or third-party Python package is used.
"""

import contextlib
from concurrent.futures import ThreadPoolExecutor
import hashlib
import os
from pathlib import Path
import shutil
import signal
import socket
import ssl
import struct
import subprocess
import sys
import tempfile
import threading
import time
import unittest


ROOT = Path(__file__).resolve().parents[1]
BINARY = Path(os.environ.get(
    "ANYTLS_BIN", str(ROOT / "tool/anytls-go/dist/anytls-zig-native")
)).expanduser().resolve()
IO_TIMEOUT = 2.0
HEADER = struct.Struct("!BIH")
TARGET = b"\x01\x7f\x00\x00\x01\x01\xbb"
CMD_WASTE, CMD_SYN, CMD_PSH, CMD_FIN, CMD_SETTINGS = range(5)
CMD_SYNACK, CMD_HEART_REQUEST, CMD_HEART_RESPONSE, CMD_SERVER_SETTINGS = range(7, 11)


def receive(conn, size):
    data = bytearray()
    while len(data) < size:
        chunk = conn.recv(size - len(data))
        if not chunk:
            raise EOFError("socket closed")
        data.extend(chunk)
    return bytes(data)


def read_reply(conn, size, point):
    """Apply one deadline to the entire read, including fragmented replies."""
    deadline = time.monotonic() + IO_TIMEOUT
    data = bytearray()
    try:
        while len(data) < size:
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                raise TimeoutError()
            conn.settimeout(remaining)
            chunk = conn.recv(size - len(data))
            if not chunk:
                raise EOFError()
            data.extend(chunk)
    except TimeoutError:
        raise AssertionError(f"{point}: timed out within {IO_TIMEOUT:.0f}s deadline") from None
    except (OSError, EOFError) as error:
        raise AssertionError(f"{point}: {type(error).__name__}") from None
    finally:
        conn.settimeout(IO_TIMEOUT)
    return bytes(data)


def close_socket(conn):
    with contextlib.suppress(OSError):
        conn.shutdown(socket.SHUT_RDWR)
    conn.close()


class EchoPeer:
    """Concurrent TLS sessions, with independent target state for each stream."""

    def __init__(self, context, password):
        self.context = context
        self.digest = hashlib.sha256(password).digest()
        self.stop = threading.Event()
        self.lock = threading.Lock()
        self.connections = set()
        self.workers = []
        self.failures = []
        self.listener = socket.socket()
        self.listener.bind(("127.0.0.1", 0))
        self.listener.listen(256)
        self.listener.settimeout(0.2)
        self.port = self.listener.getsockname()[1]
        self.acceptor = threading.Thread(target=self.accept, name="anytls-accept")

    def start(self):
        self.acceptor.start()

    def accept(self):
        while not self.stop.is_set():
            try:
                raw, _ = self.listener.accept()
            except socket.timeout:
                continue
            except OSError:
                if not self.stop.is_set():
                    self.failures.append("listener failed")
                return
            with self.lock:
                self.connections.add(raw)
            worker = threading.Thread(target=self.serve, args=(raw,), name="anytls-session")
            self.workers.append(worker)
            worker.start()

    @staticmethod
    def frame(conn, command, sid, data=b""):
        conn.sendall(HEADER.pack(command, sid, len(data)) + data)

    def serve(self, raw):
        conn = raw
        try:
            # Register the SSLSocket before handshaking so teardown can interrupt
            # a stalled handshake as well as a blocked frame read.
            with self.lock:
                if self.stop.is_set():
                    return
                conn = self.context.wrap_socket(raw, server_side=True,
                                                do_handshake_on_connect=False)
                self.connections.discard(raw)
                self.connections.add(conn)
            conn.settimeout(30)
            conn.do_handshake()
            auth = receive(conn, 34)
            if auth[:32] != self.digest:
                raise ValueError("invalid local authentication")
            receive(conn, int.from_bytes(auth[32:], "big"))
            conn.settimeout(None)  # Held sessions end only on CLI close or teardown.
            streams = {}
            while not self.stop.is_set():
                command, sid, length = HEADER.unpack(receive(conn, HEADER.size))
                data = receive(conn, length)
                if command == CMD_WASTE:
                    continue
                if command == CMD_SETTINGS:
                    self.frame(conn, CMD_SERVER_SETTINGS, 0, b"v=2")
                elif command == CMD_SYN:
                    if sid in streams:
                        raise ValueError("duplicate live stream")
                    streams[sid] = bytearray()
                elif command == CMD_PSH:
                    if sid not in streams:
                        raise ValueError("data before SYN")
                    target = streams[sid]
                    if target is not None:
                        target.extend(data)
                        if not target:
                            continue
                        atyp = target[0]
                        if atyp == 1:
                            target_size = 7
                        elif atyp == 4:
                            target_size = 19
                        elif atyp == 3:
                            if len(target) < 2:
                                continue
                            target_size = 4 + target[1]
                        else:
                            raise ValueError("invalid target address type")
                        if len(target) < target_size:
                            continue
                        if bytes(target[:target_size]) != TARGET:
                            raise ValueError("unexpected local target")
                        data = bytes(target[target_size:])
                        streams[sid] = None
                        self.frame(conn, CMD_SYNACK, sid)
                    if data:
                        self.frame(conn, CMD_PSH, sid, data)
                elif command == CMD_FIN:
                    # FIN ends only this stream; a pooled TLS session stays alive.
                    streams.pop(sid, None)
                elif command == CMD_HEART_REQUEST:
                    self.frame(conn, CMD_HEART_RESPONSE, sid, data)
                else:
                    raise ValueError("unexpected AnyTLS command")
        except (EOFError, ConnectionError, ssl.SSLEOFError):
            pass  # CLI may close an idle or completed TLS session at any time.
        except Exception as error:
            if not self.stop.is_set():
                with self.lock:
                    if len(self.failures) < 5:
                        self.failures.append(type(error).__name__ + ": " + str(error))
        finally:
            with self.lock:
                self.connections.discard(conn)
                self.connections.discard(raw)
            close_socket(conn)

    def close(self):
        self.stop.set()
        self.acceptor.join(timeout=3)
        self.listener.close()
        with self.lock:
            connections = list(self.connections)
        # Shutdown unblocks reads; the owning worker performs close().
        for conn in connections:
            with contextlib.suppress(OSError):
                conn.shutdown(socket.SHUT_RDWR)
        deadline = time.monotonic() + 5
        for worker in self.workers:
            worker.join(timeout=max(0, deadline - time.monotonic()))
        if self.acceptor.is_alive() or any(w.is_alive() for w in self.workers):
            raise AssertionError("local AnyTLS peer threads did not stop")
        if self.failures:
            raise AssertionError("local AnyTLS peer: " + "; ".join(self.failures))


def stop_process(process, log):
    if process.poll() is None:
        process.terminate()
    try:
        process.wait(timeout=3)
    except subprocess.TimeoutExpired:
        process.kill()
        process.wait(timeout=3)
        raise AssertionError("AnyTLS CLI did not exit after SIGTERM")
    if process.returncode not in (0, -signal.SIGTERM):
        log.seek(0)
        raise AssertionError("AnyTLS CLI failed: " + log.read().decode(errors="replace")[-4000:])


@contextlib.contextmanager
def runtime(state=None):
    with tempfile.TemporaryDirectory(prefix="anytls-runtime-") as directory:
        directory = Path(directory)
        cert, key = directory / "cert.pem", directory / "key.pem"
        subprocess.run(
            ["openssl", "req", "-x509", "-newkey", "ec", "-pkeyopt",
             "ec_paramgen_curve:P-256", "-nodes", "-keyout", str(key),
             "-out", str(cert), "-subj", "/CN=localhost", "-days", "1"],
            check=True, timeout=15, stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )
        context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        context.minimum_version = ssl.TLSVersion.TLSv1_3
        context.maximum_version = ssl.TLSVersion.TLSv1_3
        context.load_cert_chain(cert, key)
        password = os.urandom(24).hex().encode("ascii")
        password_file = directory / "password"
        password_file.touch(mode=0o600)
        password_file.write_bytes(password)
        with contextlib.ExitStack() as stack:
            peer = EchoPeer(context, password)
            peer.start()
            stack.callback(peer.close)
            # The CLI has no inherited-listener option, so reserve an ephemeral
            # loopback port and release it immediately before process startup.
            with socket.socket() as reservation:
                reservation.bind(("127.0.0.1", 0))
                port = reservation.getsockname()[1]
            log = stack.enter_context(open(directory / "client.log", "w+b"))
            process = subprocess.Popen(
                [str(BINARY), "-server", f"127.0.0.1:{peer.port}",
                 "--password-file", str(password_file), "-sni", "localhost",
                 "-l", f"127.0.0.1:{port}", "--insecure"],
                stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                stderr=log,
            )
            stack.callback(stop_process, process, log)
            if state is not None:
                state.update(process=process, peer=peer)
            deadline = time.monotonic() + 5
            while True:
                if process.poll() is not None:
                    raise AssertionError("AnyTLS CLI exited before listening")
                try:
                    with socket.create_connection(("127.0.0.1", port), timeout=0.1):
                        break
                except OSError:
                    if time.monotonic() >= deadline:
                        raise AssertionError("AnyTLS CLI did not listen within 5s") from None
                    time.sleep(0.02)
            yield port


@unittest.skipUnless(ssl.HAS_TLSv1_3, "Python requires TLS 1.3 support")
class AnyTLSRuntimeTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not shutil.which("openssl"):
            raise unittest.SkipTest("openssl is required for a local ephemeral certificate")
        if not BINARY.is_file() or not os.access(BINARY, os.X_OK):
            raise AssertionError("ANYTLS_BIN must select an executable file")

    def connect(self, port, stack, label):
        try:
            conn = socket.create_connection(("127.0.0.1", port), timeout=IO_TIMEOUT)
        except OSError as error:
            self.fail(f"{label}: TCP connect: {type(error).__name__}")
        stack.callback(close_socket, conn)
        conn.sendall(b"\x05\x01\x00")
        self.assertEqual(read_reply(conn, 2, f"{label}: SOCKS greeting"), b"\x05\x00")
        conn.sendall(b"\x05\x01\x00" + TARGET)
        reply = read_reply(conn, 4, f"{label}: SOCKS CONNECT")
        self.assertEqual(reply[:3], b"\x05\x00\x00", f"{label}: SOCKS CONNECT rejected")
        address_size = {1: 4, 4: 16}.get(reply[3])
        if reply[3] == 3:
            address_size = read_reply(conn, 1, f"{label}: bound address size")[0]
        self.assertIsNotNone(address_size, f"{label}: invalid bound address type")
        read_reply(conn, address_size + 2, f"{label}: bound address")
        self.echo(conn, label, 0)
        return conn

    def echo(self, conn, label, round_number):
        payload = f"{label}/round-{round_number}:".encode("ascii") + bytes(range(256)) * 4
        conn.sendall(payload)
        self.assertEqual(read_reply(conn, len(payload), f"{label}: echo round {round_number}"),
                         payload, f"{label}: echo mismatch")

    def hold_connections(self, count):
        with runtime() as port, contextlib.ExitStack() as stack:
            holders = [self.connect(port, stack, f"holder {number}/{count}")
                       for number in range(1, count + 1)]
            # Every holder remains negotiated and open while the probe completes.
            with contextlib.ExitStack() as probes:
                probe = self.connect(port, probes, f"probe with {count} holders")
                for number, conn in enumerate(holders, 1):
                    self.echo(conn, f"holder {number}/{count}", 1)
                self.echo(probe, f"probe with {count} holders", 1)
            for number, conn in enumerate(holders, 1):
                self.echo(conn, f"holder {number}/{count}", 2)

    def test_64_negotiated_connections_and_responsive_probe(self):
        self.hold_connections(64)

    def test_128_negotiated_connections_and_responsive_probe(self):
        self.hold_connections(128)

    def test_default_admission_cap_rejects_257th_connection(self):
        with runtime() as port, contextlib.ExitStack() as stack:
            holders = [self.connect(port, stack, f"capacity holder {i}") for i in range(256)]
            extra = stack.enter_context(socket.create_connection(("127.0.0.1", port), timeout=IO_TIMEOUT))
            extra.settimeout(IO_TIMEOUT)
            try:
                extra.sendall(b"\x05\x01\x00")
                self.assertEqual(extra.recv(2), b"", "over-budget connection was admitted")
            except ConnectionResetError:
                pass
            self.echo(holders[0], "healthy connection at full capacity", 1)

    def test_repeated_close_batches_allow_new_connections(self):
        with runtime() as port:
            for batch in range(6):
                with contextlib.ExitStack() as stack:
                    holders = [self.connect(port, stack, f"batch {batch + 1} holder {number}")
                               for number in range(1, 17)]
                    for number, conn in enumerate(holders, 1):
                        self.echo(conn, f"batch {batch + 1} holder {number}", 1)
                with contextlib.ExitStack() as stack:
                    self.connect(port, stack, f"probe after closed batch {batch + 1}")

    def test_upstream_disconnect_allows_new_sessions(self):
        state = {}
        with runtime(state) as port, contextlib.ExitStack() as stack:
            holders = [self.connect(port, stack, f"before disconnect {i}") for i in range(8)]
            peer = state["peer"]
            with peer.lock:
                connections = list(peer.connections)
            for conn in connections:
                with contextlib.suppress(OSError):
                    conn.shutdown(socket.SHUT_RDWR)
            for conn in holders:
                conn.settimeout(IO_TIMEOUT)
                try:
                    self.assertEqual(conn.recv(1), b"")
                except ConnectionResetError:
                    pass
            self.connect(port, stack, "after upstream disconnect")

    def test_established_tunnel_survives_setup_deadline(self):
        with runtime() as port, contextlib.ExitStack() as stack:
            conn = self.connect(port, stack, "before idle")
            time.sleep(11)
            self.echo(conn, "after setup budget elapsed", 1)

    def test_short_concurrent_soak(self):
        duration = float(os.environ.get("ANYTLS_SOAK_SECONDS", "15"))
        self.assertGreaterEqual(duration, 1)
        with runtime() as port:
            deadline = time.monotonic() + duration

            def worker(number):
                count = 0
                while time.monotonic() < deadline:
                    with contextlib.ExitStack() as stack:
                        conn = self.connect(port, stack, f"soak worker {number}")
                        self.echo(conn, f"soak worker {number}", count)
                        count += 1
                    # Exercise churn without exhausting the test host's TCP TIME_WAIT ports.
                    time.sleep(0.05)
                return count

            with ThreadPoolExecutor(max_workers=4) as pool:
                counts = list(pool.map(worker, range(4)))
            self.assertTrue(all(count > 0 for count in counts))
            print(f"short soak: {sum(counts)} connections in {duration:g}s", flush=True)
            with contextlib.ExitStack() as stack:
                self.connect(port, stack, "probe after concurrent soak")

    @unittest.skipUnless(sys.platform.startswith("linux"), "Linux /proc resource accounting")
    def test_idle_sessions_release_descriptors(self):
        state = {}
        with runtime(state) as port:
            proc = Path(f"/proc/{state['process'].pid}")
            baseline = len(list((proc / "fd").iterdir()))
            with contextlib.ExitStack() as stack:
                holders = [self.connect(port, stack, f"resource holder {i}") for i in range(64)]
                for i, conn in enumerate(holders):
                    self.echo(conn, f"resource holder {i}", 1)
                peak = len(list((proc / "fd").iterdir()))
                rss_line = next(line for line in (proc / "status").read_text().splitlines()
                                if line.startswith("VmRSS:"))
                rss_kib = int(rss_line.split()[1])
                self.assertLess(rss_kib, 128 * 1024, "unexpected memory use for 64 local tunnels")
            deadline = time.monotonic() + 40
            while time.monotonic() < deadline:
                final = len(list((proc / "fd").iterdir()))
                if final <= baseline + 4:
                    break
                time.sleep(0.2)
            else:
                self.fail("closed streams retained their idle-session descriptors")
            print(f"resources: fd {baseline}->{peak}->{final}, peak-sample RSS {rss_kib} KiB", flush=True)


if __name__ == "__main__":
    unittest.main()
