include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI support for SOCKS/HTTP Proxy with Clash
LUCI_DESCRIPTION:=A simplified LuCI application for SOCKS5/HTTP/Mixed proxy management with Clash core
LUCI_DEPENDS:=+bash +curl +ca-bundle
LUCI_PKGARCH:=all

PKG_NAME:=luci-app-socks-clash
PKG_VERSION:=1.0.0
PKG_RELEASE:=1
PKG_MAINTAINER:=SocksClash <https://github.com/socks-clash>

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=$(LUCI_TITLE)
	PKGARCH:=all
	DEPENDS:=+luci-base +bash +curl +ca-bundle
	MAINTAINER:=SocksClash
endef

define Package/$(PKG_NAME)/description
$(LUCI_DESCRIPTION)
Features:
- SOCKS5 Proxy (port 7891)
- HTTP Proxy (port 7890)
- Mixed Proxy (port 7893 - SOCKS5 + HTTP)
- Modern Web Interface
- Subscription Management
- Proxy Only Mode (No DNS hijacking or transparent proxy)
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) $(CURDIR)/luasrc $(PKG_BUILD_DIR)/
	$(CP) $(CURDIR)/root $(PKG_BUILD_DIR)/
	$(CP) $(CURDIR)/po $(PKG_BUILD_DIR)/
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
[ -n "$${IPKG_INSTROOT}" ] || {
	rm -rf /tmp/luci-modulecache
	rm -f /tmp/luci-indexcache
}
exit 0
endef

define Package/$(PKG_NAME)/prerm
#!/bin/sh
uci -q set socks-clash.config.enable=0
uci -q commit socks-clash 2>/dev/null
[ -n "$$(pidof clash)" ] && /etc/init.d/socks-clash stop 2>/dev/null
exit 0
endef

define Package/$(PKG_NAME)/postrm
#!/bin/sh
rm -rf /etc/socks-clash >/dev/null 2>&1
rm -rf /tmp/socks-clash*.log >/dev/null 2>&1
rm -rf /tmp/luci-*
exit 0
endef

define Package/$(PKG_NAME)/install
	# Install LuCI files
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	$(CP) $(PKG_BUILD_DIR)/luasrc/* $(1)/usr/lib/lua/luci/
	
	# Install root files
	$(CP) $(PKG_BUILD_DIR)/root/* $(1)/
	
	# Set permissions
	$(INSTALL_DIR) $(1)/etc/init.d
	chmod 0755 $(1)/etc/init.d/socks-clash
	
	$(INSTALL_DIR) $(1)/usr/share/socks-clash
	chmod -R 0755 $(1)/usr/share/socks-clash/
	
	# Create directories
	$(INSTALL_DIR) $(1)/etc/socks-clash/config
	$(INSTALL_DIR) $(1)/etc/socks-clash/core
	
	# Install translations (if po2lmo exists)
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	-for po in $(PKG_BUILD_DIR)/po/*/*.po; do \
		if [ -f "$$po" ]; then \
			lang=$$(basename $$(dirname $$po)); \
			name=$$(basename $$po .po); \
			if command -v po2lmo >/dev/null 2>&1; then \
				po2lmo $$po $(1)/usr/lib/lua/luci/i18n/$$name.$$lang.lmo; \
			else \
				echo "Warning: po2lmo not found, skipping translation compilation"; \
			fi; \
		fi; \
	done
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
