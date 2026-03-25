# Board Recovery Guide - Grinn GenioSBC-700

## Current Situation

Board is not booting after flashing vendor image. Network unreachable.

**Symptoms:**
- Board powered on but not responding to ping
- SSH not accessible
- Binary execution errors observed before final reboot

**Likely Causes:**
1. Vendor image may require special flashing procedure (genio-flash tool)
2. Image may be for different board variant
3. Flash process may have been interrupted or corrupted
4. Bootloader may need separate update

---

## Recovery Methods

### Method 1: Serial Console Diagnosis (First Step)

**Required:** USB-to-serial adapter connected to board's debug UART

**Steps:**
1. Connect serial console (115200 8N1)
2. Power cycle board
3. Watch boot messages
4. Identify where boot fails

**Common serial console tools:**
- Windows: PuTTY, TeraTerm
- Linux: minicom, screen

**Connection:**
```
Baud: 115200
Data bits: 8
Parity: None
Stop bits: 1
Flow control: None
```

**What to look for:**
- U-Boot messages (bootloader)
- Kernel boot messages
- Error messages about missing files or partitions
- Filesystem mount errors

---

### Method 2: SD Card Recovery Boot

Create bootable SD card to recover board access.

#### Option A: Use Original Working Image

If you have a backup of the working image from before the flash:

```bash
# Write to SD card
sudo dd if=original-working-image.wic of=/dev/sdX bs=4M status=progress
sync
```

#### Option B: Use Vendor Image on SD Card

Try the vendor image on SD card instead of eMMC:

```bash
# From WSL
cd "/mnt/c/Users/dvir/OneDrive - Data JCE Electronics LTD/Desktop/NISKO/vendors/grinn/grinn genio 700 + deepx 3.2.0 rntime/rity-demo-image-grinn-genio-700-sbc-20260325125533"

# Write to SD card (replace /dev/sdX with your SD card)
sudo dd if=rity-demo-image-grinn-genio-700-sbc.wic.img of=/dev/sdX bs=4M status=progress conv=fsync
sync
```

**Then:**
1. Insert SD card into board
2. Power on board
3. Board should boot from SD card
4. Once booted, you can reflash eMMC properly

---

### Method 3: Use genio-flash Tool (Proper Method)

The vendor image includes a `rity.json` configuration file, suggesting it should be flashed using the `genio-flash` tool, not raw dd.

#### Install genio-flash

```bash
# Install genio-tools
pip3 install genio-tools
```

#### Flash with genio-flash

```bash
cd "/mnt/c/Users/dvir/OneDrive - Data JCE Electronics LTD/Desktop/NISKO/vendors/grinn/grinn genio 700 + deepx 3.2.0 rntime/rity-demo-image-grinn-genio-700-sbc-20260325125533"

# Put board in fastboot mode (usually via serial console or hardware button)
# Then flash:
genio-flash --config rity.json
```

**This is likely the correct method for this vendor image.**

---

### Method 4: Fastboot Recovery

If board enters fastboot mode:

```bash
# Check if board is in fastboot
fastboot devices

# If detected, you can flash partitions individually
fastboot flash boot boot.img
fastboot flash system system.img
# etc.
```

---

## Immediate Actions

### 1. Check Serial Console

**Most Important:** Connect serial console to see boot messages.

**Serial port location on Grinn GenioSBC-700:**
- Usually a 3-pin or 4-pin header labeled "UART" or "DEBUG"
- Pinout: GND, TX, RX (and sometimes VCC - don't connect)

### 2. Try SD Card Boot

While waiting for serial access:

1. Write vendor image to SD card
2. Insert SD card
3. Power on board
4. See if it boots from SD

### 3. Check Hardware

- Power LED on?
- Any other LEDs blinking?
- Try power cycling (unplug, wait 10 seconds, plug back in)

---

## If Board Boots from SD Card

Once you have access via SD card boot:

### Examine eMMC

```bash
# Check eMMC partitions
lsblk /dev/mmcblk0

# Check if bootloader is intact
dd if=/dev/mmcblk0 bs=512 count=1 | hexdump -C | head

# Mount and check filesystems
mkdir -p /mnt/emmc
mount /dev/mmcblk0p2 /mnt/emmc
ls /mnt/emmc
```

### Reflash eMMC Properly

```bash
# From SD card boot, flash eMMC correctly
dd if=/dev/mmcblk1 of=/dev/mmcblk0 bs=4M status=progress conv=fsync
sync

# Or use genio-flash if available
genio-flash --config /path/to/rity.json --device /dev/mmcblk0
```

---

## Alternative: Revert to Previous Working State

If you have the previous working kernel drivers but no runtime:

### Option A: Build DeepX Runtime Packages Only

Instead of full image, just build the runtime packages:

```bash
# On build PC or in Yocto environment
bitbake dx-rt dx-npu dx-app
```

This gives you the `.ipk` packages to install on the working board.

### Option B: Use Pre-built Runtime Packages

If vendor provides separate runtime packages (not full image):
- Look for `.ipk` or `.deb` packages
- Install on working board with `opkg install` or `dpkg -i`

---

## Root Cause Analysis

**Why the flash likely failed:**

1. **Wrong flashing method:** Vendor image may require `genio-flash` tool, not raw `dd`
2. **Partition layout mismatch:** Image may have different partition scheme than current eMMC
3. **Bootloader not updated:** Image may require bootloader update first
4. **Image architecture:** Image may be for different board variant

**Evidence:**
- Binary execution errors before reboot suggest wrong architecture or corrupted binaries
- `rity.json` file in image suggests genio-flash is the intended method
- `.aiotflash.tar.xz` extension suggests special flashing procedure

---

## Next Steps - Priority Order

1. **Connect serial console** - See what's happening during boot
2. **Try SD card boot** - Get board accessible again
3. **Use genio-flash tool** - Flash image properly
4. **Contact vendor** - Ask for proper flashing procedure

---

## Prevention for Next Time

Before flashing:
1. ✅ Check vendor documentation for flashing procedure
2. ✅ Look for special tools required (genio-flash, fastboot, etc.)
3. ✅ Test image on SD card first
4. ✅ Have serial console connected to monitor boot
5. ✅ Keep backup of working image

---

## Contact Information

**Vendor:** Grinn
**Board:** GenioSBC-700
**Image:** rity-demo-image with DeepX 3.2.0
**Support:** Check Grinn documentation or contact support for proper flashing procedure

---

**Current Status:** Board not booting, needs serial console access or SD card recovery to proceed.
