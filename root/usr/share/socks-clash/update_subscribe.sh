#!/bin/bash
# SocksClash Subscription Update Script

LOG_FILE="/tmp/socks-clash.log"
CONFIG_DIR="/etc/socks-clash/config"
UCI_CONFIG="socks-clash"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [Subscribe] $1" >> "$LOG_FILE"
}

update_subscription() {
    local name="$1"
    local url="$2"
    local ua="$3"
    
    [ -z "$url" ] && return 1
    
    log "Updating subscription: $name"
    
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
    
    # Download subscription
    if curl -sL -m 60 --retry 3 \
        -H "User-Agent: $ua_string" \
        -o "$tmp_file" \
        "$url"; then
        
        # Validate YAML
        if head -1 "$tmp_file" | grep -qE "^(port:|mixed-port:|proxies:|\{)"; then
            mv "$tmp_file" "$output_file"
            log "Subscription updated successfully: $name"
            return 0
        else
            # Maybe base64 encoded, try decode
            if base64 -d "$tmp_file" > "${tmp_file}.decoded" 2>/dev/null; then
                if head -1 "${tmp_file}.decoded" | grep -qE "^(port:|mixed-port:|proxies:)"; then
                    mv "${tmp_file}.decoded" "$output_file"
                    log "Subscription decoded and updated: $name"
                    rm -f "$tmp_file"
                    return 0
                fi
            fi
            log "Invalid subscription content: $name"
            rm -f "$tmp_file" "${tmp_file}.decoded"
            return 1
        fi
    else
        log "Failed to download subscription: $name"
        rm -f "$tmp_file"
        return 1
    fi
}

# Main
mkdir -p "$CONFIG_DIR"

log "Starting subscription update..."

# Read subscriptions from UCI
uci -q show $UCI_CONFIG | grep "config_subscribe" | grep "\.name=" | while read -r line; do
    section=$(echo "$line" | cut -d'.' -f2)
    enabled=$(uci -q get "$UCI_CONFIG.$section.enabled")
    
    if [ "$enabled" = "1" ]; then
        name=$(uci -q get "$UCI_CONFIG.$section.name")
        address=$(uci -q get "$UCI_CONFIG.$section.address")
        sub_ua=$(uci -q get "$UCI_CONFIG.$section.sub_ua" || echo "ClashMeta")
        
        update_subscription "$name" "$address" "$sub_ua"
    fi
done

log "Subscription update completed"

# Restart service if running
if pidof clash >/dev/null 2>&1; then
    log "Restarting SocksClash service..."
    /etc/init.d/socks-clash restart
fi
