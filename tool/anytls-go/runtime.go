// SPDX-License-Identifier: GPL-3.0-or-later
package main

import (
	"context"
	"crypto/tls"
	"crypto/x509"
	"encoding/binary"
	"errors"
	"io"
	"net"
	"strconv"
	"sync"
	"time"

	anytls "github.com/anytls/sing-anytls"
	"github.com/sagernet/sing/common/logger"
	M "github.com/sagernet/sing/common/metadata"
)

type config struct {
	Listen, Server, Password, SNI               string
	Insecure, DisableReuse, Version             bool
	MaxConnections                              int
	HandshakeTimeout, DialTimeout, WriteTimeout time.Duration
	Resolver                                    *net.Resolver
	RootCAs                                     *x509.CertPool
}

func (c config) validate() error {
	host, port, err := net.SplitHostPort(c.Server)
	if err != nil || host == "" {
		return errors.New("invalid AnyTLS endpoint")
	}
	n, err := strconv.Atoi(port)
	if err != nil || n < 1 || n > 65535 || c.Password == "" {
		return errors.New("missing password or invalid AnyTLS port")
	}
	if c.MaxConnections < 1 || c.MaxConnections > 4096 {
		return errors.New("max-connections must be between 1 and 4096")
	}
	if c.HandshakeTimeout <= 0 || c.DialTimeout <= 0 || c.WriteTimeout <= 0 {
		return errors.New("timeouts must be positive")
	}
	return nil
}

type server struct {
	cfg        config
	ctx        context.Context
	cancel     context.CancelFunc
	backend    *anytls.Client
	slots      chan struct{}
	mu         sync.Mutex
	clients    map[net.Conn]struct{}
	transports map[net.Conn]struct{}
	listener   net.Listener
	closed     bool
	closeOnce  sync.Once
	wg         sync.WaitGroup
}

func newServer(cfg config) (*server, error) {
	if err := cfg.validate(); err != nil {
		return nil, err
	}
	ctx, cancel := context.WithCancel(context.Background())
	s := &server{cfg: cfg, ctx: ctx, cancel: cancel, slots: make(chan struct{}, cfg.MaxConnections),
		clients: make(map[net.Conn]struct{}), transports: make(map[net.Conn]struct{})}
	client, err := anytls.NewClient(ctx, anytls.ClientConfig{
		Password: cfg.Password, DialOut: s.dialTLS, Logger: logger.NOP(),
		IdleSessionCheckInterval: 6 * time.Second, IdleSessionTimeout: 30 * time.Second,
		MinIdleSession: 0, DisableReuse: cfg.DisableReuse,
	})
	if err != nil {
		cancel()
		return nil, err
	}
	s.backend = client
	return s, nil
}

func (s *server) serve(ctx context.Context, listener net.Listener) error {
	s.mu.Lock()
	s.listener = listener
	s.mu.Unlock()
	done := make(chan struct{})
	go func() {
		select {
		case <-ctx.Done():
			s.close()
		case <-done:
		}
	}()
	defer func() {
		close(done)
		s.close()
		s.wg.Wait()
		// A setup finishing concurrently with cancellation must not leave a session behind.
		_ = s.backend.Close()
	}()
	for {
		conn, err := listener.Accept()
		if err != nil {
			s.mu.Lock()
			closed := s.closed
			s.mu.Unlock()
			if closed || ctx.Err() != nil {
				return nil
			}
			return err
		}
		select {
		case s.slots <- struct{}{}:
		default:
			_ = conn.Close()
			continue
		}
		s.mu.Lock()
		if s.closed {
			s.mu.Unlock()
			<-s.slots
			_ = conn.Close()
			continue
		}
		s.clients[conn] = struct{}{}
		s.wg.Add(1)
		s.mu.Unlock()
		go func() {
			defer s.wg.Done()
			defer func() {
				_ = conn.Close()
				s.mu.Lock()
				delete(s.clients, conn)
				s.mu.Unlock()
				<-s.slots
			}()
			_ = s.handle(conn)
		}()
	}
}

func (s *server) close() {
	s.closeOnce.Do(func() {
		s.cancel()
		s.mu.Lock()
		s.closed = true
		listener := s.listener
		connections := make([]net.Conn, 0, len(s.clients)+len(s.transports))
		for conn := range s.clients {
			connections = append(connections, conn)
		}
		for conn := range s.transports {
			connections = append(connections, conn)
		}
		s.mu.Unlock()
		if listener != nil {
			_ = listener.Close()
		}
		for _, conn := range connections {
			_ = conn.Close()
		}
		_ = s.backend.Close()
	})
}

type trackedConn struct {
	net.Conn
	server *server
	once   sync.Once
}

func (c *trackedConn) Close() error {
	var err error
	c.once.Do(func() {
		err = c.Conn.Close()
		c.server.mu.Lock()
		delete(c.server.transports, c)
		c.server.mu.Unlock()
	})
	return err
}

type boundedConn struct {
	net.Conn
	timeout           time.Duration
	mu                sync.Mutex
	deadlineMu        sync.Mutex
	requestedDeadline time.Time
	activeDeadline    time.Time
	writing           bool
}

func (c *boundedConn) SetWriteDeadline(deadline time.Time) error {
	c.deadlineMu.Lock()
	defer c.deadlineMu.Unlock()
	c.requestedDeadline = deadline
	// Library control-frame clears must not erase another writer's hard bound.
	if c.writing && !deadline.IsZero() && deadline.Before(c.activeDeadline) {
		c.activeDeadline = deadline
		return c.Conn.SetWriteDeadline(deadline)
	}
	return nil
}

func (c *boundedConn) SetDeadline(deadline time.Time) error {
	if err := c.Conn.SetReadDeadline(deadline); err != nil {
		return err
	}
	return c.SetWriteDeadline(deadline)
}

func (c *boundedConn) Write(data []byte) (int, error) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.deadlineMu.Lock()
	deadline := time.Now().Add(c.timeout)
	if !c.requestedDeadline.IsZero() && c.requestedDeadline.Before(deadline) {
		deadline = c.requestedDeadline
	}
	c.activeDeadline, c.writing = deadline, true
	err := c.Conn.SetWriteDeadline(deadline)
	c.deadlineMu.Unlock()
	if err != nil {
		c.deadlineMu.Lock()
		c.writing = false
		c.deadlineMu.Unlock()
		_ = c.Conn.Close()
		return 0, err
	}
	n, err := c.Conn.Write(data)
	c.deadlineMu.Lock()
	c.writing = false
	c.deadlineMu.Unlock()
	if err != nil {
		_ = c.Conn.Close()
	}
	return n, err
}

func (s *server) dialTLS(ctx context.Context) (net.Conn, error) {
	ctx, cancel := context.WithTimeout(ctx, s.cfg.DialTimeout)
	defer cancel()
	resolver := s.cfg.Resolver
	if resolver == nil {
		resolver = &net.Resolver{PreferGo: true}
	}
	dialer := net.Dialer{Timeout: s.cfg.DialTimeout, KeepAlive: 30 * time.Second, Resolver: resolver}
	raw, err := dialer.DialContext(ctx, "tcp", s.cfg.Server)
	if err != nil {
		return nil, err
	}
	tracked := &trackedConn{Conn: raw, server: s}
	s.mu.Lock()
	if s.closed || len(s.transports) >= s.cfg.MaxConnections {
		s.mu.Unlock()
		_ = raw.Close()
		return nil, errors.New("upstream transport admission limit reached or runtime closed")
	}
	s.transports[tracked] = struct{}{}
	s.mu.Unlock()
	name := s.cfg.SNI
	if name == "" {
		name, _, _ = net.SplitHostPort(s.cfg.Server)
	}
	conn := tls.Client(tracked, &tls.Config{ServerName: name, RootCAs: s.cfg.RootCAs,
		InsecureSkipVerify: s.cfg.Insecure, MinVersion: tls.VersionTLS12})
	if err := conn.HandshakeContext(ctx); err != nil {
		_ = tracked.Close()
		return nil, err
	}
	return &boundedConn{Conn: conn, timeout: s.cfg.WriteTimeout}, nil
}

func socksReply(conn net.Conn, code byte) error {
	_, err := conn.Write([]byte{5, code, 0, 1, 0, 0, 0, 0, 0, 0})
	return err
}

func readTarget(conn net.Conn) (M.Socksaddr, error) {
	var header [4]byte
	if _, err := io.ReadFull(conn, header[:]); err != nil {
		return M.Socksaddr{}, err
	}
	if header[0] != 5 || header[2] != 0 || header[1] != 1 {
		_ = socksReply(conn, 7)
		return M.Socksaddr{}, errors.New("unsupported SOCKS command")
	}
	var host string
	switch header[3] {
	case 1, 4:
		size := 4
		if header[3] == 4 {
			size = 16
		}
		data := make([]byte, size)
		if _, err := io.ReadFull(conn, data); err != nil {
			return M.Socksaddr{}, err
		}
		host = net.IP(data).String()
	case 3:
		var size [1]byte
		if _, err := io.ReadFull(conn, size[:]); err != nil {
			return M.Socksaddr{}, err
		}
		if size[0] == 0 {
			return M.Socksaddr{}, errors.New("empty SOCKS target")
		}
		data := make([]byte, int(size[0]))
		if _, err := io.ReadFull(conn, data); err != nil {
			return M.Socksaddr{}, err
		}
		host = string(data)
	default:
		_ = socksReply(conn, 8)
		return M.Socksaddr{}, errors.New("unsupported SOCKS address type")
	}
	var port [2]byte
	if _, err := io.ReadFull(conn, port[:]); err != nil {
		return M.Socksaddr{}, err
	}
	if binary.BigEndian.Uint16(port[:]) == 0 {
		return M.Socksaddr{}, errors.New("invalid SOCKS target port")
	}
	return M.ParseSocksaddr(net.JoinHostPort(host, strconv.Itoa(int(binary.BigEndian.Uint16(port[:]))))), nil
}

func (s *server) handle(conn net.Conn) error {
	if err := conn.SetDeadline(time.Now().Add(s.cfg.HandshakeTimeout)); err != nil {
		return err
	}
	var header [2]byte
	if _, err := io.ReadFull(conn, header[:]); err != nil {
		return err
	}
	if header[0] != 5 || header[1] == 0 {
		return errors.New("invalid SOCKS greeting")
	}
	methods := make([]byte, int(header[1]))
	if _, err := io.ReadFull(conn, methods); err != nil {
		return err
	}
	noAuth := false
	for _, method := range methods {
		noAuth = noAuth || method == 0
	}
	if !noAuth {
		_, _ = conn.Write([]byte{5, 255})
		return errors.New("unsupported SOCKS authentication")
	}
	if _, err := conn.Write([]byte{5, 0}); err != nil {
		return err
	}
	destination, err := readTarget(conn)
	if err != nil {
		return err
	}
	if err := conn.SetDeadline(time.Time{}); err != nil {
		return err
	}
	ctx, cancel := context.WithTimeout(s.ctx, s.cfg.DialTimeout)
	defer cancel()
	remote, err := s.backend.CreateProxy(ctx, destination)
	_ = conn.SetWriteDeadline(time.Now().Add(s.cfg.HandshakeTimeout))
	if err != nil {
		_ = socksReply(conn, 1)
		return err
	}
	defer remote.Close()
	if err := socksReply(conn, 0); err != nil {
		return err
	}
	if err := conn.SetDeadline(time.Time{}); err != nil {
		return err
	}
	relay(conn, remote, s.cfg.WriteTimeout)
	return nil
}

func relay(client, remote net.Conn, writeTimeout time.Duration) {
	client = &boundedConn{Conn: client, timeout: writeTimeout}
	remote = &boundedConn{Conn: remote, timeout: writeTimeout}
	done := make(chan struct{}, 1)
	go func() { _, _ = io.Copy(remote, client); done <- struct{}{} }()
	finished := make(chan struct{}, 1)
	go func() { _, _ = io.Copy(client, remote); finished <- struct{}{} }()
	select {
	case <-done:
		_ = client.Close()
		_ = remote.Close()
		<-finished
	case <-finished:
		_ = client.Close()
		_ = remote.Close()
		<-done
	}
}
