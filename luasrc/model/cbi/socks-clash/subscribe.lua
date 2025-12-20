local m, s, o

m = Map("socks-clash", "配置订阅",
    "管理配置订阅。您可以从代理服务商添加订阅链接。")

-- Subscription List
s = m:section(TypedSection, "config_subscribe", "订阅列表")
s.anonymous = true
s.addremove = true
s.sortable = true
s.template = "cbi/tblsection"

o = s:option(Value, "name", "名称")
o.rmempty = false
o.placeholder = "订阅名称"

o = s:option(Value, "address", "订阅地址")
o.rmempty = false
o.placeholder = "https://example.com/subscribe"

o = s:option(Flag, "enabled", "启用")
o.default = "1"

o = s:option(ListValue, "sub_ua", "用户代理")
o:value("Clash", "Clash")
o:value("ClashMeta", "Clash.Meta")
o:value("ClashForAndroid", "ClashForAndroid")
o:value("V2RayN", "V2RayN")
o:value("Shadowrocket", "Shadowrocket")
o:value("Quantumult", "Quantumult")
o:value("Surge", "Surge")
o.default = "ClashMeta"

o = s:option(ListValue, "update_interval", "更新间隔")
o:value("0", "手动")
o:value("1", "1 小时")
o:value("6", "6 小时")
o:value("12", "12 小时")
o:value("24", "24 小时")
o:value("168", "7 天")
o.default = "24"

-- Manual Update Section
s = m:section(TypedSection, "socks-clash", "手动更新")
s.anonymous = true
s.addremove = false

o = s:option(Button, "update_now", "立即更新")
o.inputtitle = "更新所有订阅"
o.inputstyle = "apply"
o.write = function()
    luci.sys.call("/usr/share/socks-clash/update_subscribe.sh >/dev/null 2>&1 &")
end

return m
