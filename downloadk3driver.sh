#!/bin/sh

# ====================== config ======================
K3SCREEN_IPK="/tmp/k3screenctrl.ipk";
K3SCREEN_URL="https://raw.githubusercontent.com/wangzhongwen/phicomm_k3/refs/heads/main/k3screenctrl_0.10-2_arm_cortex-a9.ipk";

# WiFi
TARGET="/lib/firmware/brcm/brcmfmac4366c-pcie.bin";
MD5="32e0e8bba5fd958593743e37b095de05";
TMP_FILE="/tmp/brcmfmac4366c-pcie.bin";
FIRMWARE_URL="https://raw.githubusercontent.com/wangzhongwen/phicomm_k3/refs/heads/main/brcmfmac4366c-pcie.bin.32e0e8bba5fd958593743e37b095de05";
# ===================================================

# success flag
success_k3screen=0;
success_firmware=0;

# ====================== tast1 install k3screenctrl ======================
if [ ! -f "/etc/init.d/k3screenctrl" ]; then
    echo "download k3screenctrl...";
    wget -q --timeout=10 -O "$K3SCREEN_IPK" "$K3SCREEN_URL";

    if [ -f "$K3SCREEN_IPK" ]; then
        opkg install "$K3SCREEN_IPK" >/dev/null 2>&1;
        /etc/init.d/k3screenctrl enable >/dev/null 2>&1;

        # update port.sh
        cat > /lib/k3screenctrl/port.sh <<'EOF'
#!/bin/sh

# https://github.com/lwz322/k3screenctrl/blob/master/lib/k3screenctrl/port.sh
 

print_eth_port_status() {
    local port=$1
    
    # One `swconfig dev switch0 show` wastes more time than 4 `port show`
    if [ -n "`ip link show | grep $port@eth0 | grep 'state UP'`" ]; then
        echo 1
    else
        echo 0
    fi
}

print_usb_port_status() {
    if [ "`ls -1 /sys/bus/usb/devices | wc -l`" -gt 8 ]; then
        echo 1
    else
        echo 0
    fi
}

print_eth_port_status lan2 # lan2@eth0 is LAN1 on label
print_eth_port_status lan1 # lan1@eth0 is LAN2 on label
print_eth_port_status lan3 # lan3@eth0 is LAN3 on label
print_eth_port_status wan # WAN
print_usb_port_status
EOF
        chmod +x /lib/k3screenctrl/port.sh;
        success_k3screen=1;
        rm -f "$K3SCREEN_IPK";
        echo "k3screenctrl install success";
    else
        echo "k3screenctrl install failed";
    fi
else
    success_k3screen=1;
    echo "k3screenctrl already exist";
fi

# ====================== task2：update WiFi Driver ======================
current_md5=$(md5sum "$TARGET" 2>/dev/null | awk '{print $1}');
if [ "$current_md5" != "$MD5" ]; then
    echo "download wifi driver...";
    if wget -q --timeout=10 -O "$TMP_FILE" "$FIRMWARE_URL"; then
        dl_md5=$(md5sum "$TMP_FILE" | awk '{print $1}');
        if [ "$dl_md5" = "$MD5" ]; then
            [ ! -f "${TARGET}.ori" ] && mv -f "$TARGET" "${TARGET}.ori";
            cp -f "$TMP_FILE" "$TARGET";
            success_firmware=1;
            echo "update wifi success";
        else
            echo "update wifi failed, md5 $dl_md5 incorrect";
        fi
        rm -f "$TMP_FILE";
    else
        echo "download wifi driver error";
    fi
else
    success_firmware=1;
    echo "wifi driver already exist";
fi

if [ "$success_k3screen" = "1" ] && [ "$success_firmware" = "1" ]; then
    sed -i '/^\/root\/downloadk3driver.sh/d' /etc/rc.local;
    echo "Removed, it will not run again on next boot!";
else
    echo "Some tasks are incomplete, auto-start on boot is retained";
fi
