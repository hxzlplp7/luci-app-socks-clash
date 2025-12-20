local m, s, o
local fs = require "nixio.fs"

m = Map("socks-clash", translate("Proxy Servers"),
    translate("Manage proxy server configurations. You can add, edit, or delete proxy servers here."))

-- Proxy Servers
s = m:section(TypedSection, "proxy_server", translate("Proxy Servers"))
s.anonymous = true
s.addremove = true
s.sortable = true
s.template = "cbi/tblsection"

-- Server Name
o = s:option(Value, "name", translate("Name"))
o.rmempty = false
o.placeholder = translate("Server name")

-- Server Type
o = s:option(ListValue, "type", translate("Type"))
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
o = s:option(Value, "server", translate("Server"))
o.rmempty = false
o.datatype = "host"
o.placeholder = translate("Server address")

-- Server Port
o = s:option(Value, "port", translate("Port"))
o.rmempty = false
o.datatype = "port"

-- Enable/Disable
o = s:option(Flag, "enabled", translate("Enable"))
o.default = "1"

-- More detailed settings page
s = m:section(TypedSection, "proxy_server", translate("Add New Server"))
s.anonymous = true
s.addremove = true
s.template = "cbi/tblsection"
s.hidden = true

-- Full configuration form
local ss = m:section(NamedSection, "new_server", "proxy_server", translate("New Server Configuration"))
ss.anonymous = true
ss.addremove = false

o = ss:option(Value, "name", translate("Name"))
o.rmempty = false

o = ss:option(ListValue, "type", translate("Type"))
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

o = ss:option(Value, "server", translate("Server Address"))
o.rmempty = false
o.datatype = "host"

o = ss:option(Value, "port", translate("Port"))
o.rmempty = false
o.datatype = "port"

-- Shadowsocks specific
o = ss:option(ListValue, "cipher", translate("Cipher"))
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

o = ss:option(Value, "password", translate("Password"))
o.password = true
o:depends("type", "ss")
o:depends("type", "ssr")
o:depends("type", "trojan")

-- VMess/VLESS specific
o = ss:option(Value, "uuid", translate("UUID"))
o:depends("type", "vmess")
o:depends("type", "vless")

o = ss:option(Value, "alterId", translate("Alter ID"))
o.datatype = "uinteger"
o.default = "0"
o:depends("type", "vmess")

-- Network
o = ss:option(ListValue, "network", translate("Network"))
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
o = ss:option(Flag, "tls", translate("TLS"))
o.default = "0"
o:depends("type", "vmess")
o:depends("type", "vless")
o:depends("type", "trojan")

-- SNI
o = ss:option(Value, "sni", translate("SNI"))
o:depends("tls", "1")

-- Skip Cert Verify
o = ss:option(Flag, "skip_cert_verify", translate("Skip Certificate Verify"))
o.default = "0"
o:depends("tls", "1")

-- WebSocket Path
o = ss:option(Value, "ws_path", translate("WebSocket Path"))
o.placeholder = "/path"
o:depends("network", "ws")

-- WebSocket Host
o = ss:option(Value, "ws_host", translate("WebSocket Host"))
o:depends("network", "ws")

-- gRPC Service Name
o = ss:option(Value, "grpc_service_name", translate("gRPC Service Name"))
o:depends("network", "grpc")

return m
