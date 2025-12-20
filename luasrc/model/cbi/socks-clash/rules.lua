local m, s, o

m = Map("socks-clash", translate("Routing Rules"),
    translate("Configure proxy routing rules."))

s = m:section(TypedSection, "rules", translate("Quick Rules"))
s.anonymous = true
s.addremove = false

o = s:option(Flag, "enabled", translate("Enable Rules"))
o.default = "1"

-- Predefined rule sets
s = m:section(TypedSection, "socks-clash", translate("Predefined Rules"))
s.anonymous = true
s.addremove = false

o = s:option(Flag, "geoip_cn_direct", translate("China IPs Direct"))
o.default = "1"
o.description = translate("Route Chinese IPs directly without proxy")

o = s:option(Flag, "private_direct", translate("Private IPs Direct"))
o.default = "1"
o.description = translate("Route private/LAN IPs directly")

o = s:option(ListValue, "final_rule", translate("Final Rule"))
o:value("PROXY", translate("Proxy"))
o:value("DIRECT", translate("Direct"))
o:value("REJECT", translate("Reject"))
o.default = "PROXY"
o.description = translate("Default action for unmatched traffic")

-- Custom Rules
s = m:section(TypedSection, "custom_rule", translate("Custom Rules"))
s.anonymous = true
s.addremove = true
s.sortable = true
s.template = "cbi/tblsection"

o = s:option(ListValue, "type", translate("Type"))
o:value("DOMAIN", "DOMAIN")
o:value("DOMAIN-SUFFIX", "DOMAIN-SUFFIX")
o:value("DOMAIN-KEYWORD", "DOMAIN-KEYWORD")
o:value("IP-CIDR", "IP-CIDR")
o:value("IP-CIDR6", "IP-CIDR6")
o:value("GEOIP", "GEOIP")
o:value("PROCESS-NAME", "PROCESS-NAME")
o.default = "DOMAIN-SUFFIX"

o = s:option(Value, "value", translate("Value"))
o.rmempty = false
o.placeholder = translate("e.g., google.com, CN, 192.168.0.0/16")

o = s:option(ListValue, "action", translate("Action"))
o:value("PROXY", translate("Proxy"))
o:value("DIRECT", translate("Direct"))
o:value("REJECT", translate("Reject"))
o.default = "PROXY"

o = s:option(Flag, "enabled", translate("Enable"))
o.default = "1"

return m
