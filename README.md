# OpenWrt / LibWrt 云编译项目 (兆能 ZN-M2 / IPQ60XX 专用版)

本项目基于 **GitHub Actions** 实现全自动化云端编译，专为 **兆能 ZN-M2 (Qualcomm IPQ60XX)** 路由器深度定制。项目采用 `laipeng668/openwrt-6.x`（`25.12-nss` 分支）作为底层源码，集成高通 **NSS (Network Subsystem) v11.4** 硬件网络加速引擎与 **Linux 6.12.x** 内核，针对高负载网络转发与科学上网场景进行了极致精简与性能调优。

---

## ⚠️ 刷机前必读（重要声明）

1. **纯有线固件（无 Wi-Fi 功能）**：
   * 本配置在编译阶段已显式禁用了所有无线驱动与固件（`kmod-ath11k=n`、`ath11k-firmware-ipq6018=n`、`wpad-openssl=n`、`hostapd-common=n`）。
   * **固件不包含任何无线网络功能**，专为弱电箱主路由、纯有线网关或搭配独立 AP（无线接入点）组网的用户设计，可大幅释放系统内存并提升有线转发稳定性。
2. **后台默认地址变更**：
   * 默认管理后台 IP 已修改为 **`192.168.2.1`**（非传统的 `192.168.1.1`），刷机后请确保电脑网卡处于 `192.168.2.x` 网段或使用 DHCP 自动获取 IP。
3. **默认无密码**：
   * 首次登录后台无需密码，进入系统后请第一时间前往 **系统 -> 管理权** 设置高强度管理员密码。

---

## 📌 核心特性与技术架构

| 特性维度 | 详细配置说明 |
| :--- | :--- |
| **目标机型** | 兆能 ZN-M2 (`qualcommax_ipq60xx_DEVICE_zn_m2`) |
| **源码仓库** | `https://github.com/laipeng668/openwrt-6.x.git` (分支: `25.12-nss`) |
| **内核版本** | Linux `6.12.x` |
| **硬件加速** | 高通 NSS 固件 `11.4` (`CONFIG_NSS_FIRMWARE_VERSION_11_4=y`) |
| **编译器优化** | `-O3 -pipe -march=armv8-a+crypto+crc -mcpu=cortex-a53+crypto+crc -mtune=cortex-a53` |
| **内存管理** | 启用 `1GB` 内存配置策略 (`CONFIG_ATH11K_MEM_PROFILE_1GB=y`) + `ZRAM` 虚拟内存压缩 (默认 `LZ4` 算法) |
| **软件包格式** | 支持新版 OpenWrt `.apk` 软件包格式，编译产物自动打包 `IPQ60XX.Packages.tar.gz` |
| **界面与语言** | 默认内置 `Argon` 主题 (`luci-theme-argon`)，包含繁体中文 (`zh_Hant`) 与基础中文语言包 |

---

## 🛠️ 预装软件与精简清单

### 1. 已集成插件与工具
* **网络与代理核心**：
  * **OpenClash** (`luci-app-openclash`)：编译时直接拉取 `vernesong/OpenClash` 最新源码，并独立拉取最新 `Golang` 环境编译，完整集成 `ruby`、`ruby-yaml`、`kmod-tun`、`ip-full`、`ipset`、`iptables-mod-tproxy`、`iptables-mod-extra`、`libcap-bin`、`coreutils-nohup` 等全部运行依赖。
  * **UPnP** (`luci-app-upnp`)：支持内网设备自动端口映射。
  * **动态域名解析** (`luci-app-ddns`)：支持主流域名服务商的 DDNS 动态解析。
* **系统与硬件管理**：
  * **CPU 调频** (`luci-app-cpufreq`)：支持查看 CPU 实时频率及调整调速器（Governor）策略。
  * **磁盘管理** (`luci-app-diskman`)：支持 Web 界面可视化分区、格式化及挂载外接存储。
* **底层维护与性能测试工具**：
  * 终端与编辑器：`tmux`、`nano-full`、`openssh-sftp-server`
  * 监控与压测：`htop`、`btop`、`dmesg`、`coremark`、`autocore`
  * 磁盘与分区工具：`fdisk`、`cfdisk`、`sgdisk`、`tune2fs`、`fstrim`、`hdparm`、`smartmontools-drivedb`

### 2. 已移除插件（源码级彻底清理）
为防止插件冲突、减少固件体积并加快云编译速度，自定义脚本 (`Roc-script.sh`) 已从 `feeds` 源码层彻底删除了以下组件及其依赖：
* **代理类**：PassWall (`luci-app-passwall`) 及其全套核心依赖（`xray-core`、`sing-box`、`hysteria`、`v2ray-geodata`、`chinadns-ng`、`shadowsocks-rust`、`trojan-plus`、`tuic-client` 等）。
* **网络与服务类**：`SmartDNS`、`SQM / sqm-scripts-nss`、`Frpc / Frps`、`WireGuard`、`Samba4`、`Aria2 / Ariang`、`BanIP`、`ACME`、`OAF 应用过滤`、`ARP 绑定`、`网络唤醒 (WOL)`、`KMS (vlmcsd)`、`USB 打印服务`。
* **系统与界面类**：`TTYd 网页终端`、`Watchcat`、`微信推送 (wechatpush)`、`定时重启 (autoreboot)`、`Argon 主题配置插件 (argon-config)`、`Aurora 主题`。

---

## 🌐 默认登录信息

* **管理后台地址**：`http://192.168.2.1`
* **SSH 连接地址**：`ssh root@192.168.2.1` (端口 `22`)
* **默认用户名**：`root`
* **默认密码**：`无`（直接回车或点击登录即可）

---

## 📂 仓库文件结构说明

```text
.
├── .github/
│   └── workflows/
│       └── IPQ60XX-LibWrt.yml   # GitHub Actions 自动化编译与 Release 发布工作流
├── configs/
│   ├── IPQ60XX.config           # 目标平台 (qualcommax/ipq60xx)、ZN-M2 机型、NSS 11.4 及禁用 Wi-Fi 配置
│   └── General.config           # GCC 架构优化参数、ZRAM 压缩配置及插件启用/禁用清单
└── scripts/
    └── Roc-script.sh            # 编译前自定义脚本（修改 IP、清理冗余包源码、更新 Golang、克隆 OpenClash）
```

---

## 🚀 云编译使用教程

### 第一步：准备仓库与权限
1. 点击本仓库右上角的 **Fork** 按钮，将项目复刻到你自己的 GitHub 账号下。
2. 进入你 Fork 后的仓库，点击顶部菜单栏的 **Settings** -> 左侧 **Actions** -> **General**。
3. 向下滚动找到 **Workflow permissions**，勾选 **`Read and write permissions`**，然后点击 **Save** 保存（此步骤为自动发布 Releases 的必要权限）。

### 第二步：启动编译
1. 点击仓库顶部菜单栏的 **Actions**。
2. 在左侧工作流列表中选择 **`IPQ60XX-LibWrt`**。
3. 点击右侧的 **`Run workflow`** 下拉按钮，再次点击绿色的 **`Run workflow`** 即可开始云端编译。
4. 工作流内置了 **ccache 与 staging_dir 缓存机制**，首次编译约需 40~60 分钟，后续命中缓存后编译时间将大幅缩短。

### 第三步：获取固件
编译成功后，工作流会自动整理产物并发布到仓库右侧的 **Releases** 页面（Tag 标签为 `IPQ60XX`），包含以下文件：
* `*-squashfs-sysupgrade.bin` / `*-factory.bin`：刷机固件文件（用于 U-Boot 刷入或后台升级）。
* `IPQ60XX.Packages.tar.gz`：本次编译生成的全部 `.apk` 软件包离线归档。
* `IPQ60XX.config` / `IPQ60XX.config.buildinfo` / `IPQ60XX.manifest`：完整编译配置与软件包清单备份。

---

## 🔧 进阶自定义修改指南

如果你希望根据个人需求调整固件配置，可按以下说明修改对应文件：

1. **开启定时自动编译**：
   打开 `.github/workflows/IPQ60XX-LibWrt.yml`，取消第 6-7 行的注释（默认配置为北京时间每天凌晨 04:00 自动编译）：
   ```yaml
   schedule:
     - cron: 0 20 * * *  # UTC 时间 20:00 对应北京时间次日 04:00
   ```
2. **修改默认管理 IP**：
   编辑 `scripts/Roc-script.sh` 第 4 行，将 `192.168.2.1` 替换为你需要的局域网段地址：
   ```bash
   sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate
   ```
3. **恢复 Wi-Fi 无线功能**：
   打开 `configs/IPQ60XX.config`，删除或注释掉末尾禁用无线驱动与宿主服务的 6 行配置：
   ```ini
   # CONFIG_PACKAGE_kmod-ath11k=n
   # CONFIG_PACKAGE_kmod-ath11k-ahb=n
   # CONFIG_PACKAGE_kmod-ath11k-pci=n
   # CONFIG_PACKAGE_ath11k-firmware-ipq6018=n
   # CONFIG_PACKAGE_wpad-openssl=n
   # CONFIG_PACKAGE_hostapd-common=n
   ```
4. **添加额外插件**：
   * 在 `configs/General.config` 末尾追加 `CONFIG_PACKAGE_luci-app-xxx=y`。
   * **注意**：添加前务必检查 `scripts/Roc-script.sh` 的第 3 步，确保你想要添加的插件没有在 `rm -rf` 清理列表中被删除源码。

---

## 📋 刷机简要指引（兆能 ZN-M2）

1. **首次刷入（从原厂或其他固件刷入）**：
   * 建议通过路由器 U-Boot 恢复模式刷入：断电按住路由器 Reset 键不放并通电，等待约 8~10 秒后松开。
   * 电脑网线连接路由器 LAN 口，设置静态 IP（如 `192.168.1.2`），浏览器访问 `192.168.1.1` 进入 U-Boot 界面，上传固件完成刷机。
   * 刷机重启完成后，将电脑网卡改回自动获取 IP，通过 **`http://192.168.2.1`** 访问新系统后台。
2. **同源固件升级**：
   * 直接登录 `http://192.168.2.1`，进入 **系统 -> 备份/升级**，上传最新的 `sysupgrade` 固件执行升级即可。
3. **OpenClash 内核补充**：
   * 固件内置了 OpenClash 插件主程序及依赖，首次使用需在 **服务 -> OpenClash -> 插件设置 -> 版本更新** 中手动下载或上传对应的 `Meta` (`mihomo`) 内核（架构选择 `linux-arm64`）。

---

## 🙏 鸣谢与开源许可

* 底层源码：[laipeng668/openwrt-6.x](https://github.com/laipeng668/openwrt-6.x)
* 代理插件：[vernesong/OpenClash](https://github.com/vernesong/OpenClash)
* 编译依赖脚本：[ophub](https://ophub.org)
* Release 发布动作：[ncipollo/release-action](https://github.com/ncipollo/release-action)
