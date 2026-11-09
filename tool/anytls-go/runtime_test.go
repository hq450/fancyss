package main

import (
	"context"
	"crypto/tls"
	"crypto/x509"
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"testing"
	"time"
)

func testConfig() config {
	return config{Server: "127.0.0.1:1", Password: "test-only", MaxConnections: 4,
		HandshakeTimeout: 100 * time.Millisecond, DialTimeout: 100 * time.Millisecond,
		WriteTimeout: 100 * time.Millisecond}
}

func startTestRuntime(t *testing.T, cfg config) (*server, string, func()) {
	t.Helper()
	s, err := newServer(cfg)
	if err != nil {
		t.Fatal(err)
	}
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	ctx, cancel := context.WithCancel(context.Background())
	done := make(chan error, 1)
	go func() { done <- s.serve(ctx, listener) }()
	var once sync.Once
	stop := func() {
		once.Do(func() {
			cancel()
			select {
			case err := <-done:
				if err != nil {
					t.Error(err)
				}
			case <-time.After(time.Second):
				t.Error("runtime did not shut down")
			}
		})
	}
	t.Cleanup(stop)
	return s, listener.Addr().String(), stop
}

func dialLocal(t *testing.T, address string) net.Conn {
	t.Helper()
	conn, err := net.DialTimeout("tcp", address, time.Second)
	if err != nil {
		t.Fatal(err)
	}
	_ = conn.SetDeadline(time.Now().Add(time.Second))
	t.Cleanup(func() { _ = conn.Close() })
	return conn
}

func greeting(t *testing.T, conn net.Conn) {
	t.Helper()
	if _, err := conn.Write([]byte{5, 1, 0}); err != nil {
		t.Fatal(err)
	}
	var reply [2]byte
	if _, err := io.ReadFull(conn, reply[:]); err != nil || reply != [2]byte{5, 0} {
		t.Fatalf("greeting reply=%v err=%v", reply, err)
	}
}

func TestAdmissionLimitAndRelease(t *testing.T) {
	cfg := testConfig()
	cfg.HandshakeTimeout = time.Second
	s, address, stop := startTestRuntime(t, cfg)
	defer stop()
	holders := make([]net.Conn, cfg.MaxConnections)
	for i := range holders {
		holders[i] = dialLocal(t, address)
		greeting(t, holders[i])
	}
	extra := dialLocal(t, address)
	var reply [2]byte
	if n, err := extra.Read(reply[:]); n != 0 || err == nil {
		t.Fatal("over-budget connection was not rejected immediately")
	}
	_ = holders[0].Close()
	deadline := time.Now().Add(time.Second)
	for {
		s.mu.Lock()
		count := len(s.clients)
		s.mu.Unlock()
		if count == cfg.MaxConnections-1 {
			break
		}
		if time.Now().After(deadline) {
			t.Fatal("closed connection did not release its admission slot")
		}
		time.Sleep(time.Millisecond)
	}
	greeting(t, dialLocal(t, address))
}

func TestHandshakeDeadlineAndShutdown(t *testing.T) {
	s, address, stop := startTestRuntime(t, testConfig())
	conn := dialLocal(t, address)
	_, _ = conn.Write([]byte{5})
	time.Sleep(60 * time.Millisecond)
	_, _ = conn.Write([]byte{1, 0})
	var reply [2]byte
	if _, err := io.ReadFull(conn, reply[:]); err != nil {
		t.Fatal(err)
	}
	started := time.Now()
	var one [1]byte
	if _, err := conn.Read(one[:]); err == nil {
		t.Fatal("incomplete CONNECT did not expire")
	}
	if time.Since(started) > 90*time.Millisecond {
		t.Fatal("greeting-to-CONNECT transition reset the handshake budget")
	}
	stop()
	s.mu.Lock()
	defer s.mu.Unlock()
	if len(s.clients) != 0 || len(s.transports) != 0 {
		t.Fatal("shutdown retained connections")
	}
}

func TestTLSSetupDeadline(t *testing.T) {
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer listener.Close()
	accepted := make(chan net.Conn, 1)
	go func() { conn, _ := listener.Accept(); accepted <- conn }()
	cfg := testConfig()
	cfg.Server = listener.Addr().String()
	cfg.Insecure = true
	s, err := newServer(cfg)
	if err != nil {
		t.Fatal(err)
	}
	defer s.close()
	started := time.Now()
	_, err = s.dialTLS(context.Background())
	conn := <-accepted
	defer conn.Close()
	if err == nil || time.Since(started) > time.Second {
		t.Fatal("stalled TLS handshake did not expire")
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	if len(s.transports) != 0 {
		t.Fatal("failed TLS handshake retained a transport")
	}
}

func TestDNSSetupDeadline(t *testing.T) {
	listener, err := net.ListenPacket("udp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer listener.Close()
	cfg := testConfig()
	cfg.Server = "node.invalid:443"
	cfg.Resolver = &net.Resolver{PreferGo: true, Dial: func(ctx context.Context, _, _ string) (net.Conn, error) {
		return (&net.Dialer{}).DialContext(ctx, "udp", listener.LocalAddr().String())
	}}
	s, err := newServer(cfg)
	if err != nil {
		t.Fatal(err)
	}
	defer s.close()
	started := time.Now()
	_, err = s.dialTLS(context.Background())
	if err == nil || time.Since(started) > time.Second {
		t.Fatal("stalled DNS lookup did not expire")
	}
}

func TestShutdownInterruptsTLSSetup(t *testing.T) {
	peer, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer peer.Close()
	accepted := make(chan net.Conn, 1)
	go func() { conn, _ := peer.Accept(); accepted <- conn }()
	cfg := testConfig()
	cfg.Server, cfg.Insecure = peer.Addr().String(), true
	cfg.DialTimeout = 10 * time.Second
	s, address, stop := startTestRuntime(t, cfg)
	conn := dialLocal(t, address)
	greeting(t, conn)
	_, _ = conn.Write([]byte{5, 1, 0, 1, 127, 0, 0, 1, 0, 80})
	select {
	case raw := <-accepted:
		defer raw.Close()
	case <-time.After(time.Second):
		t.Fatal("upstream setup did not begin")
	}
	stop()
	s.mu.Lock()
	defer s.mu.Unlock()
	if len(s.clients) != 0 || len(s.transports) != 0 {
		t.Fatal("cancelled setup retained tracked sockets")
	}
}

func TestTLSVerificationAndSNI(t *testing.T) {
	peer := httptest.NewUnstartedServer(http.HandlerFunc(func(http.ResponseWriter, *http.Request) {}))
	peer.Config.ErrorLog = nil
	names := make(chan string, 8)
	peer.TLS = &tls.Config{GetConfigForClient: func(hello *tls.ClientHelloInfo) (*tls.Config, error) {
		names <- hello.ServerName
		return nil, nil
	}}
	peer.StartTLS()
	defer peer.Close()
	cfg := testConfig()
	cfg.DialTimeout = time.Second
	cfg.Server = strings.TrimPrefix(peer.URL, "https://")
	s, err := newServer(cfg)
	if err != nil {
		t.Fatal(err)
	}
	_, err = s.dialTLS(context.Background())
	s.close()
	if err == nil {
		t.Fatal("strict mode accepted an untrusted certificate")
	}
	<-names
	cfg.RootCAs = x509.NewCertPool()
	cfg.RootCAs.AddCert(peer.Certificate())
	s, err = newServer(cfg)
	if err != nil {
		t.Fatal(err)
	}
	conn, err := s.dialTLS(context.Background())
	if err != nil {
		t.Fatal("strict mode rejected the trusted endpoint:", err)
	}
	_ = conn.Close()
	s.close()
	<-names
	cfg.SNI = "provider-sni.invalid"
	s, err = newServer(cfg)
	if err != nil {
		t.Fatal(err)
	}
	_, err = s.dialTLS(context.Background())
	s.close()
	if err == nil {
		t.Fatal("strict mode accepted a trusted certificate for the wrong hostname")
	}
	<-names
	cfg.Insecure = true
	s, err = newServer(cfg)
	if err != nil {
		t.Fatal(err)
	}
	conn, err = s.dialTLS(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	_ = conn.Close()
	s.close()
	if name := <-names; name != cfg.SNI {
		t.Fatal("insecure mode discarded the configured SNI")
	}
}

func TestBoundedWriteUnblocksRelay(t *testing.T) {
	writer, reader := net.Pipe()
	defer reader.Close()
	conn := &boundedConn{Conn: writer, timeout: 50 * time.Millisecond}
	defer conn.Close()
	started := time.Now()
	_, err := conn.Write([]byte("blocked-write"))
	if err == nil || time.Since(started) > time.Second {
		t.Fatal("blocked upstream write did not expire")
	}
}

type notifyingConn struct {
	net.Conn
	started chan struct{}
}

func (c *notifyingConn) Write(data []byte) (int, error) {
	close(c.started)
	return c.Conn.Write(data)
}

func TestLibraryDeadlineClearCannotRemoveWriteBound(t *testing.T) {
	writer, reader := net.Pipe()
	defer reader.Close()
	defer writer.Close()
	started := make(chan struct{})
	conn := &boundedConn{Conn: &notifyingConn{Conn: writer, started: started}, timeout: 50 * time.Millisecond}
	done := make(chan error, 1)
	go func() { _, err := conn.Write([]byte("blocked")); done <- err }()
	<-started
	if err := conn.SetWriteDeadline(time.Time{}); err != nil {
		t.Fatal(err)
	}
	select {
	case err := <-done:
		if err == nil {
			t.Fatal("blocked write unexpectedly succeeded")
		}
	case <-time.After(300 * time.Millisecond):
		t.Fatal("library deadline clear removed the active write bound")
	}
}

func TestRelayReapsNonReadingDownstream(t *testing.T) {
	client, local := net.Pipe()
	remote, upstream := net.Pipe()
	defer client.Close()
	defer upstream.Close()
	done := make(chan struct{})
	go func() { relay(local, remote, 50*time.Millisecond); close(done) }()
	if _, err := upstream.Write([]byte("downstream-never-reads")); err != nil {
		t.Fatal(err)
	}
	select {
	case <-done:
	case <-time.After(300 * time.Millisecond):
		t.Fatal("non-reading downstream retained both relay directions")
	}
}

func TestRelayReleasesOppositeDirection(t *testing.T) {
	client, local := net.Pipe()
	remote, upstream := net.Pipe()
	defer client.Close()
	defer upstream.Close()
	done := make(chan struct{})
	go func() { relay(local, remote, 50*time.Millisecond); close(done) }()
	_ = client.Close()
	select {
	case <-done:
	case <-time.After(time.Second):
		t.Fatal("relay retained a blocked copy after client disconnect")
	}
}

func TestConfigCompatibilityAndSecrets(t *testing.T) {
	password := "file-only-secret\n"
	file := filepath.Join(t.TempDir(), "password")
	if err := os.WriteFile(file, []byte(password), 0600); err != nil {
		t.Fatal(err)
	}
	cfg, err := parseConfig([]string{"-server", "[::1]:443", "--password-file", file,
		"-sni", "localhost", "-l", "127.0.0.1:23456", "--verify"})
	if err != nil || cfg.Password != password || cfg.Insecure || cfg.SNI != "localhost" {
		t.Fatalf("compatibility parse failed: %v", err)
	}
	_, err = parseConfig([]string{"-server", "127.0.0.1:443", "-p", password,
		"--verify", "--insecure"})
	if err == nil || strings.Contains(err.Error(), password) {
		t.Fatal("conflicting TLS flags accepted or secret exposed")
	}
	_, err = parseConfig([]string{"-s", "anytls://uri-secret@localhost:443/?sni=localhost", "--max-connections", "0"})
	if err == nil || strings.Contains(err.Error(), "uri-secret") {
		t.Fatal("invalid capacity accepted or URI secret exposed")
	}
	if _, err = parseConfig([]string{"--version"}); err != nil {
		t.Fatal(err)
	}
}

func TestRejectUnsupportedAuthAndCommand(t *testing.T) {
	_, address, stop := startTestRuntime(t, testConfig())
	defer stop()
	conn := dialLocal(t, address)
	_, _ = conn.Write([]byte{5, 1, 2})
	var reply [2]byte
	_, _ = io.ReadFull(conn, reply[:])
	if reply != [2]byte{5, 255} {
		t.Fatal("accepted unsupported SOCKS authentication")
	}
	conn = dialLocal(t, address)
	greeting(t, conn)
	_, _ = conn.Write([]byte{5, 2, 0, 1, 127, 0, 0, 1, 0, 80})
	var rejected [10]byte
	_, _ = io.ReadFull(conn, rejected[:])
	if rejected[1] != 7 {
		t.Fatal("unsupported SOCKS command did not receive failure reply")
	}
}
