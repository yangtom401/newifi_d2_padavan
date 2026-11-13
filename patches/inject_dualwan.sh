#!/bin/bash
# Dual-WAN & Full Feature Matrix Injection Script for Padavan (Newifi D2)
set -e

WORK_DIR="/opt/rt-n56u"
echo "==> [Padavan Customization] Starting full feature & Dual-WAN injection into $WORK_DIR..."

# 0. Fix dead mirrors and pre-fetch Go & toolchains
echo "==> [Padavan Fixes] Pre-downloading and fixing dead mirrors..."
mkdir -p "$WORK_DIR/trunk/tools/go"
find "$WORK_DIR" -type f \( -name "Makefile" -o -name "*.mk" -o -name "*.sh" \) -exec sed -i 's|gomirrors\.org/dl/go|dl.google.com/go|g' {} + 2>/dev/null || true
find "$WORK_DIR" -type f \( -name "Makefile" -o -name "*.mk" -o -name "*.sh" \) -exec sed -i 's|https://golang.google.cn/dl/|https://dl.google.com/go/|g' {} + 2>/dev/null || true

# Pre-fetch Go 1.15.2 directly
curl -sSL --retry 3 "https://dl.google.com/go/go1.15.2.linux-amd64.tar.gz" -o "$WORK_DIR/trunk/tools/go/go1.15.2.linux-amd64.tar.gz" || curl -sSL --retry 3 "https://go.dev/dl/go1.15.2.linux-amd64.tar.gz" -o "$WORK_DIR/trunk/tools/go/go1.15.2.linux-amd64.tar.gz"
tar -zxf "$WORK_DIR/trunk/tools/go/go1.15.2.linux-amd64.tar.gz" -C "$WORK_DIR/trunk/tools/go"

# Disable htop completely to avoid dead bintray mirror
find "$WORK_DIR/trunk/configs" -type f -name "*.config" -exec sed -i 's/CONFIG_FIRMWARE_INCLUDE_HTOP=y/CONFIG_FIRMWARE_INCLUDE_HTOP=n/g' {} + 2>/dev/null || true

# 1. Patch configs/templates/NEWIFI3.config
TEMPLATE_CONFIG="$WORK_DIR/trunk/configs/templates/NEWIFI3.config"
if [ -f "$TEMPLATE_CONFIG" ] && [ -f "configs/NEWIFI3.config" ]; then
    echo "==> Merging configs/NEWIFI3.config into $TEMPLATE_CONFIG..."
    cat configs/NEWIFI3.config >> "$TEMPLATE_CONFIG"
fi

# 2. Patch trunk/build_firmware_modify directly
# In chongshengB/rt-n56u, build_firmware_modify explicitly forces =n on plugins.
# We must rewrite build_firmware_modify to force =y on all user plugins!
BFM="$WORK_DIR/trunk/build_firmware_modify"
if [ -f "$BFM" ]; then
    echo "==> Patching $BFM to enable all plugins and multipath..."
    
    # Remove all hardcoded =n lines
    sed -i 's/CONFIG_FIRMWARE_INCLUDE_SHADOWSOCKS=y/CONFIG_FIRMWARE_INCLUDE_SHADOWSOCKS=y/g' "$BFM"
    sed -i '/CONFIG_FIRMWARE_INCLUDE_SHADOWSOCKS=n/d' "$BFM"
    sed -i '/CONFIG_FIRMWARE_INCLUDE_V2RAY=n/d' "$BFM"
    sed -i '/CONFIG_FIRMWARE_INCLUDE_TROJAN=n/d' "$BFM"
    sed -i '/CONFIG_FIRMWARE_INCLUDE_SSOBFS=n/d' "$BFM"
    sed -i '/CONFIG_FIRMWARE_INCLUDE_ADBYBY=n/d' "$BFM"
    sed -i '/CONFIG_FIRMWARE_INCLUDE_KOOLPROXY=n/d' "$BFM"
    sed -i '/CONFIG_FIRMWARE_INCLUDE_SMARTDNS=n/d' "$BFM"
    sed -i '/CONFIG_FIRMWARE_INCLUDE_ADGUARDHOME=n/d' "$BFM"
    sed -i '/CONFIG_FIRMWARE_INCLUDE_ZEROTIER=n/d' "$BFM"
    sed -i '/CONFIG_FIRMWARE_INCLUDE_ALIDDNS=n/d' "$BFM"
    sed -i '/CONFIG_FIRMWARE_INCLUDE_CADDYBIN=n/d' "$BFM"
    sed -i '/CONFIG_FIRMWARE_INCLUDE_WYYBIN=n/d' "$BFM"

    # Inject our definitive config right after .config is initialized
    sed -i '/cp -f configs\/templates\/\$1\.config \.config/a \
## Force Enable Full Feature Matrix for Newifi D2 \
echo "CONFIG_FIRMWARE_INCLUDE_SHADOWSOCKS=y" >> .config\
echo "CONFIG_FIRMWARE_INCLUDE_V2RAY=y" >> .config\
echo "CONFIG_FIRMWARE_INCLUDE_TROJAN=y" >> .config\
echo "CONFIG_FIRMWARE_INCLUDE_SSOBFS=y" >> .config\
echo "CONFIG_FIRMWARE_INCLUDE_SMARTDNS=y" >> .config\
echo "CONFIG_FIRMWARE_INCLUDE_ADGUARDHOME=y" >> .config\
echo "CONFIG_FIRMWARE_INCLUDE_ADBYBY=y" >> .config\
echo "CONFIG_FIRMWARE_INCLUDE_ZEROTIER=y" >> .config\
echo "CONFIG_FIRMWARE_INCLUDE_ALIDDNS=y" >> .config\
echo "CONFIG_FIRMWARE_INCLUDE_FRPC=y" >> .config\
echo "CONFIG_FIRMWARE_INCLUDE_TTYD=y" >> .config\
echo "CONFIG_FIRMWARE_INCLUDE_VLMCSD=y" >> .config\
echo "CONFIG_FIRMWARE_INCLUDE_HTOP=n" >> .config\
echo "CONFIG_IP_ADVANCED_ROUTER=y" >> .config\
echo "CONFIG_IP_MULTIPLE_TABLES=y" >> .config\
echo "CONFIG_IP_ROUTE_MULTIPATH=y" >> .config\
echo "CONFIG_IP_ROUTE_VERBOSE=y" >> .config\
echo "CONFIG_NETFILTER_XT_MATCH_STATISTIC=y" >> .config\
echo "CONFIG_NETFILTER_XT_MATCH_CONNMARK=y" >> .config\
echo "CONFIG_NETFILTER_XT_TARGET_CONNMARK=y" >> .config\
' "$BFM"
fi

# 3. WebUI Integration: Copy Advanced_DualWAN_Content.asp to all www directories
echo "==> Deploying Advanced_DualWAN_Content.asp to WebUI directories..."
find "$WORK_DIR/trunk/user" -type d \( -name "www" -o -name "n56u_ribbon_fixed" -o -name "default" \) | while read -r wdir; do
    if [ -f "$wdir/Advanced_WAN_Content.asp" ] || [ -f "$wdir/index.asp" ]; then
        echo "    Copying to $wdir"
        cp -fv custom/web/Advanced_DualWAN_Content.asp "$wdir/"
        chmod 644 "$wdir/Advanced_DualWAN_Content.asp"
    fi
done

# 4. Patch state.js across all themes so Dual-WAN appears in WAN tabs and left menu
echo "==> Patching state.js for Dual-WAN navigation..."
find "$WORK_DIR/trunk/user/www" -type f -name "state.js" | while read -r sfile; do
    echo "    Patching $sfile..."
    # 4a. Add Dual-WAN to tablink[3] (WAN sub-tabs)
    sed -i 's/"Advanced_WAN_Content\.asp",/"Advanced_WAN_Content.asp", "Advanced_DualWAN_Content.asp",/g' "$sfile"
    sed -i 's/"<#menu5_3_1#>",/"<#menu5_3_1#>", "【双WAN拓扑聚合】",/g' "$sfile"

    # 4b. Add Dual-WAN to menuL2 (Advanced Settings Left Menu)
    sed -i '/menuL2_title = new Array/a \  menuL2_title.push("双WAN多线拓扑");' "$sfile"
    sed -i '/menuL2_link  = new Array/a \  menuL2_link.push("Advanced_DualWAN_Content.asp");' "$sfile"
done

# 5. Patch Advanced_WAN_Content.asp with a prominent jump banner
echo "==> Patching Advanced_WAN_Content.asp with navigation banner..."
find "$WORK_DIR/trunk/user/www" -type f -name "Advanced_WAN_Content.asp" | while read -r wan_file; do
    BANNER='<div style="margin: 15px 0; padding: 14px 20px; background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%); border-radius: 8px; color: #fff; box-shadow: 0 4px 12px rgba(0,0,0,0.2);"><div style="font-size: 16px; font-weight: bold; margin-bottom: 6px;">🚀 Newifi D2 专属：双WAN多线聚合 & 硬件端口穿透控制台</div><div style="font-size: 13px; opacity: 0.9; margin-bottom: 10px;">支持图形化拖拽连线定义物理 WAN2、L4 ECMP 1+1 聚合与硬件 NAT 穿透。</div><a href="Advanced_DualWAN_Content.asp" class="btn btn-primary" style="background:#00c6ff; color:#000; font-weight:bold; padding:8px 20px; border-radius:4px; text-decoration:none; display:inline-block;">⚡ 立即进入【双WAN拓扑控制台】</a></div>'
    if grep -q "Advanced_DualWAN_Content.asp" "$wan_file"; then
        echo "    Already patched: $wan_file"
    else
        sed -i "s|<body[^>]*>|&\n$BANNER|g" "$wan_file" 2>/dev/null || true
    fi
done

# 6. Inject Backend Script into firmware romfs / user scripts
echo "==> Injecting Dual-WAN daemon script..."
mkdir -p "$WORK_DIR/trunk/user/scripts"
cp -fv custom/scripts/dualwan_ctl.sh "$WORK_DIR/trunk/user/scripts/"
chmod +x "$WORK_DIR/trunk/user/scripts/dualwan_ctl.sh"

# Hook into post_wan_script.sh
POST_WAN=$(find "$WORK_DIR/trunk/user/scripts" -name "post_wan_script.sh" | head -n 1)
if [ -n "$POST_WAN" ] && [ -f "$POST_WAN" ]; then
    echo "==> Hooking into $POST_WAN..."
    if ! grep -q "dualwan_ctl.sh" "$POST_WAN"; then
        echo -e "\n# Launch Dual-WAN ECMP Controller\n[ -x /user/scripts/dualwan_ctl.sh ] && /user/scripts/dualwan_ctl.sh &\n" >> "$POST_WAN"
    fi
fi

echo "==> [Padavan Customization] All injections and feature patches applied successfully!"
