# Flash Vendor Image Guide - Grinn GenioSBC-700 with DeepX 3.2.0

## Image Information

**Image Location:** `C:\Users\dvir\OneDrive - Data JCE Electronics LTD\Desktop\NISKO\vendors\grinn\grinn genio 700 + deepx 3.2.0 rntime`

**Image Details:**
- **Name:** rity-demo-image-grinn-genio-700-sbc
- **Build Date:** March 25, 2026 (12:55:33)
- **Size:** 2.5GB (uncompressed)
- **DeepX Version:** 3.2.0 runtime included
- **Yocto Release:** Kirkstone 24.1
- **Kernel:** 5.15.47-mtk

**Board:**
- **Model:** Grinn GenioSBC-700
- **IP:** 192.168.50.31
- **User:** root (no password)

---

## Pre-Flash Checklist

✅ Board is powered on and accessible via SSH
✅ Network connection is stable
✅ Image file extracted (2.5GB .wic.img file)
✅ Backup any important data from board (if needed)

---

## Flashing Methods

### Method 1: Flash via Network (Recommended)

This method flashes the image directly over SSH without removing the board.

#### Step 1: Verify Board Connectivity

```bash
ssh root@192.168.50.31 "uname -a"
```

Expected output: `Linux grinn-genio-700-sbc 5.15.47-mtk...`

#### Step 2: Transfer Image to Board

```bash
# From WSL
cd "/mnt/c/Users/dvir/OneDrive - Data JCE Electronics LTD/Desktop/NISKO/vendors/grinn/grinn genio 700 + deepx 3.2.0 rntime/rity-demo-image-grinn-genio-700-sbc-20260325125533"

scp rity-demo-image-grinn-genio-700-sbc.wic.img root@192.168.50.31:/tmp/
```

**Note:** This will take 5-10 minutes for 2.5GB transfer.

#### Step 3: Identify eMMC Device on Board

```bash
ssh root@192.168.50.31

# Find eMMC device
lsblk -d -n -o NAME,TYPE,SIZE | grep disk
```

Expected output:
```
mmcblk0  disk  14.6G   # This is the eMMC
```

The device will be `/dev/mmcblk0`

#### Step 4: Flash Image to eMMC

**⚠️ WARNING: This will ERASE all data on the board!**

```bash
# On the board (via SSH)
ssh root@192.168.50.31

# Unmount any mounted partitions
umount /dev/mmcblk0* 2>/dev/null || true

# Flash the image
dd if=/tmp/rity-demo-image-grinn-genio-700-sbc.wic.img of=/dev/mmcblk0 bs=4M status=progress conv=fsync

# Sync to ensure all data is written
sync

# Clean up
rm /tmp/rity-demo-image-grinn-genio-700-sbc.wic.img

# Reboot
reboot
```

#### Step 5: Wait for Reboot

Wait 1-2 minutes for the board to boot with the new image.

#### Step 6: Verify New Image

```bash
# SSH to board
ssh root@192.168.50.31

# Check OS version
cat /etc/os-release

# Check kernel
uname -a

# Check DeepX kernel modules
lsmod | grep dx

# Check DeepX device
ls -l /dev/dxg*

# Test DeepX runtime
python3 -c "import dxrt; print('DeepX runtime version:', dxrt.__version__)"
```

---

### Method 2: Flash via SD Card (Alternative)

If network flashing fails, you can flash via SD card.

#### Step 1: Write Image to SD Card

```bash
# From WSL
cd "/mnt/c/Users/dvir/OneDrive - Data JCE Electronics LTD/Desktop/NISKO/vendors/grinn/grinn genio 700 + deepx 3.2.0 rntime/rity-demo-image-grinn-genio-700-sbc-20260325125533"

# Write to SD card (replace /dev/sdX with your SD card device)
sudo dd if=rity-demo-image-grinn-genio-700-sbc.wic.img of=/dev/sdX bs=4M status=progress conv=fsync
sync
```

#### Step 2: Boot from SD Card

1. Insert SD card into board
2. Power on board
3. Board should boot from SD card

#### Step 3: Copy to eMMC (Optional)

Once booted from SD card, you can copy the image to eMMC:

```bash
# On board (booted from SD card)
dd if=/dev/mmcblk1 of=/dev/mmcblk0 bs=4M status=progress conv=fsync
sync
reboot
```

---

### Method 3: Using genio-flash Tool (If Available)

The image includes a `rity.json` configuration for the genio-flash tool.

```bash
# From WSL
cd "/mnt/c/Users/dvir/OneDrive - Data JCE Electronics LTD/Desktop/NISKO/vendors/grinn/grinn genio 700 + deepx 3.2.0 rntime/rity-demo-image-grinn-genio-700-sbc-20260325125533"

# If genio-flash is installed
genio-flash --config rity.json
```

---

## Post-Flash Verification

### 1. Check System Information

```bash
ssh root@192.168.50.31

# OS version
cat /etc/os-release
# Expected: Rity Demo Layer 24.1-release (kirkstone)

# Kernel version
uname -r
# Expected: 5.15.47-mtk+gd011e19cfc68

# Disk usage
df -h /
```

### 2. Verify DeepX Kernel Drivers

```bash
# Check loaded modules
lsmod | grep dx

# Expected output:
# dxrt_driver
# dx_dma
```

If not loaded, load manually:
```bash
modprobe dx_dma
modprobe dxrt_driver
```

### 3. Verify DeepX Device

```bash
ls -l /dev/dxg*

# Expected: /dev/dxg0 or similar
```

### 4. Verify DeepX Runtime

```bash
# Check if dx-rt is installed
opkg list-installed | grep dx

# Test Python import
python3 -c "import dxrt; print('DeepX runtime OK')"

# Check version
python3 -c "import dxrt; print('Version:', dxrt.__version__)"
```

### 5. Check DeepX Firmware

```bash
ls -l /lib/firmware/deepx/
```

---

## Troubleshooting

### Issue: Cannot SSH to Board After Flash

**Solution:**
1. Wait 2-3 minutes for full boot
2. Check network cable connection
3. Power cycle the board
4. Check serial console output (if available)

### Issue: DeepX Modules Not Loaded

**Solution:**
```bash
# Load modules manually
modprobe dx_dma
modprobe dxrt_driver

# Check dmesg for errors
dmesg | grep -i dx

# Make modules load on boot
echo "dx_dma" >> /etc/modules-load.d/deepx.conf
echo "dxrt_driver" >> /etc/modules-load.d/deepx.conf
```

### Issue: DeepX Device Not Present

**Solution:**
```bash
# Check if drivers loaded
lsmod | grep dx

# Check dmesg for driver messages
dmesg | grep -i "deepx\|dxrt\|dx_dma"

# Check device tree
ls /proc/device-tree/ | grep deepx
```

### Issue: Python Cannot Import dxrt

**Solution:**
```bash
# Check if package installed
opkg list-installed | grep dx-rt

# If not installed, check if packages exist
find /usr/lib/python* -name "*dxrt*"

# Reinstall if needed
opkg update
opkg install dx-rt
```

---

## Quick Flash Script

For convenience, use the automated script:

```bash
# From WSL
wsl -d Ubuntu-22.04
bash "/mnt/c/Users/dvir/CascadeProjects/magal grinn/scripts/flash_vendor_image.sh"
```

---

## Comparison: Old vs New Image

### Current Image (Before Flash)
- Yocto: Kirkstone 24.1
- Kernel: 5.15.47-mtk+gd011e19cfc68
- DeepX: Kernel drivers only (dx_dma.ko, dxrt_driver.ko)
- DeepX Runtime: **Not installed** (pending)

### New Image (After Flash)
- Yocto: Kirkstone 24.1
- Kernel: 5.15.47-mtk+gd011e19cfc68 (same)
- DeepX: **Complete stack** (drivers + runtime)
- DeepX Runtime: **3.2.0** (dx-rt, dx-npu, dx-app)

**Advantage:** Complete DeepX 3.2.0 runtime pre-installed, no need for Yocto build!

---

## Safety Notes

⚠️ **IMPORTANT:**
- Flashing will **ERASE ALL DATA** on the board
- Backup any important data before flashing
- Ensure stable power during flash (do not disconnect power)
- Ensure stable network during transfer
- The flash process takes 10-15 minutes total

✅ **Safe to proceed if:**
- Board is a development/test unit
- No critical data on board
- You have stable power and network
- You can recover via SD card if needed

---

## Summary

**Recommended Method:** Network flash (Method 1)

**Steps:**
1. Transfer image to board: `scp rity-demo-image-grinn-genio-700-sbc.wic.img root@192.168.50.31:/tmp/`
2. Flash to eMMC: `dd if=/tmp/rity-demo-image-grinn-genio-700-sbc.wic.img of=/dev/mmcblk0 bs=4M status=progress`
3. Reboot: `reboot`
4. Verify: `python3 -c "import dxrt; print('DeepX OK')"`

**Time:** 15-20 minutes total (10 min transfer + 5 min flash + 2 min boot)

**Result:** Complete working system with DeepX 3.2.0 runtime ready to use!

---

**This vendor image eliminates the need for the 4-8 hour Yocto build. You can have a fully functional DeepX system in under 30 minutes!**
