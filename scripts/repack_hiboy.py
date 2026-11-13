#!/usr/bin/env python3
import os
import sys
import struct
import zlib
import subprocess
import shutil

def main():
    trx_file = sys.argv[1] if len(sys.argv) > 1 else "RT-N56UB1-newifi3D2-512M_3.4.3.9-099.trx"
    output_file = sys.argv[2] if len(sys.argv) > 2 else "NEWIFI3_Hiboy_DualWAN.trx"

    print(f"[*] Reading original Hiboy firmware: {trx_file}")
    with open(trx_file, "rb") as f:
        data = f.read()

    # Parse uImage header
    hdr = data[:64]
    magic, hcrc, time, size, load, ep, dcrc, os_type, arch, img_type, comp, name = struct.unpack('>IIIIIIIBBBB32s', hdr)
    print(f"[*] Original uImage: Magic={hex(magic)}, Size={size}, Load={hex(load)}, EP={hex(ep)}, Name={name}")

    # Find SquashFS offset
    idx = data.find(b"hsqs")
    if idx == -1:
        print("[-] Error: SquashFS magic (hsqs) not found!")
        sys.exit(1)

    print(f"[*] Found SquashFS at offset: {idx} ({hex(idx)})")
    kernel_padded = data[64:idx]
    rootfs_data = data[idx:]

    with open("kernel_padded.bin", "wb") as f:
        f.write(kernel_padded)
    with open("rootfs.squashfs", "wb") as f:
        f.write(rootfs_data)

    # Unpack SquashFS
    if os.path.exists("squashfs-root"):
        shutil.rmtree("squashfs-root")
    print("[*] Unpacking rootfs with unsquashfs...")
    subprocess.run(["unsquashfs", "rootfs.squashfs"], check=True)

    # Inject Dual-WAN Web UI
    print("[*] Injecting Dual-WAN web pages & scripts into squashfs-root...")
    www_dir = "squashfs-root/www"
    os.makedirs(www_dir, exist_ok=True)
    shutil.copy("custom/web/Advanced_DualWAN_Content.asp", os.path.join(www_dir, "Advanced_DualWAN_Content.asp"))

    # Copy daemon script
    os.makedirs("squashfs-root/usr/bin", exist_ok=True)
    shutil.copy("custom/scripts/dualwan_ctl.sh", "squashfs-root/usr/bin/dualwan_ctl.sh")
    os.chmod("squashfs-root/usr/bin/dualwan_ctl.sh", 0o755)

    # Patch state.js for WAN tab and left menu
    state_js = os.path.join(www_dir, "state.js")
    if os.path.exists(state_js):
        print("[*] Patching state.js...")
        with open(state_js, "r", encoding="utf-8", errors="ignore") as f:
            content = f.read()
        
        # Add Dual-WAN to tablink[3] (WAN sub-tabs)
        if "Advanced_DualWAN_Content.asp" not in content:
            content = content.replace(
                '"Advanced_WAN_Content.asp",',
                '"Advanced_WAN_Content.asp", "Advanced_DualWAN_Content.asp",'
            )
            content = content.replace(
                '"<#menu5_3_1#>",',
                '"<#menu5_3_1#>", "【双WAN拓扑聚合】",'
            )
            # Add to menuL2 if not already there
            content = content.replace(
                'menuL2_title = new Array(',
                'menuL2_title = new Array(\n  "双WAN多线拓扑",\n  '
            )
            content = content.replace(
                'menuL2_link  = new Array(',
                'menuL2_link  = new Array(\n  "Advanced_DualWAN_Content.asp",\n  '
            )
            with open(state_js, "w", encoding="utf-8") as f:
                f.write(content)

    # Patch Advanced_WAN_Content.asp to add direct link banner
    wan_asp = os.path.join(www_dir, "Advanced_WAN_Content.asp")
    if os.path.exists(wan_asp):
        print("[*] Patching Advanced_WAN_Content.asp with navigation card...")
        with open(wan_asp, "r", encoding="utf-8", errors="ignore") as f:
            wan_content = f.read()
        banner = '''
<div style="margin: 15px 0; padding: 14px 20px; background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%); border-radius: 8px; color: #fff; box-shadow: 0 4px 12px rgba(0,0,0,0.2);">
    <div style="font-size: 16px; font-weight: bold; margin-bottom: 6px;">🚀 Newifi D2 专属：双WAN多线聚合 & 硬件端口穿透控制台</div>
    <div style="font-size: 13px; opacity: 0.9; margin-bottom: 10px;">支持图形化拖拽连线定义物理 WAN2、L4 ECMP 1+1 聚合与硬件 NAT 穿透。</div>
    <a href="Advanced_DualWAN_Content.asp" class="btn btn-primary" style="background:#00c6ff; color:#000; font-weight:bold; padding:8px 20px; border-radius:4px; text-decoration:none; display:inline-block;">⚡ 立即进入【双WAN拓扑控制台】</a>
</div>
'''
        if "Advanced_DualWAN_Content.asp" not in wan_content:
            import re
            wan_content = re.sub(r'(<body[^>]*>)', r'\1' + banner, wan_content, count=1)
            with open(wan_asp, "w", encoding="utf-8") as f:
                f.write(wan_content)

    # Repack SquashFS
    print("[*] Repacking SquashFS with mksquashfs...")
    if os.path.exists("new_rootfs.squashfs"):
        os.remove("new_rootfs.squashfs")
    cmd = [
        "mksquashfs", "squashfs-root", "new_rootfs.squashfs",
        "-comp", "xz", "-b", "131072", "-no-xattrs", "-nopad", "-no-exports"
    ]
    subprocess.run(cmd, check=True)

    with open("new_rootfs.squashfs", "rb") as f:
        new_rootfs_data = f.read()

    # Padded kernel + new compressed rootfs
    new_payload = kernel_padded + new_rootfs_data
    payload_size = len(new_payload)
    print(f"[*] New payload size: {payload_size} bytes (Kernel: {len(kernel_padded)}, RootFS: {len(new_rootfs_data)})")

    # Calculate Data CRC32
    new_dcrc = zlib.crc32(new_payload) & 0xffffffff

    # Generate new uImage header
    # Header format: >IIIIIIIBBBB32s
    # magic (0x27051956), hcrc (0), time, size, load, ep, dcrc, os, arch, img_type, comp, name
    import time as time_mod
    current_time = int(time_mod.time())
    header_nobytes = struct.pack(
        '>IIIIIIIBBBB32s',
        magic, 0, current_time, payload_size, load, ep, new_dcrc,
        os_type, arch, img_type, comp, name
    )
    new_hcrc = zlib.crc32(header_nobytes) & 0xffffffff
    final_header = struct.pack(
        '>IIIIIIIBBBB32s',
        magic, new_hcrc, current_time, payload_size, load, ep, new_dcrc,
        os_type, arch, img_type, comp, name
    )

    with open(output_file, "wb") as f:
        f.write(final_header + new_payload)

    final_size = os.path.getsize(output_file)
    print(f"[+] Successfully generated firmware: {output_file} ({final_size} bytes)")

if __name__ == "__main__":
    main()
