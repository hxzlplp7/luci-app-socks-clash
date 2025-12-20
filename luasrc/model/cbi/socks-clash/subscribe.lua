local m, s, o

m = Map("socks-clash", translate("Config Subscribe"),
    translate("Manage configuration subscriptions. You can add subscription links from your proxy providers."))

-- Subscription List
s = m:section(TypedSection, "config_subscribe", translate("Subscriptions"))
s.anonymous = true
s.addremove = true
s.sortable = true
s.template = "cbi/tblsection"

o = s:option(Value, "name", translate("Name"))
o.rmempty = false
o.placeholder = translate("Subscription name")

o = s:option(Value, "address", translate("Subscribe URL"))
o.rmempty = false
o.placeholder = "https://example.com/subscribe"

o = s:option(Flag, "enabled", translate("Enable"))
o.default = "1"

o = s:option(ListValue, "sub_ua", translate("User Agent"))
o:value("Clash", "Clash")
o:value("ClashMeta", "Clash.Meta")
o:value("ClashForAndroid", "ClashForAndroid")
o:value("V2RayN", "V2RayN")
o:value("Shadowrocket", "Shadowrocket")
o:value("Quantumult", "Quantumult")
o:value("Surge", "Surge")
o.default = "ClashMeta"

o = s:option(ListValue, "update_interval", translate("Update Interval"))
o:value("0", translate("Manual"))
o:value("1", translate("1 hour"))
o:value("6", translate("6 hours"))
o:value("12", translate("12 hours"))
o:value("24", translate("24 hours"))
o:value("168", translate("7 days"))
o.default = "24"

-- Manual Update Section
s = m:section(TypedSection, "socks-clash", translate("Manual Update"))
s.anonymous = true
s.addremove = false

o = s:option(Button, "update_now", translate("Update Now"))
o.inputtitle = translate("Update All Subscriptions")
o.inputstyle = "apply"
o.write = function()
    luci.sys.call("/usr/share/socks-clash/update_subscribe.sh >/dev/null 2>&1 &")
end

return m
