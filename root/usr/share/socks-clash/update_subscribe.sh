#!/bin/sh
# SocksClash 订阅更新脚本

LOG_FILE="/tmp/socks-clash.log"
CONFIG_DIR="/etc/socks-clash/config"
UCI_CONFIG="socks-clash"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [信息] $1" >> "$LOG_FILE"
}

log_error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [错误] $1" >> "$LOG_FILE"
}

log_success() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [成功] $1" >> "$LOG_FILE"
}

update_subscription() {
    local name="$1"
    local url="$2"
    local ua="$3"
    
    [ -z "$url" ] && return 1
    
    log "正在更新订阅: $name"
    
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
    log "正在下载订阅配置..."
    log "订阅地址: $url"
    
    if curl -sL -m 60 --retry 3 \
        -H "User-Agent: $ua_string" \
        -o "$tmp_file" \
        "$url"; then
        
        # 检查文件是否下载成功
        if [ ! -s "$tmp_file" ]; then
            log_error "下载的文件为空"
            rm -f "$tmp_file"
            return 1
        fi
        
        log "下载完成，正在验证配置格式..."
        
        # 验证 YAML 格式
        if head -5 "$tmp_file" | grep -qE "(port:|mixed-port:|proxies:|proxy-groups:|rules:|\{)"; then
            mv "$tmp_file" "$output_file"
            log_success "订阅更新成功: $name"
            log "配置已保存到: $output_file"
            return 0
        else
            # 尝试 base64 解码
            log "尝试 Base64 解码..."
            if base64 -d "$tmp_file" > "${tmp_file}.decoded" 2>/dev/null; then
                if head -5 "${tmp_file}.decoded" | grep -qE "(port:|mixed-port:|proxies:|proxy-groups:|rules:)"; then
                    mv "${tmp_file}.decoded" "$output_file"
                    log_success "订阅解码并更新成功: $name"
                    rm -f "$tmp_file"
                    return 0
                fi
            fi
            log_error "订阅内容格式无效: $name"
            log "提示: 请确认订阅地址返回的是 Clash 格式的配置"
            rm -f "$tmp_file" "${tmp_file}.decoded"
            return 1
        fi
    else
        log_error "下载订阅失败: $name"
        log "提示: 请检查网络连接和订阅地址是否正确"
        rm -f "$tmp_file"
        return 1
    fi
}

# 主程序
mkdir -p "$CONFIG_DIR"

log "========================================="
log "开始更新订阅"
log "========================================="

# 调试: 显示所有 UCI 配置
log "读取 UCI 配置..."

# 从 UCI 读取订阅配置 - 使用多种方法尝试
count=0
success=0

# 方法1: 直接遍历所有 section
. /lib/functions.sh

handle_subscribe() {
    local section="$1"
    local enabled name address sub_ua
    
    config_get_bool enabled "$section" enabled 0
    config_get name "$section" name ""
    config_get address "$section" address ""
    config_get sub_ua "$section" sub_ua "ClashMeta"
    
    log "找到订阅配置: section=$section, name=$name, enabled=$enabled"
    
    if [ "$enabled" = "1" ] && [ -n "$name" ] && [ -n "$address" ]; then
        log "处理订阅: $name"
        if update_subscription "$name" "$address" "$sub_ua"; then
            success=$((success + 1))
        fi
        count=$((count + 1))
    fi
}

config_load "$UCI_CONFIG"
config_foreach handle_subscribe config_subscribe

if [ "$count" = "0" ]; then
    log "未找到已启用的订阅"
    log "提示: 请在 LuCI 界面的'订阅'页面添加订阅地址，并点击'保存并应用'"
else
    log "处理完成: $success/$count 个订阅更新成功"
fi

log "========================================="
log "订阅更新完成"
log "========================================="

# 如果服务正在运行且有成功的订阅，则重启服务
if [ "$success" -gt 0 ] && pgrep -f "/etc/socks-clash/core/clash" >/dev/null 2>&1; then
    log "正在重启 SocksClash 服务以应用新配置..."
    /etc/init.d/socks-clash restart
    log_success "服务已重启"
fi
