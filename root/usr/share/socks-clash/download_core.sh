#!/bin/sh
# SocksClash 内核下载脚本

CORE_DIR="/etc/socks-clash/core"
CORE_PATH="$CORE_DIR/clash"
TMP_DIR="/tmp/socks-clash"
LOG_FILE="/tmp/socks-clash.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [信息] $1" >> "$LOG_FILE"
}

log_error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [错误] $1" >> "$LOG_FILE"
}

log_success() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [成功] $1" >> "$LOG_FILE"
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

download_with_progress() {
    local url="$1"
    local output="$2"
    local desc="$3"
    
    log "开始下载: $desc"
    log "下载地址: $url"
    
    # 先获取文件大小
    local total_size=$(curl -sI "$url" 2>/dev/null | grep -i content-length | awk '{print $2}' | tr -d '\r')
    
    if [ -n "$total_size" ] && [ "$total_size" -gt 0 ] 2>/dev/null; then
        local size_mb=$(echo "scale=2; $total_size / 1048576" | bc 2>/dev/null || echo "未知")
        log "文件大小: ${size_mb} MB"
    fi
    
    # 使用 curl 下载，显示进度
    log "正在下载，请稍候..."
    
    if curl -L --connect-timeout 30 --max-time 600 \
        --progress-bar \
        -o "$output" "$url" 2>&1 | while read line; do
            # 解析进度信息并记录
            if echo "$line" | grep -q '%'; then
                percent=$(echo "$line" | grep -oE '[0-9]+%' | tail -1)
                if [ -n "$percent" ]; then
                    log "下载进度: $percent"
                fi
            fi
        done; then
        log_success "下载完成"
        return 0
    else
        log_error "下载失败"
        return 1
    fi
}

download_core() {
    local arch=$(get_arch)
    
    if [ "$arch" = "unknown" ]; then
        log_error "不支持的系统架构: $(uname -m)"
        return 1
    fi
    
    log "========================================="
    log "开始下载 Clash Meta (mihomo) 内核"
    log "系统架构: $arch"
    log "========================================="
    
    mkdir -p "$CORE_DIR"
    mkdir -p "$TMP_DIR"
    
    # Clash Meta (mihomo) 版本
    local version="v1.18.10"
    local filename="mihomo-linux-$arch-$version.gz"
    local url="https://github.com/MetaCubeX/mihomo/releases/download/$version/$filename"
    
    log "目标版本: $version"
    
    # 下载文件
    if curl -L --connect-timeout 30 --max-time 600 -o "$TMP_DIR/$filename" "$url" 2>&1; then
        log_success "文件下载完成"
        
        log "正在解压文件..."
        if gunzip -c "$TMP_DIR/$filename" > "$CORE_PATH" 2>&1; then
            chmod +x "$CORE_PATH"
            rm -f "$TMP_DIR/$filename"
            log_success "文件解压完成"
            
            # 验证内核
            log "正在验证内核..."
            if "$CORE_PATH" -v >/dev/null 2>&1; then
                local installed_version=$("$CORE_PATH" -v 2>/dev/null | awk '{print $2}' | head -1)
                log_success "Clash Meta 内核安装成功!"
                log "安装版本: $installed_version"
                log "安装路径: $CORE_PATH"
                log "========================================="
                return 0
            else
                log_error "内核验证失败，可能文件损坏"
                rm -f "$CORE_PATH"
                return 1
            fi
        else
            log_error "解压文件失败"
            rm -f "$TMP_DIR/$filename"
            return 1
        fi
    else
        log_error "下载失败，请检查网络连接"
        log "提示: 如果无法访问 GitHub，可以尝试手动下载内核"
        return 1
    fi
}

# 主程序
log "========================================="
log "SocksClash 内核管理"
log "========================================="

# 检查现有内核
if [ -x "$CORE_PATH" ]; then
    current_version=$("$CORE_PATH" -v 2>/dev/null | awk '{print $2}' | head -1)
    log "检测到已安装内核: $current_version"
    
    if [ "$1" = "force" ]; then
        log "强制更新模式"
        download_core
    else
        log "如需更新，请使用强制更新选项"
    fi
else
    log "未检测到内核，开始安装..."
    download_core
fi

log "========================================="
log "操作完成"
log "========================================="
