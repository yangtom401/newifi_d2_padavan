# Newifi D2 (新路由3) Padavan 极致性能定制版

[![Build Padavan for Newifi D2](https://github.com/yangtom401/newifi_d2_padavan/actions/workflows/build-padavan.yml/badge.svg)](https://github.com/yangtom401/newifi_d2_padavan/actions/workflows/build-padavan.yml)

专为 **Newifi D2 (新路由3 / MT7621 + 512MB RAM + 32MB Flash)** 深度调校打造的 **Padavan (老毛子) 极致性能定制固件**。

---

## ⚡ 为什么选择 Padavan 版本？

与 OpenWrt 相比，Padavan 在联发科 MT7621 平台上具备独特的核心优势：

1. **联发科官方闭源原厂无线驱动 (MT7603E + MT7612E)**：
   * 采用 MTK SDK 专有驱动体系，彻底告别开源驱动可能带来的 2.4G 丢包与断流问题。
   * 内置最佳 PA/LNA 功率放大校准，2.4G (300Mbps) 与 5G (867Mbps) 穿墙信号与吞吐量更强、更稳。
2. **芯片级 HWNAT 硬件加速**：
   * 联发科 MT7621 原生硬件 NAT 极限卸载，千兆全双工 NAT 转发跑满时，CPU 占用率常年保持在 **< 3%**，整机发热极低。
3. **轻量极速与超低内存底销**：
   * 原生 C 语言底层架构，开机启动耗时仅需 **10 ~ 15 秒**，系统常驻内存仅占用 **~40MB**，比任何通用系统都更轻盈迅捷。

---

## 🌟 核心特性与功能矩阵

### 1. 独家双WAN硬件穿透 & 拖拽拓扑 (Dual WAN ECMP)
* **交互式面板拓扑 UI**：支持直接在 WebUI 中拖拽次级宽带线缆到任意 LAN 端口（LAN 1 ~ 4），即刻将该端口从内部交换机剥离，划入独立的第二物理网卡 `eth2.3`。
* **内核级四元组多路径负载聚合**：启用 Linux 内核 `fib_multipath_hash_policy=1`，支持两条宽带 **1+1 带宽叠加**（多线程满速下载翻倍），同时保障网银、游戏连接不漂移。
* **多模式接入**：支持 WAN1/WAN2 分别独立配置 PPPoE 拨号、DHCP 自动分配或静态 IP，并自动配置对称路由（源进源出）。

### 2. 科学上网与防污染代理 (对标 PassWall / SSR+)
* **内核全协议支持**：Shadowsocks Plus、Xray-core、V2Ray、Trojan、Clash。
* **DNS 优选解析**：SmartDNS（双向分流与低延迟优选）、Chinadns-ng、Dnsmasq-China-List 规则支持。

### 3. 远程访问与内网穿透
* **ZeroTier**：异地局域网一键组网控制器与客户端。
* **Frp 穿透**：高性能 `frpc` 客户端。
* **DDNS-Go**：现代化全功能动态域名解析，支持阿里云、腾讯云 DNSPod、Cloudflare、华为云 IPv4/IPv6。
* **DDNSTO**：微信扫码即用的轻量级内网穿透。

### 4. 系统实用工具与优化
* **广告拦截**：内置 AdGuardHome 与 Adbyby Plus+。
* **局域网激活**：KMS 服务 (`vlmcsd`)，自动激活局域网内所有 Windows 与 Office。
* **网页终端**：内置 `ttyd` 浏览器 SSH 终端。
* **网络加速**：Shortcut-FE (SFE) 与 TCP BBR 拥塞控制算法。

---

## 🖥️ 默认配置说明

* **默认后台 IP**：`192.168.123.1` (或 `192.168.1.1`)
* **默认用户名**：`admin`
* **默认密码**：`admin`
* **默认 Wi-Fi SSID**：`PDCN` / `PDCN_5G`
* **默认 Wi-Fi 密码**：`1234567890`

---

## 🛠️ 刷机指南

1. **首次刷机（通过 Breed Web 控制台）**：
   * 路由器拔掉电源，按住复位键（Reset）不放，插上电源，等待指示灯闪烁后松开。
   * 电脑网线连接 LAN 口，浏览器打开 `192.168.1.1` 进入 Breed 控制台。
   * 点击【固件更新】-> 勾选【固件】-> 选择编译出的 `*.trx` 文件。
   * 点击【上传】并确认刷入，等待 1~2 分钟重启完成即可。
2. **已有 Padavan 升级**：
   * 进入 Padavan 后台 -> 【系统管理】 -> 【固件升级】 -> 选择新版 `*.trx` 固件直接升级。

---

## 🤖 自动化构建工作流

本仓库通过 GitHub Actions 进行全自动云端交叉编译：
* 触发方式：在 Actions 页面点击 **Run workflow** 手动触发，或向仓库推送代码自动构建。
* 产物输出：构建完成后，自动将 `.trx` 固件及 MD5/SHA256 校验文件发布到 [GitHub Releases](../../releases)。
