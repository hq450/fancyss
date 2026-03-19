# fancyss 下的 NaiveProxy 配置实践

本文面向：

- `fancyss full` 版本用户
- 需要在 VPS 上自建 `NaiveProxy` 服务端，并在 `fancyss` 中配置使用的用户
- 服务端按 `naiveproxy` 官方推荐方案：`Caddy + forwardproxy(naive)`

不适用于：

- `fancyss lite` 版本
  - `lite` 包默认不带 `naive` 二进制
- 希望直接使用自签证书且不导入信任链的场景
  - `fancyss` 的 NaiveProxy 节点没有前端“跳过证书校验”开关

`NaiveProxy` 的官方推荐服务端并不是单独的 `naive-server`，而是：

- `Caddy`
- `klzgrad/forwardproxy` 的 `naive` 分支模块

官方文档：

- `naiveproxy`: <https://github.com/klzgrad/naiveproxy>
- `forwardproxy(naive)`: <https://github.com/klzgrad/forwardproxy/tree/naive>

---

## 一、先说结论

在 `fancyss` 中使用 `NaiveProxy`，建议遵循下面几条：

1. 服务端优先使用 `443` 端口 + 有效域名证书
2. 服务端按官方方案使用 `Caddy + forward_proxy`
3. `fancyss` 客户端推荐填写：
   - 协议：`https`
   - 服务器：`example.com`
   - 端口：`443`
   - 账户：`naive`
   - 密码：`password`
4. 用户名和密码尽量只用字母、数字和少量安全符号
   - 避免 `@`、`:`、`/`、`?`、`#` 这类 URL 保留字符
5. `NaiveProxy` 不支持 UDP
   - 在 `fancyss` 中会自动按“仅 TCP 代理”处理

---

## 二、fancyss 对 NaiveProxy 节点的处理方式

`fancyss` 中的 NaiveProxy 节点是独立类型，前端对应：

- 协议：`NaiveProxy 协议`
- 服务器：`NaiveProxy 服务器`
- 端口：`NaiveProxy 端口`
- 账户：`NaiveProxy 账户`
- 密码：`NaiveProxy 密码`

后端启动逻辑大致是：

1. 先启动 `ipt2socks`
2. 再启动 `naive`
3. `naive` 在本地监听 `127.0.0.1:23456`
4. `fancyss` 再通过 `ipt2socks` 接管透明代理流量

当前实现的关键点：

1. `NaiveProxy` 节点不支持 UDP
2. 如果服务器填写的是域名，`fancyss` 会先解析域名，再把解析结果传给 `naive`
3. 如果服务器本身填写的是 IP，`fancyss` 就直接连接这个 IP

所以：

- 推荐优先填写域名
- 只有你明确知道证书、SNI 和 IP 直连关系时，才建议直接填 IP

---

## 三、服务端推荐方案：Caddy + forwardproxy(naive)

这是 `naiveproxy` 官方推荐的服务端实现方式。

### 1. 准备条件

你需要先准备好：

1. 一台 VPS
2. 一个指向 VPS 的域名，例如：`example.com`
3. 开放 TCP `443` 端口
4. 一个可用证书
   - 推荐公开 CA 证书，比如 Let's Encrypt

如果你用自签证书：

- `curl` 测试时可以临时跳过校验
- 但 `fancyss` 的 NaiveProxy 节点默认不会跳过证书校验
- 所以自签证书场景通常不适合作为最终方案

### 2. 安装带 `forward_proxy` 模块的 Caddy

你有两种做法：

#### 方案 A：自己用 `xcaddy` 编译

参考官方 README 编译带插件的 Caddy。

#### 方案 B：直接使用 `forwardproxy` 项目的预编译版本

这是更直接的做法。

例如：

```bash
wget -O caddy-forwardproxy-naive.tar.xz \
  https://github.com/klzgrad/forwardproxy/releases/download/v2.10.0-naive/caddy-forwardproxy-naive.tar.xz
tar -xf caddy-forwardproxy-naive.tar.xz
install -m 0755 caddy-forwardproxy-naive/caddy /usr/local/bin/caddy
```

安装后可检查模块：

```bash
caddy list-modules | grep forward_proxy
```

正常应看到：

```bash
http.handlers.forward_proxy
```

### 3. Caddy 全局选项

按官方 `forwardproxy` 文档，建议在全局选项中加入：

```caddy
{
    order forward_proxy before file_server
}
```

如果你原来已经有其它全局配置，就把这一行并进去，不要重复写多个全局块。

### 4. 站点配置示例

下面给一个适合 `fancyss` 客户端的最小可用示例。

#### 示例 A：使用已有证书

```caddy
{
    order forward_proxy before file_server
}

:443, example.com {
    tls /path/to/cert/fullchain.pem /path/to/cert/privkey.pem

    forward_proxy {
        basic_auth naive password
        hide_ip
        hide_via
        probe_resistance
    }
}
```

#### 示例 B：同域名下还要挂其它服务

如果你同一个域名下已经有其它网站或反代路径，也可以共存：

```caddy
{
    order forward_proxy before file_server
}

:443, example.com {
    tls /path/to/cert/fullchain.pem /path/to/cert/privkey.pem

    forward_proxy {
        basic_auth naive password
        hide_ip
        hide_via
        probe_resistance
    }

    reverse_proxy /app/* 127.0.0.1:10000
    file_server
}
```

要点：

1. `forward_proxy` 必须启用
2. `basic_auth` 就是客户端要填的用户名和密码
3. 推荐保留：
   - `hide_ip`
   - `hide_via`
   - `probe_resistance`
4. 站点地址建议写成：
   - `:443, example.com`

### 5. 配置检查与启动

```bash
caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile
systemctl restart caddy
systemctl is-active caddy
```

如果是 `active`，说明 Caddy 已正常启动。

---

## 四、服务端可用性测试

服务端配好后，先不要急着在路由器上配节点，先在 VPS 外部做一次代理测试。

例如在本地电脑或另一台 Linux 上执行：

```bash
curl --proxy-insecure -sS -o /dev/null -w "%{http_code}\n" \
  -x https://naive:password@example.com:443 \
  https://www.gstatic.com/generate_204
```

返回：

```bash
204
```

说明至少这几件事是通的：

1. 域名可访问
2. 443 端口可访问
3. TLS 握手正常
4. `forward_proxy` 生效
5. 用户名密码正确

注意：

- `--proxy-insecure` 这里只是为了方便 `curl` 测试
- 不代表 `fancyss` 会这样工作
- `fancyss` 仍然建议配合有效证书使用

---

## 五、fancyss 客户端填写方法

在 `fancyss` 的账号设置中新增一个 `NaïveProxy` 节点，按下面填写：

### 推荐填写示例

- 协议：`https`
- 服务器：`example.com`
- 端口：`443`
- 账户：`naive`
- 密码：`password`

对应关系如下：

| fancyss 字段 | 服务端配置来源 |
|---|---|
| NaïveProxy 协议 | `https` |
| NaïveProxy 服务器 | Caddy 所在域名，如 `example.com` |
| NaïveProxy 端口 | Caddy 监听端口，推荐 `443` |
| NaïveProxy 账户 | `forward_proxy` 里的 `basic_auth` 用户名 |
| NaïveProxy 密码 | `forward_proxy` 里的 `basic_auth` 密码 |

### 实际建议

1. 服务器优先填写域名，不要直接填 IP
2. 端口优先使用 `443`
3. 账户和密码尽量使用简单、安全、可打印字符
4. 避免在用户名/密码里使用 URL 保留字符

不推荐的密码例子：

- `pass@word`
- `abc:def`
- `abc/def`

推荐的密码例子：

- `password`
- `pass_word_123`
- `Naive2026Test`

原因是 `fancyss` 当前会直接拼接 Naive 的代理 URL，如果使用 URL 保留字符，容易引入解析歧义。

---

## 六、一个完整的可用示例

### 1. 服务端 Caddyfile

```caddy
{
    admin off
    http_port 80
    https_port 443
    order forward_proxy before file_server
}

:443, example.com {
    tls /path/to/cert/fullchain.pem /path/to/cert/privkey.pem

    forward_proxy {
        basic_auth naive password
        hide_ip
        hide_via
        probe_resistance
    }
}
```

### 2. fancyss 节点

- 节点类型：`NaïveProxy`
- 协议：`https`
- 服务器：`example.com`
- 端口：`443`
- 账户：`naive`
- 密码：`password`

---

## 七、fancyss 启动后的预期现象

当你切换到 Naive 节点并启动插件后，日志里通常会看到类似内容：

1. 先解析服务器域名
2. 启动 `ipt2socks`
3. 启动 `naive`
4. 输出代理出口 IP

例如：

```text
检测到你的Naïve服务器：【example.com】不是ip格式！
尝试解析Naïve服务器域名...
Naïve服务器【example.com】的ip地址解析成功：1.2.3.4
开启ipt2socks进程...
开启NaïveProxy主进程...
代理服务器出口地址：x.x.x.x
节点服务器解析地址：1.2.3.4
```

如果日志能走到这里，说明节点大概率已经正常工作。

---

## 八、常见问题

### 1. 为什么建议用域名，不建议直接填 IP？

因为 Naive 本质上跑在 HTTPS/TLS 上：

1. 域名更符合证书校验和 SNI 使用方式
2. `fancyss` 会自动解析域名并传给 `naive`
3. 证书一般也是签给域名，不是签给裸 IP

只有在下面这种场景下才建议直接填 IP：

- 你明确知道证书里包含了 IP SAN
- 或者你清楚自己为什么要这样配

### 2. 能不能用自签证书？

不推荐。

原因：

1. `fancyss` 的 NaiveProxy 节点没有类似 `skip_cert_verify` 的前端开关
2. `naive` 客户端本身默认依赖系统信任链
3. 所以自签证书通常会因为证书校验失败而无法正常使用

结论：

- 正式使用请配公开可信证书

### 3. 为什么 Naive 节点下 UDP 不生效？

因为 `NaiveProxy` 本身就不支持 UDP。

在 `fancyss` 中：

- Naive 节点会被按“仅 TCP 代理”处理
- UDP 相关能力不能按 SS/Xray/TUIC 那样工作

### 4. 服务端已经能 `curl 204`，但 fancyss 还是不通，先看什么？

优先检查：

1. `fancyss` 是否是 `full` 版本
2. `/koolshare/bin/naive` 是否存在且可执行
3. 节点里的服务器、端口、账户、密码是否和 Caddy 一致
4. 用户名/密码里是否含有 URL 保留字符
5. 域名解析是否正确
6. VPS 的 `443/TCP` 是否真的对外开放

---

## 九、推荐实践

如果你是第一次在 `fancyss` 中用 Naive，建议按这个顺序做：

1. 先准备好域名和有效证书
2. 用官方推荐方案部署 `Caddy + forward_proxy`
3. 先用 `curl -x https://user:pass@example.com:443` 验证服务端
4. 再去 `fancyss` 里添加 Naive 节点
5. 启动后用日志确认：
   - 域名解析成功
   - `ipt2socks` 启动成功
   - `naive` 启动成功
   - 出口 IP 正常

这样排查路径最短，也最稳。
