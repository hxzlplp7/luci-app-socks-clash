#!/bin/bash
# SocksClash 订阅更新脚本

START_LOG="/tmp/socks-clash_start.log"
LOG_FILE="/tmp/socks-clash.log"
CONFIG_DIR="/etc/socks-clash/config"
UCI_CONFIG="socks-clash"

# 日志函数 - 完全模仿 OpenClash log.sh
LOG_OUT() {
    if [ -n "${1}" ]; then
        echo -e "${1}" > "$START_LOG"
        echo -e "$(date "+%Y-%m-%d %H:%M:%S") ${1}" >> "$LOG_FILE"
    fi
}

SLOG_CLEAN() {
    echo "##FINISH##" > "$START_LOG"
}

# 锁机制
set_lock() {
    exec 878>"/tmp/lock/socks_clash_update.lock" 2>/dev/null
    flock -x 878 2>/dev/null
}

del_lock() {
    flock -u 878 2>/dev/null
    rm -rf "/tmp/lock/socks_clash_update.lock" 2>/dev/null
}

# 确保清理锁
trap 'del_lock' EXIT

update_subscription() {
    local name="$1"
    local url="$2"
    local ua="$3"
    
    [ -z "$url" ] && return 1
    
    local ua_string="Clash"
    case "$ua" in
        ClashMeta) ua_string="clash.meta" ;;
        ClashForAndroid) ua_string="ClashForAndroid/2.5.12" ;;
        V2RayN) ua_string="v2rayN" ;;
        Shadowrocket) ua_string="Shadowrocket/1.0" ;;
        Quantumult) ua_string="Quantumult/1.0" ;;
        Surge) ua_string="Surge/4" ;;
    esac
    
    local output_file="$CONFIG_DIR/${name}.yaml"
    local tmp_file="/tmp/socks-clash_sub_${name}.tmp"
    
    local retry_count=0
    local max_retries=3
    local download_success=false

    while [ $retry_count -lt $max_retries ]; do
        retry_count=$((retry_count + 1))
        
        LOG_OUT "Tip:【$retry_count/$max_retries】正在下载订阅【$name】..."
        LOG_OUT "Tip: 订阅地址: $url"
        
        if curl -sL -m 30 --retry 2 \
            -H "User-Agent: $ua_string" \
            -o "$tmp_file" \
            "$url"; then
            
            if [ -s "$tmp_file" ]; then
                download_success=true
                break
            else
                LOG_OUT "Error: 下载的文件为空..."
            fi
        else
            LOG_OUT "Error:【$retry_count/$max_retries】下载失败, 正在重试..."
        fi
        
        if [ $retry_count -lt $max_retries ]; then
            sleep 2
        fi
    done

    if [ "$download_success" = "true" ]; then
        LOG_OUT "Tip: 下载成功，正在验证配置..."
        
        # 验证/解码
        if head -5 "$tmp_file" | grep -qE "(port:|mixed-port:|proxies:|proxy-groups:|rules:|\{)"; then
            mv "$tmp_file" "$output_file"
            LOG_OUT "Tip: 订阅【$name】更新成功"
            return 0
        else
            LOG_OUT "Tip: 尝试 Base64 解码..."
            if base64 -d "$tmp_file" > "${tmp_file}.decoded" 2>/dev/null; then
                 if head -5 "${tmp_file}.decoded" | grep -qE "^(port:|mixed-port:|proxies:|proxy-groups:|rules:)"; then
                    mv "${tmp_file}.decoded" "$output_file"
                    LOG_OUT "Tip: 订阅【$name】解码并更新成功"
                    rm -f "$tmp_file"
                    return 0
                 fi
            fi
            LOG_OUT "Error: 订阅【$name】配置格式无效"
            rm -f "$tmp_file" "${tmp_file}.decoded"
            return 1
        fi
    else
        LOG_OUT "Error: 订阅【$name】下载失败，已重试 $max_retries 次"
        rm -f "$tmp_file"
        return 1
    fi
}

# 主程序
set_lock
mkdir -p "$CONFIG_DIR"
mkdir -p "/tmp/lock"

LOG_OUT "========================================="
LOG_OUT "Tip: 开始更新订阅"

# 读取配置逻辑
. /lib/functions.sh

count=0
success=0

handle_subscribe() {
    local section="$1"
    local enabled name address sub_ua
    
    config_get_bool enabled "$section" enabled 1
    config_get name "$section" name ""
    config_get address "$section" address ""
    config_get sub_ua "$section" sub_ua "ClashMeta"
    
    # 容错处理: 再次确认为 0 才是真的禁用
    local raw_enabled=$(uci -q get "$UCI_CONFIG.$section.enabled")
    if [ "$raw_enabled" = "0" ]; then
        enabled=0
    else
        enabled=1
    fi
    
    if [ "$enabled" = "1" ] && [ -n "$name" ] && [ -n "$address" ]; then
        if update_subscription "$name" "$address" "$sub_ua"; then
            success=$((success + 1))
        fi
        count=$((count + 1))
    elif [ "$enabled" = "0" ] && [ -n "$name" ]; then
        LOG_OUT "Tip: 跳过已禁用的订阅: $name"
    fi
}

config_load "$UCI_CONFIG"
config_foreach handle_subscribe config_subscribe

if [ "$count" = "0" ]; then
    LOG_OUT "Error: 未找到已启用的订阅"
    LOG_OUT "Tip: 请在订阅页面添加并启用订阅"
else
    LOG_OUT "Tip: 更新统计: 成功 $success / 共 $count"
fi

if [ "$success" -gt 0 ]; then
    main_enable=$(uci -q get socks-clash.config.enable)
    if [ "$main_enable" = "0" ]; then
         LOG_OUT "Tip: 主服务已禁用，不自动重启..."
    else
        LOG_OUT "Tip: 正在重启 SocksClash 服务..."
        if /etc/init.d/socks-clash restart >/dev/null 2>&1; then
             LOG_OUT "Tip: SocksClash 重启成功"
        else
             LOG_OUT "Error: SocksClash 重启失败"
        fi
    fi
fi

LOG_OUT "Tip: 订阅更新完成"
LOG_OUT "========================================="
SLOG_CLEAN

# 确保清理锁
del_lock
