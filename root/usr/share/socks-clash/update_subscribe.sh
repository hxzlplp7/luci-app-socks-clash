#!/bin/sh
# SocksClash 订阅更新脚本

LOG_FILE="/tmp/socks-clash.log"
CONFIG_DIR="/etc/socks-clash/config"
UCI_CONFIG="socks-clash"

log_plain() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
}

log_step() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') 第$1步: $2" >> "$LOG_FILE"
}

log_hint() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') 提示：$1" >> "$LOG_FILE"
}

log_warn() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') 警告：$1" >> "$LOG_FILE"
}

log_error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') 错误：$1" >> "$LOG_FILE"
}

update_subscription() {
    local name="$1"
    local url="$2"
    local ua="$3"
    
    [ -z "$url" ] && return 1
    
    log_hint "正在处理订阅【$name】..."
    
    local ua_string="Clash"
    case "$ua" in
        ClashMeta)
            ua_string="clash.meta"
            ;;
        ClashForAndroid)
            ua_string="ClashForAndroid/2.5.12"
            ;;
        V2RayN)
            ua_string="v2rayN"
            ;;
        Shadowrocket)
            ua_string="Shadowrocket/1.0"
            ;;
        Quantumult)
            ua_string="Quantumult/1.0"
            ;;
        Surge)
            ua_string="Surge/4"
            ;;
    esac
    
    local output_file="$CONFIG_DIR/${name}.yaml"
    local tmp_file="/tmp/socks-clash_sub_${name}.tmp"
    
    # 下载订阅
    log_hint "开始下载，UA: $ua_string"
    log_plain "下载地址: $url"
    
    if curl -sL -m 60 --retry 3 \
        -H "User-Agent: $ua_string" \
        -o "$tmp_file" \
        "$url"; then
        
        # 检查文件是否下载成功
        if [ ! -s "$tmp_file" ]; then
            log_error "下载文件为空"
            rm -f "$tmp_file"
            return 1
        fi
        
        log_hint "下载完成，正在验证配置格式..."
        
        # 验证 YAML 格式
        if head -5 "$tmp_file" | grep -qE "(port:|mixed-port:|proxies:|proxy-groups:|rules:|\{)"; then
            mv "$tmp_file" "$output_file"
            log_hint "订阅【$name】更新成功"
            return 0
        else
            # 尝试 base64 解码
            log_hint "尝试 Base64 解码..."
            if base64 -d "$tmp_file" > "${tmp_file}.decoded" 2>/dev/null; then
                if head -5 "${tmp_file}.decoded" | grep -qE "(port:|mixed-port:|proxies:|proxy-groups:|rules:)"; then
                    mv "${tmp_file}.decoded" "$output_file"
                    log_hint "订阅【$name】解码并更新成功"
                    rm -f "$tmp_file"
                    return 0
                fi
            fi
            log_error "订阅内容格式无效，请确认订阅链接是否正确"
            rm -f "$tmp_file" "${tmp_file}.decoded"
            return 1
        fi
    else
        log_error "下载失败，请检查网络连接"
        rm -f "$tmp_file"
        return 1
    fi
}

# 主程序
mkdir -p "$CONFIG_DIR"

log_plain "========================================="
log_plain "SocksClash 订阅更新程序启动"

# 调试: 显示所有 UCI 配置
log_step "一" "读取订阅配置..."
. /lib/functions.sh

count=0
success=0

handle_subscribe() {
    local section="$1"
    local enabled name address sub_ua
    
    config_get_bool enabled "$section" enabled 1  # 默认为 1，尝试强制处理
    config_get name "$section" name ""
    config_get address "$section" address ""
    config_get sub_ua "$section" sub_ua "ClashMeta"
    
    # 强制修正 enabled 逻辑，如果配置里真的是 0，那 uci get bool 应该返回 0
    # 但我们这里再确认一下 uci原始值
    local raw_enabled=$(uci -q get "$UCI_CONFIG.$section.enabled")
    if [ "$raw_enabled" = "0" ]; then
        config_get_bool enabled "$section" enabled 0
    else
        # 如果没有值 或者 值为1，都认为是启用
        enabled=1
    fi
    
    # log_plain "检测: $name (状态: $enabled)"
    
    if [ "$enabled" = "1" ] && [ -n "$name" ] && [ -n "$address" ]; then
        log_step "二" "开始更新订阅: $name"
        if update_subscription "$name" "$address" "$sub_ua"; then
            success=$((success + 1))
        fi
        count=$((count + 1))
    elif [ "$enabled" = "0" ] && [ -n "$name" ]; then
       log_plain "跳过已禁用订阅: $name"
    fi
}

config_load "$UCI_CONFIG"
config_foreach handle_subscribe config_subscribe

if [ "$count" = "0" ]; then
    log_warn "未找到已启用的订阅"
    log_hint "请前往「订阅」页面添加并启用订阅链接"
else
    log_step "三" "更新汇总: 成功 $success / 总计 $count"
fi

# 如果更新成功，重启服务
if [ "$success" -gt 0 ]; then
    # 检查主开关，如果没开，提示一下
    main_enable=$(uci -q get socks-clash.config.enable)
    if [ "$main_enable" = "0" ]; then
         log_warn "SocksClash 主服务未启用，订阅已更新但服务不会自动启动"
         log_hint "请前往「设置」页面启用 SocksClash，或在「概览」页面点击启动"
    else
        log_step "四" "重启 SocksClash 服务以应用新配置..."
        if /etc/init.d/socks-clash restart >/dev/null 2>&1; then
             log_hint "SocksClash 重启成功"
        else
             log_error "SocksClash 重启失败"
        fi
    fi
fi

log_plain "操作完成"
log_plain "========================================="
