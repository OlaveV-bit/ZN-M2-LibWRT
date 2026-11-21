# OpenWrt / LibWrt 云编译项目（兆能 ZN-M2 / IPQ60XX 专用版）

基于 **GitHub Actions** 的全自动云端编译项目，面向 **兆能 ZN-M2（Qualcomm IPQ60XX，1GB 内存魔改版 + 加装 USB3.0 接口及独立供电）** 定制。源码采用 `laipeng668/openwrt-6.x` 的 `25.12-nss` 分支，集成高通 **NSS v11.4** 硬件转发加速与 **Linux 6.12.x** 内核，按“纯有线、带外接存储、不要 Wi-Fi”的定位做了精简与调优。

---

## ⚠️ 刷机前必读

1. **纯有线固件（无 Wi-Fi）**：
   编译阶段已显式关闭整套无线驱动与宿主服务（`kmod-ath11k`、`kmod-ath11k-ahb/pci`、`ath11k-firmware-ipq6018`、`wpad-*`、`hostapd-common` 全为 `=n`）。固件不含任何无线功能，适合弱电箱主路由或搭配独立 AP 组网，可省下内存与固件体积。
2. **USB3.0 已内置驱动**：
   IPQ6018 的 USB3 是 Synopsys DWC3 控制器，配置里已加入 `kmod-usb-dwc3-qcom`、`kmod-usb-xhci-hcd`、`kmod-usb3` 及完整存储栈（`kmod-usb-storage`、`uas`、`usb-storage-extras`、`usbutils`），并带 `exfat / ntfs3 / vfat / ext4` 与 `nls` 编码，配合 `block-mount` + `luci-app-diskman` 可自动挂载外接硬盘。设备树里 `&usb2`、`&usb3` 及两个 PHY 本身就是 `okay`，无需改 DTS。
3. **1GB 内存需自行确认**：
   本套 DTS 链没有 `memory` 节点，内存大小由 U-Boot 上报。刷完执行 `free -m`，接近 900–1000MB 即正常；若只有约 500MB，说明 bootloader 只报告了 512MB，需要换支持 1GB 的 uboot 或在 bootargs 补 `mem=1024M`。
4. **后台默认地址**：
   已改为 **`192.168.2.1`**（非 `192.168.1.1`），刷机后请让电脑处于 `192.168.2.x` 网段或走 DHCP。
5. **默认无密码**：
   首次登录直接进入，请第一时间在 **系统 → 管理权** 设置管理员密码。
6. **默认主题为 Design**：
   首次开机自动启用 `luci-theme-design`，底部导航的「代理」图标默认指向 **OpenClash**（`/cgi-bin/luci/admin/services/openclash`）。

---

## 📌 核心特性

| 维度 | 配置说明 |
| :--- | :--- |
| **目标机型** | 兆能 ZN-M2（`qualcommax_ipq60xx_DEVICE_zn_m2`），1GB 内存魔改版 |
| **源码仓库** | `https://github.com/laipeng668/openwrt-6.x.git`（分支 `25.12-nss`） |
| **内核版本** | Linux `6.12.x` |
| **硬件加速** | 高通 NSS 固件 `11.4`（`CONFIG_NSS_FIRMWARE_VERSION_11_4=y`，与 Wi-Fi 无关，务必保留） |
| **编译器优化** | `-O3 -pipe -march=armv8-a+crypto+crc -mcpu=cortex-a53+crypto+crc -mtune=cortex-a53` |
| **内存策略** | 1GB 物理内存 + `zram-swap`（LZ4 压缩，内核 `ZRAM_BACKEND_LZ4`） |
| **CPU 调速器** | `performance`、`powersave`、`userspace`、`ondemand`、`conservative`、`schedutil` 六种全编译 |
| **USB 扩展** | DWC3 + XHCI + UAS 存储栈，支持 exfat / ntfs3 / vfat / ext4 自动挂载 |
| **软件包格式** | 25.12 已切换 `.apk`，产物自动打包 `IPQ60XX.Packages.tar.gz` |
| **界面与语言** | Design 主题（`luci-theme-design`）+ 简体中文（`LUCI_LANG_zh_Hans`）+ `luci-compat` |

---

## 🛠️ 预装软件与精简清单

### 1. 已集成插件与工具

* **网络与代理**：
  * **OpenClash**（`luci-app-openclash`）：编译时从 `vernesong/OpenClash` 拉最新源码（自动处理其 `luci-app-openclash/` 子目录结构，克隆失败时回落到 luci feed 自带版本），并单独拉取较新 `Golang` 工具链；`ruby`、`ruby-yaml`、`kmod-tun`、`ip-full`、`ipset`、`iptables-mod-tproxy/extra`、`libcap-bin`、`coreutils-nohup`、`luci-compat` 等依赖由包管理自动补齐。
  * **UPnP**（`luci-app-upnp`）、**DDNS**（`luci-app-ddns`）。
* **系统与硬件**：
  * **CPU 调频**（`luci-app-cpufreq` + `cpufreq`）、**磁盘管理**（`luci-app-diskman`）、`autocore`。
* **USB / 存储**：`usbutils`、`block-mount`、`blockd`、`kmod-fs-exfat/ntfs3/vfat/ext4`、`kmod-nls-base/cp437/iso8859-1/utf8`。
* **维护与测试工具**：`tmux`、`nano-full`、`openssh-sftp-server`、`htop`、`btop`、`dmesg`、`coremark`、`fdisk`、`cfdisk`、`tune2fs`、`fstrim`、`hdparm`、`smartmontools-drivedb`、`zoneinfo-asia`。
  * 说明：`sgdisk` 在 25.12 的 feeds 中已无 `gdisk` 包，配置里已注释；分区用 `fdisk`/`cfdisk` 即可。

### 2. 已移除插件（源码级清理）

`Roc-script.sh` 在编译前直接从 `feeds` 源码删掉以下组件，减少冲突与体积：

* **代理类**：PassWall（`luci-app-passwall`）及其全套依赖（`xray-core`、`v2ray-geodata`、`sing-box`、`chinadns-ng`、`dns2socks`、`hysteria`、`ipt2socks`、`microsocks`、`naiveproxy`、`shadowsocks-libev/rust`、`shadowsocksr-libev`、`simple-obfs`、`tcping`、`trojan-plus`、`tuic-client`、`v2ray-plugin`、`xray-plugin`、`geoview`、`shadow-tls`）。
* **网络与服务**：SmartDNS、SQM、Frpc/Frps、Samba4、Aria2/Ariang、WOL、WeChatPush、TTYd、Watchcat、`luci-app-3cat`、`open-app-filter`。
* **界面**：Aurora 主题、`luci-app-argon-config`；Argon 主题包仍在 feed 里，但 `CONFIG_PACKAGE_luci-theme-argon` 已设为 `=n`（不装进固件）。

---

## 🌐 默认登录信息

* **管理后台**：`http://192.168.2.1`
* **SSH**：`ssh root@192.168.2.1`（端口 22）
* **用户名**：`root`，**密码**：无（首次登录后请立即设置）

---

## 📂 仓库文件结构

```text
.
├── .github/workflows/IPQ60XX-LibWrt.yml   # 编译 + Release 发布工作流
├── configs/
│   ├── IPQ60XX.config                     # 机型、无 Wi-Fi、USB3.0 驱动栈
│   └── General.config                     # 优化参数、ZRAM、调速器、插件清单、主题
└── scripts/
    └── Roc-script.sh                      # 改默认 IP、清理冗余包、更新 Golang、OpenClash、Design 主题
```

---

## 🚀 云编译使用

1. **Fork 仓库**，进入 **Settings → Actions → General → Workflow permissions**，选 **Read and write permissions** 并保存（发布 Release 必需）。
2. 打开 **Actions → `IPQ60XX-LibWrt` → Run workflow** 触发。
3. 工作流会：清理 runner 磁盘 → 装编译依赖 → 克隆源码（`/mnt/openwrt`）→ 恢复 `ccache`/`staging_dir` 缓存 → feeds update/install → 修补 rust 的 `download-ci-llvm` → 执行自定义脚本 → 生成 `.config` → `make download` → 编译 → 整理并发布。
4. 首次编译无缓存，全量工具链 + NSS + OpenClash 耗时较长（可能 1–2 小时以上，接近 GitHub 6 小时上限）；命中缓存后明显加快。若想更快，可把 `General.config` 里的 `CONFIG_DEVEL=y` 去掉改用预编译工具链。

产物发布在 **Releases**（Tag 固定为 `IPQ60XX`，每次覆盖旧资产）：

* `*-zn_m2-*sysupgrade.bin`：sysupgrade 固件；同目录另有 factory 等镜像（视目标配置而定）。
* `IPQ60XX.Packages.tar.gz`：本次编译的全部 `.apk` 离线包。
* `IPQ60XX.config`、`IPQ60XX.config.buildinfo`、`IPQ60XX.manifest`：配置与包清单备份。

---

## 🔧 进阶自定义

1. **开启定时编译**：在 `.github/workflows/IPQ60XX-LibWrt.yml` 第 6–7 行取消注释即可（`cron: 0 20 * * *` = 北京时间次日 04:00）。
2. **改默认 IP**：`scripts/Roc-script.sh` 第 4–7 行的 `sed` 改成你要的网段。
3. **恢复 Wi-Fi**：删除 `configs/IPQ60XX.config` 第 6–15 行整段「无线关闭」配置（`kmod-ath11k*`、`ath11k-firmware-ipq6018`、`wpad-openssl/basic-mbedtls/basic-wolfssl`、`hostapd-common`），按需补 `wpad` 与固件包。
4. **加插件**：在 `configs/General.config` 追加 `CONFIG_PACKAGE_luci-app-xxx=y`；先确认该包没被 `Roc-script.sh` 的 `rm -rf` 列表删掉源码。
5. **换主题**：`configs/General.config` 里把 `luci-theme-argon` 设 `=y`、`luci-theme-design` 设 `=n` 重新编译即可（Design 官方标称支持到 24.x，25.12 上由 LuCI 的 ucode/lua 双模板回退机制兜底，渲染不了会自动切回其它已注册主题，不会白屏）。
6. **编译报错**：`-O3` 偶尔会让个别包（ruby、部分 C++ 组件）失败，把 `CONFIG_TARGET_OPTIMIZATION` 退回 `-O2` 再试。

---

## 📋 刷机与验证

1. **首次刷入**：断电按住 Reset 通电，约 8–10 秒后松开进入 U-Boot 恢复模式；电脑设静态 IP（如 `192.168.1.2`），浏览器打开 `192.168.1.1` 上传固件。完成后改回 DHCP，访问 `http://192.168.2.1`。
2. **同源升级**：后台 **系统 → 备份/升级** 上传 `sysupgrade` 固件。
3. **刷完自检**：

```bash
free -m                                  # 1GB 魔改应接近 900–1000MB
dmesg | grep -i -E "dwc3|xhci"           # USB3 控制器是否起来
lsusb                                    # 插 U 盘后能否识别
uci get luci.main.mediaurlbase           # 应为 /luci-static/design
uci get design.@global[0].navbar_proxy   # 应为 openclash
```

4. **OpenClash 内核**：固件只带插件主体，首次使用需在 **服务 → OpenClash → 插件设置 → 版本更新** 下载或上传 `Meta (mihomo)` 内核，架构选 `linux-arm64`。

---

## 🙏 鸣谢

* 底层源码：[laipeng668/openwrt-6.x](https://github.com/laipeng668/openwrt-6.x)
* 代理插件：[vernesong/OpenClash](https://github.com/vernesong/OpenClash)
* 主题：[0x676e67/luci-theme-design](https://github.com/0x676e67/luci-theme-design)
* 编译依赖：[ophub](https://ophub.org)
* 发布动作：[ncipollo/release-action](https://github.com/ncipollo/release-action)
