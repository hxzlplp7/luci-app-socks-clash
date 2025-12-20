module("luci.controller.socks-clash", package.seeall)

local fs = require "nixio.fs"
local json = require "luci.jsonc"
local uci = require("luci.model.uci").cursor()
local sys = require "luci.sys"
local http = require "luci.http"

function index()
    local page

    -- Main entry
    page = entry({"admin", "services", "socks-clash"}, alias("admin", "services", "socks-clash", "overview"), _("SocksClash"), 50)
    page.dependent = true
    page.acl_depends = { "luci-app-socks-clash" }

    -- Overview page
    entry({"admin", "services", "socks-clash", "overview"}, template("socks-clash/overview"), _("Overview"), 10).leaf = true
    
    -- Settings page
    entry({"admin", "services", "socks-clash", "settings"}, cbi("socks-clash/settings"), _("Settings"), 20).leaf = true
    
    -- Proxy Settings
    entry({"admin", "services", "socks-clash", "proxy"}, cbi("socks-clash/proxy"), _("Proxy Settings"), 30).leaf = true
    
    -- Servers page
    entry({"admin", "services", "socks-clash", "servers"}, cbi("socks-clash/servers"), _("Servers"), 40).leaf = true
    
    -- Rules page
    entry({"admin", "services", "socks-clash", "rules"}, cbi("socks-clash/rules"), _("Rules"), 50).leaf = true
    
    -- Subscribe page
    entry({"admin", "services", "socks-clash", "subscribe"}, cbi("socks-clash/subscribe"), _("Subscribe"), 55).leaf = true
    
    -- Log page
    entry({"admin", "services", "socks-clash", "log"}, template("socks-clash/log"), _("Logs"), 60).leaf = true
    
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
    return sys.call("pidof clash >/dev/null") == 0
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

local function get_secret()
    return uci:get("socks-clash", "config", "dashboard_password") or ""
end

local function get_core_version()
    local core_path = uci:get("socks-clash", "config", "core_path") or "/etc/socks-clash/core/clash"
    if fs.access(core_path) then
        local version = sys.exec(core_path .. " -v 2>/dev/null | awk '{print $2}' | head -1 | tr -d '\\n'")
        return version ~= "" and version or "Unknown"
    end
    return "Not installed"
end

local function api_request(path, method, data)
    local ip = get_lan_ip()
    local port = get_cn_port()
    local secret = get_secret()
    
    local auth_header = ""
    if secret and secret ~= "" then
        auth_header = string.format('-H "Authorization: Bearer %s"', secret)
    end
    
    local cmd
    if method == "GET" then
        cmd = string.format('curl -sL -m 3 %s "http://%s:%s%s"', auth_header, ip, port, path)
    elseif method == "POST" then
        cmd = string.format('curl -sL -m 3 -X POST %s -H "Content-Type: application/json" -d \'%s\' "http://%s:%s%s"', 
            auth_header, data or "{}", ip, port, path)
    elseif method == "DELETE" then
        cmd = string.format('curl -sL -m 3 -X DELETE %s "http://%s:%s%s"', auth_header, ip, port, path)
    end
    
    return sys.exec(cmd)
end

-- API handlers
function action_status()
    local running = is_running()
    local enabled = uci:get("socks-clash", "config", "enable") == "1"
    local socks_port = uci:get("socks-clash", "config", "socks_port") or "7891"
    local http_port = uci:get("socks-clash", "config", "http_port") or "7890"
    local mixed_port = uci:get("socks-clash", "config", "mixed_port") or "7893"
    local cn_port = get_cn_port()
    local lan_ip = get_lan_ip()
    local core_version = get_core_version()
    
    local traffic = {}
    local mode = "unknown"
    
    if running then
        local traffic_data = api_request("/traffic", "GET")
        if traffic_data and traffic_data ~= "" then
            local t = json.parse(traffic_data)
            if t then
                traffic = t
            end
        end
        
        local config_data = api_request("/configs", "GET")
        if config_data and config_data ~= "" then
            local c = json.parse(config_data)
            if c and c.mode then
                mode = c.mode
            end
        end
    end
    
    http.prepare_content("application/json")
    http.write_json({
        running = running,
        enabled = enabled,
        socks_port = socks_port,
        http_port = http_port,
        mixed_port = mixed_port,
        cn_port = cn_port,
        lan_ip = lan_ip,
        core_version = core_version,
        mode = mode,
        traffic = traffic,
        uptime = running and sys.exec("ps -o etime= -p $(pidof clash) 2>/dev/null | tr -d ' \\n'") or ""
    })
end

function action_start()
    uci:set("socks-clash", "config", "enable", "1")
    uci:commit("socks-clash")
    sys.call("/etc/init.d/socks-clash start >/dev/null 2>&1 &")
    
    http.prepare_content("application/json")
    http.write_json({status = "success", message = "Starting SocksClash..."})
end

function action_stop()
    uci:set("socks-clash", "config", "enable", "0")
    uci:commit("socks-clash")
    sys.call("/etc/init.d/socks-clash stop >/dev/null 2>&1")
    
    http.prepare_content("application/json")
    http.write_json({status = "success", message = "SocksClash stopped"})
end

function action_restart()
    sys.call("/etc/init.d/socks-clash restart >/dev/null 2>&1 &")
    
    http.prepare_content("application/json")
    http.write_json({status = "success", message = "Restarting SocksClash..."})
end

function action_get_log()
    local log = ""
    local log_path = "/tmp/socks-clash.log"
    
    if fs.access(log_path) then
        log = sys.exec("tail -n 100 " .. log_path .. " 2>/dev/null")
    end
    
    http.prepare_content("application/json")
    http.write_json({log = log})
end

function action_clear_log()
    sys.call("echo '' > /tmp/socks-clash.log 2>/dev/null")
    
    http.prepare_content("application/json")
    http.write_json({status = "success"})
end

function action_get_connections()
    local data = {}
    
    if is_running() then
        local result = api_request("/connections", "GET")
        if result and result ~= "" then
            local parsed = json.parse(result)
            if parsed then
                data = parsed
            end
        end
    end
    
    http.prepare_content("application/json")
    http.write_json(data)
end

function action_close_connections()
    if is_running() then
        api_request("/connections", "DELETE")
    end
    
    http.prepare_content("application/json")
    http.write_json({status = "success"})
end

function action_get_traffic()
    local data = {up = 0, down = 0}
    
    if is_running() then
        local result = api_request("/traffic", "GET")
        if result and result ~= "" then
            local parsed = json.parse(result)
            if parsed then
                data = parsed
            end
        end
    end
    
    http.prepare_content("application/json")
    http.write_json(data)
end

function action_check_core()
    local core_path = uci:get("socks-clash", "config", "core_path") or "/etc/socks-clash/core/clash"
    local exists = fs.access(core_path)
    local version = "Not installed"
    
    if exists then
        version = sys.exec(core_path .. " -v 2>/dev/null | awk '{print $2}' | head -1 | tr -d '\\n'")
        if version == "" then
            version = "Unknown"
        end
    end
    
    http.prepare_content("application/json")
    http.write_json({
        exists = exists,
        version = version,
        path = core_path
    })
end

function action_download_core()
    local arch = sys.exec("uname -m | tr -d '\\n'")
    
    http.prepare_content("application/json")
    
    -- Download core in background
    sys.call("/usr/share/socks-clash/download_core.sh >/dev/null 2>&1 &")
    
    http.write_json({
        status = "success",
        message = "Core download started",
        arch = arch
    })
end

function action_upload_config()
    local file = http.formvalue("config_file")
    
    if not file then
        http.prepare_content("application/json")
        http.write_json({status = "error", message = "No file provided"})
        return
    end
    
    local config_dir = "/etc/socks-clash/config"
    sys.call("mkdir -p " .. config_dir)
    
    local filename = http.formvalue("filename") or "uploaded_config.yaml"
    local filepath = config_dir .. "/" .. filename
    
    local f = io.open(filepath, "w")
    if f then
        f:write(file)
        f:close()
        
        http.prepare_content("application/json")
        http.write_json({status = "success", message = "Config uploaded", path = filepath})
    else
        http.prepare_content("application/json")
        http.write_json({status = "error", message = "Failed to save config"})
    end
end
