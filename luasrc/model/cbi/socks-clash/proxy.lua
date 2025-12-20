local m, s, o

m = Map("socks-clash", translate("Proxy Port Settings"),
    translate("Configure SOCKS5, HTTP, and Mixed proxy ports."))

s = m:section(TypedSection, "socks-clash", translate("SOCKS5 Proxy"))
s.anonymous = true
s.addremove = false

-- SOCKS5 Enable
o = s:option(Flag, "socks_enabled", translate("Enable SOCKS5 Proxy"))
o.default = "1"

-- SOCKS5 Port
o = s:option(Value, "socks_port", translate("SOCKS5 Port"))
o.datatype = "port"
o.default = "7891"
o:depends("socks_enabled", "1")

s = m:section(TypedSection, "socks-clash", translate("HTTP Proxy"))
s.anonymous = true
s.addremove = false

-- HTTP Enable
o = s:option(Flag, "http_enabled", translate("Enable HTTP Proxy"))
o.default = "1"

-- HTTP Port
o = s:option(Value, "http_port", translate("HTTP Port"))
o.datatype = "port"
o.default = "7890"
o:depends("http_enabled", "1")

s = m:section(TypedSection, "socks-clash", translate("Mixed Proxy (SOCKS5 + HTTP)"))
s.anonymous = true
s.addremove = false

-- Mixed Enable
o = s:option(Flag, "mixed_enabled", translate("Enable Mixed Proxy"))
o.default = "0"
o.description = translate("Mixed port supports both SOCKS5 and HTTP protocols on the same port")

-- Mixed Port
o = s:option(Value, "mixed_port", translate("Mixed Port"))
o.datatype = "port"
o.default = "7893"
o:depends("mixed_enabled", "1")

s = m:section(TypedSection, "socks-clash", translate("Usage Instructions"))
s.anonymous = true
s.addremove = false
s.template = "socks-clash/proxy_usage"

return m
