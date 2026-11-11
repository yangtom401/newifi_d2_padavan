#!/bin/bash
# Dual-WAN & Port Hardware Passthrough Injection Script for Padavan
set -e

WORK_DIR="/opt/rt-n56u"
echo "==> [Padavan Customization] Injecting Dual-WAN UI and scripts into $WORK_DIR..."

# 0. Fix dead mirrors and pre-fetch Go toolchain
echo "==> [Padavan Fixes] Pre-downloading and fixing Go toolchain mirror..."
mkdir -p "$WORK_DIR/trunk/tools/go"
# Replace gomirrors.org with dl.google.com in all Makefiles and scripts
find "$WORK_DIR" -type f \( -name "Makefile" -o -name "*.mk" -o -name "*.sh" \) -exec sed -i 's|gomirrors\.org/dl/go|dl.google.com/go|g' {} + 2>/dev/null || true
find "$WORK_DIR" -type f \( -name "Makefile" -o -name "*.mk" -o -name "*.sh" \) -exec sed -i 's|https://golang.google.cn/dl/|https://dl.google.com/go/|g' {} + 2>/dev/null || true

# Pre-fetch Go 1.15.2 directly from official dl.google.com or go.dev
curl -sSL --retry 3 "https://dl.google.com/go/go1.15.2.linux-amd64.tar.gz" -o "$WORK_DIR/trunk/tools/go/go1.15.2.linux-amd64.tar.gz" || curl -sSL --retry 3 "https://go.dev/dl/go1.15.2.linux-amd64.tar.gz" -o "$WORK_DIR/trunk/tools/go/go1.15.2.linux-amd64.tar.gz"
# Extract ahead of time so tools/Makefile won't need to do it
tar -zxf "$WORK_DIR/trunk/tools/go/go1.15.2.linux-amd64.tar.gz" -C "$WORK_DIR/trunk/tools/go"
ls -la "$WORK_DIR/trunk/tools/go"

# 1. Dynamically locate Web UI directory where Advanced_WAN_Content.asp is
WAN_ASP=$(find $WORK_DIR/trunk/user -name "Advanced_WAN_Content.asp" | head -n 1)
if [ -n "$WAN_ASP" ]; then
    WEB_DIR=$(dirname "$WAN_ASP")
    echo "==> Located WebUI directory: $WEB_DIR"
    cp -fv custom/web/Advanced_DualWAN_Content.asp "$WEB_DIR/"
    chmod 644 "$WEB_DIR/Advanced_DualWAN_Content.asp"
    
    # Locate menu_tree.js
    MENU_FILE=$(find "$WEB_DIR" -name "menu_tree.js" | head -n 1)
    if [ -f "$MENU_FILE" ]; then
        echo "==> Patching $MENU_FILE with Dual-WAN menu..."
        sed -i '/Advanced_WAN_Content\.asp/a \t\t\t\t\t\t\t\t\t\t\t\t\t\tnew menu_item("双WAN拓扑", "Advanced_DualWAN_Content.asp"),' "$MENU_FILE" 2>/dev/null || true
    fi
else
    echo "==> Searching for www or web directories under trunk/user..."
    TARGET_WWW=$(find $WORK_DIR/trunk/user -type d \( -name "www" -o -name "web" \) | head -n 1)
    if [ -n "$TARGET_WWW" ]; then
        echo "==> Fallback to $TARGET_WWW"
        cp -fv custom/web/Advanced_DualWAN_Content.asp "$TARGET_WWW/"
    fi
fi

# 2. Inject Backend Script
SCRIPT_DIR="$WORK_DIR/trunk/user/scripts"
mkdir -p "$SCRIPT_DIR"
cp -fv custom/scripts/dualwan_ctl.sh "$SCRIPT_DIR/"
chmod +x "$SCRIPT_DIR/dualwan_ctl.sh"

# 3. Hook into post_wan_script
POST_WAN=$(find $WORK_DIR/trunk/user/scripts -name "post_wan_script.sh" | head -n 1)
if [ -f "$POST_WAN" ]; then
    echo "==> Hooking into $POST_WAN..."
    echo -e "\n# Launch Dual-WAN ECMP Controller\n[ -x /user/scripts/dualwan_ctl.sh ] && /user/scripts/dualwan_ctl.sh &\n" >> "$POST_WAN"
fi

# 4. Overwrite/Merge NEWIFI3.config
TEMPLATE_CONFIG="$WORK_DIR/trunk/configs/templates/NEWIFI3.config"
if [ -f "configs/NEWIFI3.config" ] && [ -f "$TEMPLATE_CONFIG" ]; then
    echo "==> Merging configs/NEWIFI3.config into $TEMPLATE_CONFIG..."
    cat configs/NEWIFI3.config >> "$TEMPLATE_CONFIG"
fi

echo "==> [Padavan Customization] Injection completed successfully!"
