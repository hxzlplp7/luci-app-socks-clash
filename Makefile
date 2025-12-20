include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-socks-clash
PKG_VERSION:=1.0.3
PKG_RELEASE:=1

PKG_MAINTAINER:=SocksClash <https://github.com/socks-clash>

LUCI_TITLE:=LuCI support for SOCKS/HTTP Proxy with Clash
LUCI_DEPENDS:=+luci-base +bash +curl +ca-bundle +coreutils-nohup
LUCI_PKGARCH:=all

# Config files
define Package/$(PKG_NAME)/conffiles
/etc/config/socks-clash
endef

include $(TOPDIR)/feeds/luci/luci.mk

# Post-install script
define Package/$(PKG_NAME)/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
	rm -rf /tmp/luci-modulecache
	rm -f /tmp/luci-indexcache
}
exit 0
endef

# Pre-remove script
define Package/$(PKG_NAME)/prerm
#!/bin/sh
uci -q set socks-clash.config.enable=0
uci -q commit socks-clash
[ -n "$$(pidof clash)" ] && /etc/init.d/socks-clash stop 2>/dev/null
exit 0
endef

# Post-remove script
define Package/$(PKG_NAME)/postrm
#!/bin/sh
rm -rf /etc/socks-clash >/dev/null 2>&1
rm -rf /tmp/socks-clash*.log >/dev/null 2>&1
rm -rf /tmp/luci-*
exit 0
endef

# Custom call since we are using luci.mk
$(eval $(call BuildPackage,$(PKG_NAME)))
