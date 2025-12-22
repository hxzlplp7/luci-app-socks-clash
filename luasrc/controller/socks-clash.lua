module("luci.controller.socks-clash", package.seeall)

local fs = require "nixio.fs"
local json = require "luci.jsonc"
local uci = require("luci.model.uci").cursor()
local sys = require "luci.sys"
local http = require "luci.http"

function index()
    local page

    -- Main entry
    page = entry({"admin", "services", "socks-clash"}, alias("admin", "services", "socks-clash", "overview"), "SocksClash", 50)
    page.dependent = true
    page.acl_depends = { "luci-app-socks-clash" }

    -- Overview page
    entry({"admin", "services", "socks-clash", "overview"}, template("socks-clash/overview"), "概览", 10).leaf = true
    
    -- Dashboard page
    entry({"admin", "services", "socks-clash", "dashboard"}, template("socks-clash/dashboard"), "控制面板", 15).leaf = true
    
    -- Settings page
    entry({"admin", "services", "socks-clash", "settings"}, cbi("socks-clash/settings"), "设置", 20).leaf = true
    
    -- Proxy Settings
    entry({"admin", "services", "socks-clash", "proxy"}, cbi("socks-clash/proxy"), "代理配置", 30).leaf = true
    
    -- Servers page (Clash 不支持通过界面添加单个节点，只能用订阅或配置文件)
    -- entry({"admin", "services", "socks-clash", "servers"}, cbi("socks-clash/servers"), "服务器", 40).leaf = true
    
    -- Rules page
    entry({"admin", "services", "socks-clash", "rules"}, cbi("socks-clash/rules"), "规则", 50).leaf = true
    
    -- Subscribe page
    entry({"admin", "services", "socks-clash", "subscribe"}, cbi("socks-clash/subscribe"), "订阅", 55).leaf = true
    
    -- Log page
    entry({"admin", "services", "socks-clash", "log"}, template("socks-clash/log"), "日志", 60).leaf = true
    
    -- API endpoints
    entry({"admin", "services", "socks-clash", "status"}, call("action_status")).leaf = true
    entry({"admin", "services", "socks-clash", "start"}, call("action_start")).leaf = true
    entry({"admin", "services", "socks-clash", "stop"}, call("action_stop")).leaf = true
    entry({"admin", "services", "socks-clash", "restart"}, call("action_restart")).leaf = true
    entry({"admin", "services", "socks-clash", "get_log"}, call("action_get_log")).leaf = true
    entry({"admin", "services", "socks-clash", "clear_log"}, call("action_clear_log")).leaf = true
    entry({"admin", "services", "socks-clash", "get_connections"}, call("action_get_connections")).leaf = true
    entry({"admin", "services", "socks-clash", "close_connections"}, call("action_close_connections")).leaf = true
    entry({"admin", "services", "socks-clash", "get_traffic"}, call("action_get_traffic")).leaf = true
    entry({"admin", "services", "socks-clash", "download_core"}, call("action_download_core")).leaf = true
    entry({"admin", "services", "socks-clash", "check_core"}, call("action_check_core")).leaf = true
    entry({"admin", "services", "socks-clash", "upload_config"}, call("action_upload_config")).leaf = true
end

-- Helper functions
local function is_running()
    return sys.call("pgrep -f /etc/socks-clash/core/clash >/dev/null") == 0
end

local function get_lan_ip()
    local ip = sys.exec("uci -q get network.lan.ipaddr 2>/dev/null | awk -F'/' '{print $1}' | tr -d '\\n'")
    if not ip or ip == "" then
        ip = sys.exec("ip addr show br-lan 2>/dev/null | grep -w 'inet' | grep -Eo 'inet [0-9.]+' | awk '{print $2}' | head -1 | tr -d '\\n'")
    end
    return ip ~= "" and ip or "0.0.0.0"
end

local function get_cn_port()
    return uci:get("socks-clash", "config", "cn_port") or "9090"
end

-- API Actions
function action_status()
    local running = is_running()
    local lan_ip = get_lan_ip()
    local cn_port = get_cn_port()
    local socks_port = uci:get("socks-clash", "config", "socks_port") or "7891"
    local http_port = uci:get("socks-clash", "config", "http_port") or "7890"
    local mixed_port = uci:get("socks-clash", "config", "mixed_port") or "7893"
    local mode = uci:get("socks-clash", "config", "mode") or "rule"
    
    local data = {
        running = running,
        lan_ip = lan_ip,
        cn_port = cn_port,
        socks_port = socks_port,
        http_port = http_port,
        mixed_port = mixed_port,
        mode = mode
    }
    
    http.prepare_content("application/json")
    http.write_json(data)
end

function action_start()
    sys.call("/etc/init.d/socks-clash start >/dev/null 2>&1")
    http.prepare_content("application/json")
    http.write_json({success = true})
end

function action_stop()
    sys.call("/etc/init.d/socks-clash stop >/dev/null 2>&1")
    http.prepare_content("application/json")
    http.write_json({success = true})
end

function action_restart()
    sys.call("/etc/init.d/socks-clash restart >/dev/null 2>&1")
    http.prepare_content("application/json")
    http.write_json({success = true})
end

function action_get_log()
    local log_file = "/tmp/socks-clash.log"
    local lines = tonumber(http.formvalue("lines")) or 200
    
    local content = ""
    if fs.access(log_file) then
        content = sys.exec("tail -n " .. lines .. " " .. log_file .. " 2>/dev/null") or ""
    end
    
    http.prepare_content("application/json")
    http.write_json({log = content})
end

function action_clear_log()
    sys.call("echo '' > /tmp/socks-clash.log 2>/dev/null")
    http.prepare_content("application/json")
    http.write_json({success = true})
end

function action_get_connections()
    local cn_port = get_cn_port()
    local result = sys.exec("curl -s http://127.0.0.1:" .. cn_port .. "/connections 2>/dev/null")
    
    http.prepare_content("application/json")
    if result and result ~= "" then
        http.write(result)
    else
        http.write_json({connections = {}})
    end
end

function action_close_connections()
    local cn_port = get_cn_port()
    sys.call("curl -X DELETE http://127.0.0.1:" .. cn_port .. "/connections >/dev/null 2>&1")
    http.prepare_content("application/json")
    http.write_json({success = true})
end

function action_get_traffic()
    local cn_port = get_cn_port()
    local result = sys.exec("curl -s http://127.0.0.1:" .. cn_port .. "/traffic 2>/dev/null")
    
    http.prepare_content("application/json")
    if result and result ~= "" then
        http.write(result)
    else
        http.write_json({up = 0, down = 0})
    end
end

function action_download_core()
    sys.call("/usr/share/socks-clash/download_core.sh >/tmp/socks-clash.log 2>&1 &")
    http.prepare_content("application/json")
    http.write_json({success = true, message = "下载任务已启动"})
end

function action_check_core()
    local core_path = "/etc/socks-clash/core/clash"
    local exists = fs.access(core_path)
    local version = ""
    
    if exists then
        version = sys.exec(core_path .. " -v 2>/dev/null | head -1 | tr -d '\\n'")
    end
    
    http.prepare_content("application/json")
    http.write_json({
        exists = exists,
        version = version
    })
end

function action_upload_config()
    local file = http.formvalue("file")
    if file then
        local config_path = "/etc/socks-clash/config/config.yaml"
        local f = io.open(config_path, "w")
        if f then
            f:write(file)
            f:close()
            http.prepare_content("application/json")
            http.write_json({success = true})
            return
        end
    end
    http.prepare_content("application/json")
    http.write_json({success = false, message = "上传失败"})
end
