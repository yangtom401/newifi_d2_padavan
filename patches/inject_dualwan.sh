#!/bin/bash
# Dual-WAN & Port Hardware Passthrough Injection Script for Padavan
set -e

WORK_DIR="/opt/rt-n56u"
echo "==> [Padavan Customization] Injecting Dual-WAN UI and scripts into $WORK_DIR..."

# 1. Inject Web UI
cp -fv custom/web/Advanced_DualWAN_Content.asp $WORK_DIR/trunk/user/httpd/web/
chmod 644 $WORK_DIR/trunk/user/httpd/web/Advanced_DualWAN_Content.asp

# 2. Add Menu Entry in menu_tree.js
MENU_FILE="$WORK_DIR/trunk/user/httpd/web/menu_tree.js"
if [ -f "$MENU_FILE" ]; then
    echo "==> Patching $MENU_FILE with Dual-WAN menu..."
    # Insert Dual-WAN menu entry right after Advanced_WAN_Content.asp
    sed -i '/Advanced_WAN_Content\.asp/a \t\t\t\t\t\t\t\t\t\t\t\t\t\tnew menu_item("双WAN拓扑", "Advanced_DualWAN_Content.asp"),' "$MENU_FILE" 2>/dev/null || true
fi

# 3. Inject Backend Script
mkdir -p $WORK_DIR/trunk/user/scripts
cp -fv custom/scripts/dualwan_ctl.sh $WORK_DIR/trunk/user/scripts/
chmod +x $WORK_DIR/trunk/user/scripts/dualwan_ctl.sh

# 4. Integrate into post_wan_script hook in trunk/user/scripts/defaults/post_wan_script.sh
POST_WAN="$WORK_DIR/trunk/user/scripts/defaults/post_wan_script.sh"
if [ -f "$POST_WAN" ]; then
    echo "==> Hooking into $POST_WAN..."
    echo -e "\n# Launch Dual-WAN ECMP Controller\n[ -x /user/scripts/dualwan_ctl.sh ] && /user/scripts/dualwan_ctl.sh &\n" >> "$POST_WAN"
fi

# 5. Overwrite/Merge NEWIFI3.config
if [ -f "configs/NEWIFI3.config" ]; then
    echo "==> Merging configs/NEWIFI3.config into $WORK_DIR/trunk/configs/templates/NEWIFI3.config..."
    cat configs/NEWIFI3.config >> $WORK_DIR/trunk/configs/templates/NEWIFI3.config
fi

echo "==> [Padavan Customization] Injection completed successfully!"
