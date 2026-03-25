# Install MediaTek USB VCOM Drivers for Genio 700

## Problem

Device Manager shows "Yocto" device with error:
- **"The drivers for this device are not installed. (Code 28)"**
- **"There are no compatible drivers for this device."**

This prevents genio-flash from communicating with the board after bootstrap.

---

## Solution: Install MediaTek USB VCOM Drivers

### Method 1: Download Official MediaTek Drivers

**Download Link:** https://developer.mediatek.com/resources/tool/usb-driver

Or search for: **"MediaTek USB VCOM drivers download"**

**Steps:**
1. Download MediaTek USB VCOM driver package
2. Extract the ZIP file
3. Run the installer as Administrator
4. Follow installation wizard
5. Restart computer if prompted

### Method 2: Manual Driver Installation via Device Manager

If you have the driver files:

1. Open **Device Manager**
2. Find **"Yocto"** under **"Other devices"** (with yellow warning)
3. Right-click → **"Update driver"**
4. Choose **"Browse my computer for drivers"**
5. Navigate to extracted MediaTek driver folder
6. Check **"Include subfolders"**
7. Click **"Next"** and let Windows install
8. Restart if prompted

### Method 3: Use Windows Update

Sometimes Windows Update has the drivers:

1. Right-click **"Yocto"** device
2. Choose **"Update driver"**
3. Select **"Search automatically for drivers"**
4. Wait for Windows to find and install drivers
5. Restart if needed

---

## Alternative: Install Android SDK Platform Tools

The Android SDK Platform Tools include MediaTek drivers:

1. Download: https://developer.android.com/studio/releases/platform-tools
2. Extract to `C:\platform-tools\`
3. Add to PATH environment variable
4. Restart computer
5. Reconnect board

---

## Verify Driver Installation

After installing drivers:

### 1. Check Device Manager

The "Yocto" device should now show as:
- **"MediaTek PreLoader USB VCOM Port"** or
- **"MediaTek USB Port"** or
- **"Android ADB Interface"**

No yellow warning icon should be present.

### 2. Test Fastboot Connection

```powershell
fastboot devices
```

If the board is in fastboot mode, it should show a device ID.

### 3. Retry genio-flash

```powershell
cd "C:\Users\dvir\OneDrive - Data JCE Electronics LTD\Desktop\NISKO\vendors\grinn\grinn genio 700 + deepx 3.2.0 rntime\rity-demo-image-grinn-genio-700-sbc-20260325125533"

genio-flash
```

This time it should:
- Detect board after bootstrap
- Not get stuck at "waiting for any device"
- Flash all partitions successfully

---

## Common Driver Package Names

Look for these driver packages:
- **MediaTek USB VCOM Drivers**
- **MediaTek Preloader USB VCOM Drivers**
- **MTK USB All Drivers**
- **SP Flash Tool** (includes drivers)

---

## If Drivers Still Don't Install

### Option 1: Disable Driver Signature Enforcement

Windows may block unsigned drivers:

1. Hold **Shift** and click **Restart**
2. Choose **Troubleshoot** → **Advanced options** → **Startup Settings**
3. Click **Restart**
4. Press **F7** for "Disable driver signature enforcement"
5. Install MediaTek drivers
6. Restart normally

### Option 2: Use SP Flash Tool

SP Flash Tool includes MediaTek drivers and installs them automatically:

1. Download **SP Flash Tool** from MediaTek
2. Extract and run `flash_tool.exe`
3. Drivers will auto-install when you connect the board
4. You don't need to use SP Flash Tool for flashing - just use it to install drivers
5. Then use genio-flash as normal

---

## After Driver Installation

Once drivers are installed:

1. **Power cycle the board**
2. **Put board in download mode** (hold volume button + power on)
3. **Run genio-flash** - it should now work without getting stuck
4. **Flash will complete** in 5-10 minutes
5. **Power cycle normally** and board should boot with DeepX 3.2.0

---

## Quick Links

- **MediaTek Developer Portal:** https://developer.mediatek.com/
- **Android Platform Tools:** https://developer.android.com/studio/releases/platform-tools
- **SP Flash Tool:** Search "SP Flash Tool MediaTek download"

---

**Current Issue:** Missing MediaTek USB VCOM drivers causing genio-flash to hang at "waiting for any device"

**Solution:** Install MediaTek USB VCOM drivers, then retry genio-flash
