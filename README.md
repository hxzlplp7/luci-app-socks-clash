# SocksClash

<p align="center">
  <img src="logo.png" width="120" alt="SocksClash Logo">
</p>

<p align="center">
  <strong>🚀 OpenWrt 代理管理插件 - 简洁、美观、易用</strong>
</p>

<p align="center">
  <a href="#功能特点">功能特点</a> •
  <a href="#安装说明">安装说明</a> •
  <a href="#使用方法">使用方法</a> •
  <a href="#截图预览">截图预览</a>
</p>

---

## 📖 简介

**SocksClash** 是一个基于 Clash 内核的 OpenWrt LuCI 代理管理插件。与 OpenClash 不同，SocksClash 专注于提供**纯代理服务**，不进行 DNS 劫持或透明代理，让您完全掌控哪些设备/应用使用代理。

## ✨ 功能特点

### 🔌 代理模式
- **SOCKS5 代理** - 支持标准 SOCKS5 协议
- **HTTP 代理** - 支持 HTTP/HTTPS 代理
- **混合代理** - 单端口同时支持 SOCKS5 和 HTTP

### 🎨 现代化界面
- 精美的仪表盘设计
- 实时流量监控
- 连接状态显示
- 一键切换代理模式

### ⚙️ 灵活配置
- 可视化服务器管理
- 自定义路由规则
- 多种代理协议支持
  - Shadowsocks
  - VMess / VLESS
  - Trojan
  - Hysteria / Hysteria2
  - TUIC

### 📊 监控功能
- 实时流量统计
- 连接数监控
- 详细日志记录

## 📦 安装说明

### 方式一：手动编译

1. 克隆仓库到 OpenWrt 源码的 `package` 目录：

```bash
cd /path/to/openwrt
git clone https://github.com/your-repo/luci-app-socks-clash.git package/luci-app-socks-clash
```

2. 更新 feeds 并选择包：

```bash
./scripts/feeds update -a
./scripts/feeds install -a
make menuconfig
# 选择 LuCI -> Applications -> luci-app-socks-clash
```

3. 编译：

```bash
make package/luci-app-socks-clash/compile V=s
```

### 方式二：IPK 安装

从 [Releases](../../releases) 页面下载最新的 IPK 文件，然后：

```bash
opkg install luci-app-socks-clash_*.ipk
```

### 下载 Clash 内核

安装后需要下载 Clash 内核：

```bash
/usr/share/socks-clash/download_core.sh
```

或在 LuCI 界面中点击下载按钮。

## 🚀 使用方法

### 1. 配置代理端口

访问 **服务 -> SocksClash -> 代理设置**，配置：

| 代理类型 | 默认端口 | 说明 |
|---------|---------|------|
| SOCKS5 | 7891 | 标准 SOCKS5 代理 |
| HTTP | 7890 | HTTP/HTTPS 代理 |
| Mixed | 7893 | 混合代理（推荐） |

### 2. 设备配置代理

#### Windows
```
设置 → 网络和 Internet → 代理
手动设置代理:
  地址: 192.168.1.1 (路由器IP)
  端口: 7890 (HTTP) 或 7891 (SOCKS5)
```

#### macOS
```
系统偏好设置 → 网络 → 高级 → 代理
Web 代理 (HTTP): 192.168.1.1:7890
SOCKS 代理: 192.168.1.1:7891
```

#### iOS/Android
```
WiFi 设置 → 当前网络 → 配置代理 → 手动
服务器: 192.168.1.1
端口: 7890
```

#### 命令行
```bash
# HTTP 代理
export http_proxy=http://192.168.1.1:7890
export https_proxy=http://192.168.1.1:7890

# SOCKS5 代理
export ALL_PROXY=socks5://192.168.1.1:7891
```

### 3. 浏览器扩展（推荐）

使用 **SwitchyOmega** 或 **FoxyProxy** 等浏览器扩展，可以更灵活地控制代理：

- 自动切换规则
- PAC 脚本支持
- 按域名/IP 分流

## 📸 截图预览

### 概览页面
![Overview](screenshots/overview.png)

### 设置页面
![Settings](screenshots/settings.png)

### 日志页面
![Logs](screenshots/logs.png)

## 🔧 与 OpenClash 的区别

| 特性 | SocksClash | OpenClash |
|-----|------------|-----------|
| 代理模式 | 仅代理（手动配置） | 透明代理/DNS劫持 |
| 配置复杂度 | 简单 | 复杂 |
| 资源占用 | 低 | 较高 |
| 适用场景 | 部分设备代理 | 全局代理 |
| 界面风格 | 现代简洁 | 功能丰富 |

## 📝 配置文件说明

配置文件位置：
- UCI 配置：`/etc/config/socks-clash`
- Clash 配置：`/etc/socks-clash/config/config.yaml`
- 日志文件：`/tmp/socks-clash.log`
- 内核文件：`/etc/socks-clash/core/clash`

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

MIT License

## 🙏 致谢

- [Clash](https://github.com/Dreamacro/clash)
- [Clash Meta](https://github.com/MetaCubeX/mihomo)
- [OpenClash](https://github.com/vernesong/OpenClash)
- [OpenWrt](https://openwrt.org/)
