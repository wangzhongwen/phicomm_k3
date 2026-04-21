#!/bin/sh

# ====================== Configuration ======================
K3SCREEN_IPK="/tmp/k3screenctrl.ipk";
K3SCREEN_URL="https://raw.githubusercontent.com/wangzhongwen/phicomm_k3/refs/heads/main/k3screenctrl_0.10-2_arm_cortex-a9.ipk";

# WiFi firmware configuration
TARGET="/lib/firmware/brcm/brcmfmac4366c-pcie.bin";
MD5="32e0e8bba5fd958593743e37b095de05";
TMP_FILE="/tmp/brcmfmac4366c-pcie.bin";
FIRMWARE_URL="https://raw.githubusercontent.com/wangzhongwen/phicomm_k3/refs/heads/main/brcmfmac4366c-pcie.bin.32e0e8bba5fd958593743e37b095de05";
# ===========================================================

# Success status flags
success_k3screen=0;
success_firmware=0;

# ====================== Task 1: Install k3screenctrl ======================
if [ ! -f "/etc/init.d/k3screenctrl" ]; then
    # Update opkg package repository
    if opkg update >/dev/null 2>&1; then
        echo "opkg update succeeded"
    else
        echo "opkg update failed"
    fi
    
    echo "Downloading k3screenctrl...";
    wget -q --timeout=10 -O "$K3SCREEN_IPK" "$K3SCREEN_URL";

    if [ -f "$K3SCREEN_IPK" ]; then
        if opkg install "$K3SCREEN_IPK" >/dev/null 2>&1; then
          # Enable k3screenctrl auto-start
          /etc/init.d/k3screenctrl enable >/dev/null 2>&1;

          # Update port status detection script
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
          # Make port script executable
          chmod +x /lib/k3screenctrl/port.sh;
          success_k3screen=1;
          # Clean up downloaded package
          rm -f "$K3SCREEN_IPK";
          echo "k3screenctrl installed successfully";
        else
          echo "k3screenctrl installation failed";
        fi
    else
        echo "k3screenctrl installation failed (package download failed)";
    fi
else
    success_k3screen=1;
    echo "k3screenctrl already installed, skipping";
fi

# ====================== Task 2: Update WiFi Driver ======================
# Calculate current firmware MD5 checksum
current_md5=$(md5sum "$TARGET" 2>/dev/null | awk '{print $1}');

# Check if firmware needs update
if [ "$current_md5" != "$MD5" ]; then
    echo "Downloading WiFi driver...";
    if wget -q --timeout=10 -O "$TMP_FILE" "$FIRMWARE_URL"; then
        # Verify downloaded firmware integrity
        dl_md5=$(md5sum "$TMP_FILE" | awk '{print $1}');
        if [ "$dl_md5" = "$MD5" ]; then
            # Backup original firmware (only once)
            [ ! -f "${TARGET}.ori" ] && mv -f "$TARGET" "${TARGET}.ori";
            # Replace with new firmware
            cp -f "$TMP_FILE" "$TARGET";
            success_firmware=1;
            echo "WiFi driver updated successfully";
        else
            echo "WiFi driver update failed: incorrect MD5 ($dl_md5)";
        fi
        # Clean up temporary file
        rm -f "$TMP_FILE";
    else
        echo "WiFi driver download failed";
    fi
else
    success_firmware=1;
    echo "WiFi driver is already up to date, skipping";
fi

# ====================== Auto-start Cleanup ======================
# Remove script from rc.local if all tasks succeeded
if [ "$success_k3screen" = "1" ] && [ "$success_firmware" = "1" ]; then
    sed -i '/downloadk3driver.sh/d' /etc/rc.local;
    echo "Auto-start entry removed: script will not run on next boot!";
else
    echo "Some tasks incomplete: retaining auto-start on boot";
fi
