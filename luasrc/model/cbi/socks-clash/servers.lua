local m, s, o
local fs = require "nixio.fs"

m = Map("socks-clash", "代理服务器",
    "管理代理服务器配置。您可以在此添加、编辑或删除代理服务器。")

-- Proxy Servers
s = m:section(TypedSection, "proxy_server", "代理服务器列表")
s.anonymous = true
s.addremove = true
s.sortable = true
s.template = "cbi/tblsection"

-- Server Name
o = s:option(Value, "name", "名称")
o.rmempty = false
o.placeholder = "服务器名称"

-- Server Type
o = s:option(ListValue, "type", "类型")
o:value("ss", "Shadowsocks")
o:value("ssr", "ShadowsocksR")
o:value("vmess", "VMess")
o:value("vless", "VLESS")
o:value("trojan", "Trojan")
o:value("hysteria", "Hysteria")
o:value("hysteria2", "Hysteria2")
o:value("tuic", "TUIC")
o:value("socks5", "SOCKS5")
o:value("http", "HTTP")
o.default = "ss"

-- Server Address
o = s:option(Value, "server", "服务器")
o.rmempty = false
o.datatype = "host"
o.placeholder = "服务器地址"

-- Server Port
o = s:option(Value, "port", "端口")
o.rmempty = false
o.datatype = "port"

-- Enable/Disable
o = s:option(Flag, "enabled", "启用")
o.default = "1"

-- Full configuration form
local ss = m:section(NamedSection, "new_server", "proxy_server", "新建服务器配置")
ss.anonymous = true
ss.addremove = false

o = ss:option(Value, "name", "名称")
o.rmempty = false

o = ss:option(ListValue, "type", "类型")
o:value("ss", "Shadowsocks")
o:value("ssr", "ShadowsocksR")
o:value("vmess", "VMess")
o:value("vless", "VLESS")
o:value("trojan", "Trojan")
o:value("hysteria", "Hysteria")
o:value("hysteria2", "Hysteria2")
o:value("tuic", "TUIC")
o:value("socks5", "SOCKS5")
o:value("http", "HTTP")

o = ss:option(Value, "server", "服务器地址")
o.rmempty = false
o.datatype = "host"

o = ss:option(Value, "port", "端口")
o.rmempty = false
o.datatype = "port"

-- Shadowsocks specific
o = ss:option(ListValue, "cipher", "加密方式")
o:value("aes-128-gcm", "aes-128-gcm")
o:value("aes-192-gcm", "aes-192-gcm")
o:value("aes-256-gcm", "aes-256-gcm")
o:value("chacha20-ietf-poly1305", "chacha20-ietf-poly1305")
o:value("xchacha20-ietf-poly1305", "xchacha20-ietf-poly1305")
o:value("2022-blake3-aes-128-gcm", "2022-blake3-aes-128-gcm")
o:value("2022-blake3-aes-256-gcm", "2022-blake3-aes-256-gcm")
o:value("2022-blake3-chacha20-poly1305", "2022-blake3-chacha20-poly1305")
o.default = "aes-256-gcm"
o:depends("type", "ss")

o = ss:option(Value, "password", "密码")
o.password = true
o:depends("type", "ss")
o:depends("type", "ssr")
o:depends("type", "trojan")

-- VMess/VLESS specific
o = ss:option(Value, "uuid", "UUID")
o:depends("type", "vmess")
o:depends("type", "vless")

o = ss:option(Value, "alterId", "额外 ID")
o.datatype = "uinteger"
o.default = "0"
o:depends("type", "vmess")

-- Network
o = ss:option(ListValue, "network", "传输协议")
o:value("tcp", "TCP")
o:value("ws", "WebSocket")
o:value("grpc", "gRPC")
o:value("h2", "HTTP/2")
o:value("quic", "QUIC")
o.default = "tcp"
o:depends("type", "vmess")
o:depends("type", "vless")
o:depends("type", "trojan")

-- TLS
o = ss:option(Flag, "tls", "TLS")
o.default = "0"
o:depends("type", "vmess")
o:depends("type", "vless")
o:depends("type", "trojan")

-- SNI
o = ss:option(Value, "sni", "SNI")
o:depends("tls", "1")

-- Skip Cert Verify
o = ss:option(Flag, "skip_cert_verify", "跳过证书验证")
o.default = "0"
o:depends("tls", "1")

-- WebSocket Path
o = ss:option(Value, "ws_path", "WebSocket 路径")
o.placeholder = "/path"
o:depends("network", "ws")

-- WebSocket Host
o = ss:option(Value, "ws_host", "WebSocket 主机")
o:depends("network", "ws")

-- gRPC Service Name
o = ss:option(Value, "grpc_service_name", "gRPC 服务名")
o:depends("network", "grpc")

return m
