#!/bin/bash
# SocksClash Core Download Script

CORE_DIR="/etc/socks-clash/core"
CORE_PATH="$CORE_DIR/clash"
TMP_DIR="/tmp/socks-clash"
LOG_FILE="/tmp/socks-clash.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
}

get_arch() {
    local arch=$(uname -m)
    case "$arch" in
        x86_64|amd64)
            echo "amd64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        armv7l|armhf)
            echo "armv7"
            ;;
        armv6l)
            echo "armv6"
            ;;
        i686|i386)
            echo "386"
            ;;
        mips)
            echo "mips-softfloat"
            ;;
        mipsel)
            echo "mipsle-softfloat"
            ;;
        mips64)
            echo "mips64"
            ;;
        mips64el)
            echo "mips64le"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

download_core() {
    local arch=$(get_arch)
    
    if [ "$arch" = "unknown" ]; then
        log "Error: Unsupported architecture: $(uname -m)"
        return 1
    fi
    
    log "Downloading Clash Meta core for $arch..."
    
    mkdir -p "$CORE_DIR"
    mkdir -p "$TMP_DIR"
    
    # Clash Meta (mihomo) download
    local version="v1.18.10"
    local filename="mihomo-linux-$arch-$version.gz"
    local url="https://github.com/MetaCubeX/mihomo/releases/download/$version/$filename"
    
    # Try GitHub release
    log "Downloading from: $url"
    
    if curl -sL --connect-timeout 30 --max-time 300 -o "$TMP_DIR/$filename" "$url"; then
        log "Download completed, extracting..."
        
        if gunzip -c "$TMP_DIR/$filename" > "$CORE_PATH"; then
            chmod +x "$CORE_PATH"
            rm -f "$TMP_DIR/$filename"
            
            # Verify
            if "$CORE_PATH" -v >/dev/null 2>&1; then
                local version=$("$CORE_PATH" -v 2>/dev/null | awk '{print $2}' | head -1)
                log "Clash Meta core installed successfully: $version"
                return 0
            else
                log "Error: Core verification failed"
                rm -f "$CORE_PATH"
                return 1
            fi
        else
            log "Error: Failed to extract core"
            return 1
        fi
    else
        log "Error: Download failed"
        return 1
    fi
}

# Check if core exists
if [ -x "$CORE_PATH" ]; then
    version=$("$CORE_PATH" -v 2>/dev/null | awk '{print $2}' | head -1)
    log "Clash core already exists: $version"
    
    # Ask for update
    if [ "$1" = "force" ]; then
        log "Force update requested"
        download_core
    fi
else
    download_core
fi
