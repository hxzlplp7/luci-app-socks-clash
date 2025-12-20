local m, s, o

m = Map("socks-clash", translate("SocksClash Settings"),
    translate("Configure SocksClash proxy settings. This is a simplified proxy-only mode without DNS hijacking or transparent proxy."))

s = m:section(TypedSection, "socks-clash", translate("General Settings"))
s.anonymous = true
s.addremove = false

-- Enable
o = s:option(Flag, "enable", translate("Enable"))
o.rmempty = false
o.default = "0"

-- Log Level
o = s:option(ListValue, "log_level", translate("Log Level"))
o:value("silent", translate("Silent"))
o:value("error", translate("Error"))
o:value("warning", translate("Warning"))
o:value("info", translate("Info"))
o:value("debug", translate("Debug"))
o.default = "info"

-- Proxy Mode
o = s:option(ListValue, "mode", translate("Proxy Mode"))
o:value("rule", translate("Rule Mode"))
o:value("global", translate("Global Mode"))
o:value("direct", translate("Direct Mode"))
o.default = "rule"
o.description = translate("Rule: Route based on rules | Global: All traffic through proxy | Direct: All direct connection")

-- Allow LAN
o = s:option(Flag, "allow_lan", translate("Allow LAN"))
o.default = "1"
o.description = translate("Allow connections from LAN devices")

-- Bind Address
o = s:option(Value, "bind_address", translate("Bind Address"))
o.default = "*"
o.placeholder = "*"
o.description = translate("'*' for all interfaces, or specify an IP address")

-- IPv6
o = s:option(Flag, "ipv6", translate("Enable IPv6"))
o.default = "0"

s = m:section(TypedSection, "socks-clash", translate("Dashboard Settings"))
s.anonymous = true
s.addremove = false

-- External Controller Port
o = s:option(Value, "cn_port", translate("Dashboard Port"))
o.datatype = "port"
o.default = "9090"
o.description = translate("External controller port for dashboard access")

-- Dashboard Password
o = s:option(Value, "dashboard_password", translate("Dashboard Password"))
o.password = true
o.placeholder = translate("Leave empty for no authentication")

return m
