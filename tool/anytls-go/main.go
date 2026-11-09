// SPDX-License-Identifier: GPL-3.0-or-later
package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"io"
	"net"
	"net/url"
	"os"
	"os/signal"
	"runtime/debug"
	"strconv"
	"strings"
	"syscall"
	"time"
)

var version = "0.1.0"

func parseConfig(args []string) (config, error) {
	cfg := config{}
	flags := flag.NewFlagSet("anytls-go", flag.ContinueOnError)
	flags.SetOutput(io.Discard)
	var uri, uriFile, passwordFile string
	var verify bool
	flags.StringVar(&cfg.Listen, "l", "127.0.0.1:18081", "SOCKS listen address")
	flags.StringVar(&cfg.Listen, "listen", "127.0.0.1:18081", "SOCKS listen address")
	flags.StringVar(&cfg.Server, "server", "", "AnyTLS endpoint")
	flags.StringVar(&uri, "s", "", "AnyTLS URI")
	flags.StringVar(&uri, "server-uri", "", "AnyTLS URI")
	flags.StringVar(&uriFile, "server-uri-file", "", "AnyTLS URI file")
	flags.StringVar(&cfg.Password, "p", "", "AnyTLS password (prefer password-file)")
	flags.StringVar(&cfg.Password, "password", "", "AnyTLS password (prefer password-file)")
	flags.StringVar(&passwordFile, "password-file", "", "AnyTLS password file")
	flags.StringVar(&cfg.SNI, "sni", "", "TLS server name")
	flags.BoolVar(&cfg.Insecure, "insecure", false, "Explicitly disable certificate verification")
	flags.BoolVar(&verify, "verify", false, "Verify certificate and server name (default)")
	flags.BoolVar(&cfg.Version, "version", false, "Print backend version")
	flags.BoolVar(&cfg.DisableReuse, "dr", false, "Disable AnyTLS session reuse")
	flags.IntVar(&cfg.MaxConnections, "max-connections", 256, "Maximum admitted SOCKS connections")
	flags.DurationVar(&cfg.HandshakeTimeout, "handshake-timeout", 10*time.Second, "Local SOCKS negotiation deadline")
	flags.DurationVar(&cfg.DialTimeout, "dial-timeout", 10*time.Second, "Upstream DNS/TCP/TLS setup deadline")
	flags.DurationVar(&cfg.WriteTimeout, "write-timeout", 10*time.Second, "Upstream blocked-write deadline")
	if len(args) == 1 && args[0] == "version" {
		cfg.Version = true
		return cfg, nil
	}
	if err := flags.Parse(args); err != nil {
		if errors.Is(err, flag.ErrHelp) {
			return cfg, flag.ErrHelp
		}
		return cfg, errors.New("invalid command-line options")
	}
	if cfg.Version {
		return cfg, nil
	}
	if flags.NArg() != 0 || (verify && cfg.Insecure) {
		return cfg, errors.New("unexpected arguments or conflicting TLS flags")
	}
	if uriFile != "" {
		data, err := os.ReadFile(uriFile)
		if err != nil {
			return cfg, errors.New("cannot read AnyTLS URI file")
		}
		uri = string(data)
	}
	if uri != "" {
		u, err := url.Parse(strings.TrimSpace(uri))
		if err != nil || u.Scheme != "anytls" || u.User == nil {
			return cfg, errors.New("invalid AnyTLS URI")
		}
		cfg.Server = u.Host
		cfg.Password = u.User.Username()
		if cfg.SNI == "" {
			cfg.SNI = u.Query().Get("sni")
		}
		if !verify && !cfg.Insecure {
			cfg.Insecure, _ = strconv.ParseBool(u.Query().Get("insecure"))
		}
	}
	if passwordFile != "" {
		data, err := os.ReadFile(passwordFile)
		if err != nil {
			return cfg, errors.New("cannot read AnyTLS password file")
		}
		cfg.Password = string(data)
	}
	if err := cfg.validate(); err != nil {
		return cfg, err
	}
	if _, _, err := net.SplitHostPort(cfg.Listen); err != nil {
		return cfg, errors.New("invalid SOCKS listen address")
	}
	return cfg, nil
}

func run(args []string) error {
	cfg, err := parseConfig(args)
	if errors.Is(err, flag.ErrHelp) {
		fmt.Println("anytls-go (fancyss compatibility): -server HOST:PORT --password-file PATH -l HOST:PORT [-sni NAME] [--verify|--insecure]")
		return nil
	}
	if err != nil {
		return err
	}
	if cfg.Version {
		fmt.Printf("anytls-go %s (fancyss CLI compatibility; sing-anytls v0.0.13)\n", version)
		return nil
	}
	debug.SetMemoryLimit(64 << 20)
	s, err := newServer(cfg)
	if err != nil {
		return err
	}
	listener, err := net.Listen("tcp", cfg.Listen)
	if err != nil {
		s.close()
		return err
	}
	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer cancel()
	return s.serve(ctx, listener)
}

func main() {
	if err := run(os.Args[1:]); err != nil {
		fmt.Fprintln(os.Stderr, "anytls-go:", err)
		os.Exit(1)
	}
}
