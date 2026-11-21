#!/bin/bash
set -e

# 1. 修改默认管理 IP (192.168.2.1)
if [ -f package/base-files/files/bin/config_generate ]; then
    sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate
fi

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
cd temp_pkg
git sparse-checkout set lang/golang
if [ -d "lang/golang" ]; then
    mv -f lang/golang ../feeds/packages/lang/golang
elif [ -d "golang" ]; then
    mv -f golang ../feeds/packages/lang/golang
fi
cd ..
rm -rf temp_pkg

# 5. 安装 OpenClash（上游仓库现为 luci-app-openclash/ 子目录结构，需挪平）
rm -rf package/luci-app-openclash package/openclash-src
if git clone --depth=1 https://github.com/vernesong/OpenClash.git package/openclash-src; then
    if [ -f package/openclash-src/luci-app-openclash/Makefile ]; then
        mv package/openclash-src/luci-app-openclash package/luci-app-openclash
        rm -rf package/openclash-src
    elif [ -f package/openclash-src/Makefile ]; then
        mv package/openclash-src package/luci-app-openclash
    else
        echo "!! OpenClash 仓库结构无法识别，改用 luci feed 自带版本"
        rm -rf package/openclash-src
    fi
else
    echo "!! OpenClash 克隆失败，改用 luci feed 自带版本"
    rm -rf package/openclash-src
fi

# 5.5 清掉 feeds 里被我删掉的包残留的悬空软链接，避免扫描期报错
find package/feeds -xtype l -delete 2>/dev/null || true

# 6. 主题 Design（luci feed 里没有，直接放入 package 目录）
rm -rf package/luci-theme-design
if ! git clone --depth=1 -b js https://github.com/0x676e67/luci-theme-design.git package/luci-theme-design; then
    rm -rf package/luci-theme-design
    git clone --depth=1 https://github.com/0x676e67/luci-theme-design.git package/luci-theme-design || true
fi
if [ -f package/luci-theme-design/Makefile ]; then
    rm -rf package/luci-theme-design/.git package/luci-theme-design/preview
    mkdir -p package/luci-theme-design/root/etc/uci-defaults
    cat > package/luci-theme-design/root/etc/uci-defaults/31_design-defaults <<'EOF'
#!/bin/sh
# 底部导航的 proxy 入口默认指向 OpenClash（主题默认值是 shadowsocksr）
uci -q get design.@global[0] >/dev/null 2>&1 || uci -q add design global >/dev/null 2>&1
uci -q set design.@global[0].navbar=display
uci -q set design.@global[0].navbar_proxy=openclash
uci -q commit design

# 首次安装时把 Design 设为默认主题
[ "$PKG_UPGRADE" = 1 ] || {
    uci -q get luci.themes.Design >/dev/null 2>&1 || {
        uci -q set luci.themes.Design=/luci-static/design
        uci -q set luci.main.mediaurlbase=/luci-static/design
        uci -q commit luci
    }
}

exit 0
EOF
    chmod +x package/luci-theme-design/root/etc/uci-defaults/31_design-defaults
else
    echo "!! Design 主题获取失败，界面会回落到内置 bootstrap 主题"
fi

# 7. 重新建立 packages feed 的索引
./scripts/feeds install -a -p packages
