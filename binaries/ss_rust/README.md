## 说明

因shadowsocks-rust的二进制体积越来越大，从官方release下载后upx压缩，体积还是很大。因此从v1.20.3版本开始，不再使用`get_latest.sh`从官方下载，二是通过官方源代码进行编译，编译删除了`logging` `hickory-dns` `dns-over-tls` `dns-over-https` `local-http` `local-http-rustls` `local-socks4` `local-dns` `local-tun` `local-fake-dns` `local-online-config`这些fancyss用不到的特性，这样编译出的二进制大概在6MB左右，用upx压缩后可以维持在1.8MB左右。

## 编译方法

### arm64
```bash
docker pull messense/rust-musl-cross:aarch64-musl
alias rust-musl-builder='docker run --rm -it -v "$(pwd)":/home/rust/src messense/rust-musl-cross:aarch64-musl'
rust-musl-builder cargo build --release --features "local local-tunnel local-redir multi-threaded stream-cipher aead-cipher-2022"
```

### arm7

```bash
docker pull messense/rust-musl-cross:armv7-musleabihf
alias rust-musl-builder='docker run --rm -it -v "$(pwd)":/home/rust/src messense/rust-musl-cross:armv7-musleabihf'
rust-musl-builder cargo build --release --features "local local-tunnel local-redir multi-threaded stream-cipher aead-cipher-2022"
```


### arm5
```bash
docker pull messense/rust-musl-cross:arm-musleabi
alias rust-musl-builder='docker run --rm -it -v "$(pwd)":/home/rust/src messense/rust-musl-cross:arm-musleabi'
rust-musl-builder cargo build --release --features "local local-tunnel local-redir multi-threaded stream-cipher aead-cipher-2022"
```

编译完成后可以在`$(pwd)/target`下找到对应二进制文件，二进制文件需要进一步经过upx压缩即可使用
