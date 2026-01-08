# xray和v2ray差异 

 出站协议差异（proxy）

  - 两者共有（都能作为 outbound 使用）：vmess、vless、trojan、shadowsocks、socks、http、freedom、blackhole、dns（以及内部用的 loopback）。
  - Xray-core 独有：
      - wireguard（proxy/wireguard）
      - VLESS/VMess 相关的 XTLS/REALITY 能力是 Xray 的核心扩展（v2ray-core 源码里没有 reality/xtls/vision 相关实现）。
      - shadowsocks_2022（目录名带下划线：proxy/shadowsocks_2022）
  - v2ray-core 独有：
      - hysteria2（proxy/hysteria2，可 inbound/outbound）
      - vlite（proxy/vlite，其 proto short name 里可见 vliteu）

  底层传输差异（transport/internet）

  - 两者共有（都有对应传输目录）：tcp、udp、websocket、mkcp（目录名 kcp，协议名是 mkcp）、httpupgrade、grpc（但注意名字差异见下条）。
  - 命名/实现差异（很关键）
      - v2ray-core：gRPC 传输的 protocolName 是 gun（transport/internet/grpc/config.go），配置层通常写 grpc 但内部映射到 gun。
      - xray-core：gRPC 传输的 protocolName 直接就是 grpc（transport/internet/grpc/grpc.go）。
  - Xray-core 独有传输/安全层
      - splithttp：XHTTP 实现（配置里常见 network: "xhttp"，底层实现对应 splithttp，并且源码里可见对 XHTTP/3/QUIC 的支持逻辑集中在这里，而不是单独一个 quic 传输目录）。
      - reality：REALITY 安全层（配合 security: "reality" / realitySettings），v2ray-core 没有该目录与实现。
  - v2ray-core 独有传输/相关组件
      - http：标准 HTTP/2（h2）传输（xray-core 这版源码里没有 transport/internet/http 目录）
      - quic：独立 QUIC 传输（xray-core 没有独立 quic 传输目录）
      - dtls、domainsocket、hysteria2（同时存在 proxy 与 transport 两侧）、以及一些支撑目录如 tlsmirror、transportcommon、security、request 等（xray-core 这版对应结构不同/部分不存在）。