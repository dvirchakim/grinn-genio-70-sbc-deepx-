# genio-flash Recovery - Board Stuck After Erase

## Problem

genio-flash successfully erased the eMMC but is now stuck at "< waiting for any device >"

This happens because after erasing, the board needs to be manually reset into download mode again.

---

## Solution: Manual Reset and Retry

### Step 1: Stop Current genio-flash Process

Press **Ctrl+C** in the genio-flash window to stop it.

### Step 2: Power Cycle the Board

1. **Unplug power** from the board
2. **Wait 5 seconds**
3. **Plug power back in**

### Step 3: Put Board Back in Download Mode

**IMPORTANT:** You must manually enter download mode again:

1. **Unplug power** from board
2. **Hold Volume Down button** (or both volume buttons)
3. While holding button, **plug in power**
4. **Keep holding for 5-10 seconds**
5. Release button

The board should now be in download mode again.

### Step 4: Retry genio-flash

```powershell
cd "C:\Users\dvir\OneDrive - Data JCE Electronics LTD\Desktop\NISKO\vendors\grinn\grinn genio 700 + deepx 3.2.0 rntime\rity-demo-image-grinn-genio-700-sbc-20260325125533"

genio-flash
```

This time it should:
- Detect the board in download mode
- Skip the erase (already done)
- Flash all partitions
- Complete successfully

---

## Alternative: Flash Individual Partitions

If full flash keeps failing, try flashing partitions one at a time:

```powershell
# Flash bootloader components
genio-flash bl2
genio-flash fip
genio-flash lk

# Flash kernel
genio-flash boot

# Flash root filesystem
genio-flash rootfs
```

Between each partition flash, you may need to reset the board back to download mode.

---

## Alternative: Use Fastboot Directly

If the board enters fastboot mode (check with `fastboot devices`), you can flash directly:

```powershell
fastboot devices  # Check if board is detected

# If detected, flash partitions:
fastboot flash bl2 bl2.img
fastboot flash fip fip.bin
fastboot flash lk lk.bin
fastboot flash boot fitImage
fastboot flash rootfs rity-demo-image-grinn-genio-700-sbc.wic.img

fastboot reboot
```

---

## Troubleshooting

### Board Not Entering Download Mode

**Try these button combinations while powering on:**
- Hold **Volume Down** only
- Hold **Volume Up** only  
- Hold **both Volume buttons**
- Hold **Volume Down + Power button**

### USB Connection Issues

- Try different USB port (prefer USB 2.0)
- Try different USB cable (must be data cable, not charge-only)
- Check Device Manager for COM port (should show as COM7 or similar)

### genio-flash Hangs Again

If it hangs again at "waiting for any device":
1. The board may have rebooted out of download mode
2. You need to manually reset it back to download mode
3. This is normal behavior - the board doesn't automatically stay in download mode

---

## Expected Behavior

**Normal genio-flash sequence:**
1. Detects board in download mode ✅
2. Sends bootstrap ✅
3. Erases eMMC ✅
4. **Board may reboot here** ⚠️
5. Waits for device (this is where it's stuck) ❌
6. **Manual intervention needed:** Put board back in download mode
7. Flashes all partitions
8. Completes

---

## Quick Recovery Commands

```powershell
# 1. Stop genio-flash (Ctrl+C)

# 2. Power cycle board

# 3. Put board in download mode (hold volume down + power on)

# 4. Retry flash
cd "C:\Users\dvir\OneDrive - Data JCE Electronics LTD\Desktop\NISKO\vendors\grinn\grinn genio 700 + deepx 3.2.0 rntime\rity-demo-image-grinn-genio-700-sbc-20260325125533"
genio-flash
```

---

## Success Indicators

When flash completes successfully, you'll see:
- All partitions flashed
- "Flash complete" or similar message
- No errors

Then:
1. Power cycle board normally (no download mode)
2. Wait 1-2 minutes for boot
3. Test: `ping 192.168.50.31`
4. SSH: `ssh root@192.168.50.31`
5. Verify DeepX: `python3 -c "import dxrt"`

---

**Current Status:** Board erased, needs to be put back in download mode to continue flashing.
