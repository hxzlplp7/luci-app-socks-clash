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
    if curl -sL -m 60 --retry 3 \
        -H "User-Agent: $ua_string" \
        -o "$tmp_file" \
        "$url"; then
        
        log "下载完成，正在验证配置格式..."
        
        # 验证 YAML 格式
        if head -1 "$tmp_file" | grep -qE "^(port:|mixed-port:|proxies:|\{)"; then
            mv "$tmp_file" "$output_file"
            log_success "订阅更新成功: $name"
            return 0
        else
            # 尝试 base64 解码
            log "尝试 Base64 解码..."
            if base64 -d "$tmp_file" > "${tmp_file}.decoded" 2>/dev/null; then
                if head -1 "${tmp_file}.decoded" | grep -qE "^(port:|mixed-port:|proxies:)"; then
                    mv "${tmp_file}.decoded" "$output_file"
                    log_success "订阅解码并更新成功: $name"
                    rm -f "$tmp_file"
                    return 0
                fi
            fi
            log_error "订阅内容格式无效: $name"
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

# 从 UCI 读取订阅配置
count=0
uci -q show $UCI_CONFIG | grep "config_subscribe" | grep "\.name=" | while read -r line; do
    section=$(echo "$line" | cut -d'.' -f2)
    enabled=$(uci -q get "$UCI_CONFIG.$section.enabled")
    
    if [ "$enabled" = "1" ]; then
        name=$(uci -q get "$UCI_CONFIG.$section.name")
        address=$(uci -q get "$UCI_CONFIG.$section.address")
        sub_ua=$(uci -q get "$UCI_CONFIG.$section.sub_ua" || echo "ClashMeta")
        
        log "处理订阅 [$name]..."
        update_subscription "$name" "$address" "$sub_ua"
        count=$((count + 1))
    fi
done

if [ "$count" = "0" ]; then
    log "未找到已启用的订阅"
fi

log "========================================="
log "订阅更新完成"
log "========================================="

# 如果服务正在运行，则重启服务
if pgrep -f "/etc/socks-clash/core/clash" >/dev/null 2>&1; then
    log "正在重启 SocksClash 服务以应用新配置..."
    /etc/init.d/socks-clash restart
    log_success "服务已重启"
fi
