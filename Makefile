include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-socks-clash
PKG_VERSION:=1.0.0
PKG_MAINTAINER:=SocksClash <https://github.com/socks-clash>

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=LuCI support for SOCKS/HTTP Proxy with Clash
	PKGARCH:=all
	DEPENDS:=+bash +curl +ca-bundle +kmod-tun
	MAINTAINER:=SocksClash
endef

define Package/$(PKG_NAME)/description
    A simplified LuCI application for SOCKS5/HTTP/Mixed proxy management with Clash core.
    Features:
    - SOCKS5 Proxy
    - HTTP Proxy
    - Mixed Proxy (SOCKS5 + HTTP)
    - Modern Web Interface
    - Proxy Only Mode (No DNS hijacking or transparent proxy)
endef

define Build/Prepare
	$(CP) $(CURDIR)/root $(PKG_BUILD_DIR)
	$(CP) $(CURDIR)/luasrc $(PKG_BUILD_DIR)
	$(foreach po,$(wildcard ${CURDIR}/po/zh-cn/*.po), \
		po2lmo $(po) $(PKG_BUILD_DIR)/$(patsubst %.po,%.lmo,$(notdir $(po)));)
	chmod 0755 $(PKG_BUILD_DIR)/root/etc/init.d/socks-clash
	chmod -R 0755 $(PKG_BUILD_DIR)/root/usr/share/socks-clash/
	mkdir -p $(PKG_BUILD_DIR)/root/etc/socks-clash/config
	mkdir -p $(PKG_BUILD_DIR)/root/etc/socks-clash/core
	exit 0
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/socks-clash
endef

define Package/$(PKG_NAME)/preinst
#!/bin/sh
	if [ -f "/etc/config/socks-clash" ] && [ ! -f "/tmp/socks-clash.bak" ]; then
		cp -f "/etc/config/socks-clash" "/tmp/socks-clash.bak" >/dev/null 2>&1
		cp -rf "/etc/socks-clash" "/tmp/socks-clash" >/dev/null 2>&1
	fi
	exit 0
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
	exit 0
endef

define Package/$(PKG_NAME)/prerm
#!/bin/sh
	uci -q set socks-clash.config.enable=0
	uci -q commit socks-clash
	[ -n "$$(pidof clash)" ] && /etc/init.d/socks-clash stop 2>/dev/null
	exit 0
endef

define Package/$(PKG_NAME)/postrm
#!/bin/sh
	rm -rf /etc/socks-clash >/dev/null 2>&1
	rm -rf /etc/config/socks-clash >/dev/null 2>&1
	rm -rf /tmp/socks-clash*.log >/dev/null 2>&1
	rm -rf /usr/share/socks-clash >/dev/null 2>&1
	rm -rf /tmp/luci-*
	exit 0
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/*.*.lmo $(1)/usr/lib/lua/luci/i18n/ 2>/dev/null || true
	$(CP) $(PKG_BUILD_DIR)/root/* $(1)/
	$(CP) $(PKG_BUILD_DIR)/luasrc/* $(1)/usr/lib/lua/luci/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
