屏幕驱动来自
https://github.com/lwz322/k3screenctrl/releases/download/0.10-2/k3screenctrl_0.10-2_arm_cortex-a9.ipk

wifi驱动来自
https://github.com/coolsnowwolf/lede/blob/master/package/lean/k3-firmware/files/brcmfmac4366c-pcie.bin
MD5 32e0e8bba5fd958593743e37b095de05


手工执行 或者 编译固件时，在首次启动时运行的脚本（uci-defaults）添加
```bash
sed -i '/^exit 0/i sh -c "$(wget -qO- https://raw.githubusercontent.com/wangzhongwen/phicomm_k3/refs/heads/main/downloadk3driver.sh)"' /etc/rc.local;
chmod u+x /etc/rc.local;
```
