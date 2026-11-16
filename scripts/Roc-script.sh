#!/bin/bash

# 1. 修改默认管理 IP (192.168.2.1)
sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate

# 2. 移除所有不再需要的包源码
rm -rf feeds/luci/applications/luci-app-3cat
rm -rf feeds/luci/applications/luci-app-passwall
rm -rf feeds/luci/applications/luci-app-smartdns
rm -rf feeds/luci/applications/luci-app-sqm
rm -rf feeds/luci/applications/luci-app-wol
rm -rf feeds/luci/applications/luci-app-frpc
rm -rf feeds/luci/applications/luci-app-frps
rm -rf feeds/luci/applications/luci-app-samba4
rm -rf feeds/luci/applications/luci-app-aria2
rm -rf feeds/luci/applications/luci-app-wechatpush
rm -rf feeds/luci/applications/luci-app-ttyd
rm -rf feeds/luci/applications/luci-app-watchcat
rm -rf feeds/luci/applications/luci-app-argon-config
rm -rf feeds/luci/themes/luci-theme-aurora
rm -rf feeds/packages/net/open-app-filter
rm -rf feeds/packages/net/ariang

# 3. 彻底清理 PassWall 的依赖组件 (释放空间)
rm -rf feeds/packages/net/{xray-core,v2ray-geodata,sing-box,chinadns-ng,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-libev,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,trojan-plus,tuic-client,v2ray-plugin,xray-plugin,geoview,shadow-tls}

# 4. 更新 Golang 版本 (加入安全性判断)
rm -rf feeds/packages/lang/golang
git clone --depth=1 -b master --single-branch --filter=blob:none --sparse https://github.com/laipeng668/packages temp_pkg
cd temp_pkg && git sparse-checkout set lang/golang
if [ -d "lang/golang" ]; then
    mv -f lang/golang ../feeds/packages/lang/golang
elif [ -d "golang" ]; then
    mv -f golang ../feeds/packages/lang/golang
fi
cd .. && rm -rf temp_pkg

# 5. 安装 OpenClash (直接放入 package 目录)
rm -rf package/luci-app-openclash
git clone --depth=1 https://github.com/vernesong/OpenClash package/luci-app-openclash

# 6. 重新建立 packages feed 的索引
./scripts/feeds install -a -p packages
