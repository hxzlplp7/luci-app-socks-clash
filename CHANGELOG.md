# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-12-20

### Added
- Initial release of SocksClash
- **Proxy Features:**
  - SOCKS5 proxy support (default port: 7891)
  - HTTP proxy support (default port: 7890)
  - Mixed proxy support (default port: 7893, supports both SOCKS5 and HTTP)
- **Modern Web Dashboard:**
  - Real-time service status monitoring
  - Traffic statistics (upload/download)
  - Connection count display
  - One-click copy proxy addresses
  - Mode switching (Rule/Global/Direct)
- **Configuration:**
  - Visual server management interface
  - Support for multiple proxy protocols:
    - Shadowsocks
    - VMess / VLESS
    - Trojan
    - Hysteria / Hysteria2
    - TUIC
  - Custom routing rules
  - Subscription management with auto-update
- **Other Features:**
  - Chinese language support (中文支持)
  - Detailed logging with filtering
  - Automatic core download script
  - UCI configuration support
  
### Notes
- This is a **proxy-only** application - no DNS hijacking or transparent proxy
- Designed as a simplified alternative to OpenClash
- Lower resource usage compared to full-featured solutions
