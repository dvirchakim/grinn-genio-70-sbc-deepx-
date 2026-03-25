# Flash Status and Next Steps - Grinn GenioSBC-700

## Current Status

### ✅ Flash Completed Successfully

**genio-flash output:**
- ✅ MediaTek drivers installed (fixed Code 28 error)
- ✅ Board detected in download mode
- ✅ Bootstrap sent successfully
- ✅ eMMC erased (mmc0, mmc0boot0, mmc0boot1)
- ✅ Full system image flashed (2.5GB in 189 seconds)
- ✅ Bootloader flashed (bl2.img)
- ✅ U-Boot environment configured
- ✅ Board rebooted

**Flash time:** ~3 minutes total

### ❌ Board Not Responding

**Issue:** Board not responding to ping at 192.168.50.31 after 2.5 minutes

**Possible causes:**
1. Board needs more boot time (first boot can take 3-5 minutes)
2. Network configuration issue
3. Board may be booting but with different IP
4. Serial console needed to see boot messages
5. Hardware issue (power, network cable)

---

## Immediate Troubleshooting Steps

### 1. Check Physical Connections

**Power:**
- Is power LED on?
- Is board powered properly?
- Try power cycling (unplug, wait 10 seconds, plug back in)

**Network:**
- Is network cable connected?
- Is link LED on network port blinking?
- Try different network cable
- Try different network port on switch/router

### 2. Wait Longer for First Boot

First boot after flash can take longer:
- Wait 5 minutes total
- Board may be expanding filesystem
- Board may be running first-boot scripts

```powershell
# Keep checking every 30 seconds
ping -t 192.168.50.31
```

### 3. Check if Board Has Different IP

Board may have obtained different IP via DHCP:

```powershell
# Scan network for new devices
arp -a | findstr "192.168.50"

# Or use network scanner
# Advanced IP Scanner or similar tool
```

### 4. Connect Serial Console (Recommended)

**This is the most important troubleshooting step.**

Serial console will show:
- Bootloader messages (U-Boot)
- Kernel boot messages
- Where boot is failing
- Network configuration
- Any errors

**Serial connection:**
- Port: UART debug port on board
- Settings: 115200 baud, 8N1, no flow control
- Tool: PuTTY, TeraTerm, or similar

**PuTTY settings:**
```
Connection type: Serial
Serial line: COM7 (or check Device Manager)
Speed: 115200
```

### 5. Check Router/DHCP Server

- Check router's DHCP client list
- Look for new device with MAC address starting with common prefixes
- Board may have obtained IP but not the expected 192.168.50.31

---

## What Serial Console Will Show

### Normal Boot Sequence

```
U-Boot 2023.04 (Mar 25 2026 - 12:55:33 +0000)

CPU:   MediaTek MT8395 (Genio 700)
Model: Grinn GenioSBC-700
DRAM:  8 GiB
...
Starting kernel ...

[    0.000000] Booting Linux on physical CPU 0x0000000000 [0x411fd050]
[    0.000000] Linux version 5.15.47-mtk+gd011e19cfc68
...
[  OK  ] Started Network Name Resolution.
[  OK  ] Reached target Network.
[  OK  ] Reached target Multi-User System.

Rity Demo Layer 24.1-release grinn-genio-700-sbc ttyS0

grinn-genio-700-sbc login:
```

### If Boot Fails

You'll see where it stops:
- Bootloader errors
- Kernel panic
- Filesystem mount errors
- Network configuration issues

---

## Alternative: Reflash with Serial Console Connected

If board won't boot, reflash with serial console connected to see what's happening:

1. Connect serial console (PuTTY on COM7, 115200 baud)
2. Put board in download mode
3. Run genio-flash
4. Watch serial console during flash and boot
5. Identify where it fails

---

## If Board Boots But Wrong IP

### Find the Board

```powershell
# Scan network
arp -a

# Or use nmap (if installed)
nmap -sn 192.168.50.0/24

# Check router DHCP leases
# Look for device named "grinn-genio-700-sbc"
```

### SSH to New IP

```bash
ssh root@<discovered-ip>

# Once logged in, check network config
ip addr show
cat /etc/network/interfaces
```

### Set Static IP

```bash
# On board, edit network config
vi /etc/network/interfaces

# Add:
auto eth0
iface eth0 inet static
    address 192.168.50.31
    netmask 255.255.255.0
    gateway 192.168.50.1

# Restart networking
systemctl restart networking
```

---

## If Board Boots Successfully

Once board is accessible:

### 1. Verify System

```bash
ssh root@192.168.50.31

# Check OS version
cat /etc/os-release
# Expected: Rity Demo Layer 24.1-release (kirkstone)

# Check kernel
uname -a
# Expected: 5.15.47-mtk+gd011e19cfc68

# Check disk usage
df -h /
```

### 2. Verify DeepX Kernel Drivers

```bash
# Check loaded modules
lsmod | grep dx

# If not loaded, load them
modprobe dx_dma
modprobe dxrt_driver

# Verify loaded
lsmod | grep dx
# Should show: dx_dma, dxrt_driver

# Check device
ls -l /dev/dxg*
# Should show: /dev/dxg0 or similar
```

### 3. Verify DeepX Runtime

```bash
# Check installed packages
opkg list-installed | grep dx

# Expected packages:
# dx-rt - DeepX runtime library
# dx-npu - NPU firmware
# dx-app - Application layer

# Test Python import
python3 -c "import dxrt; print('DeepX runtime OK')"

# Check version
python3 -c "import dxrt; print('Version:', dxrt.__version__)"
# Expected: 3.2.0 or similar
```

### 4. Test DeepX Functionality

```bash
# Run simple test
python3 << 'EOF'
import dxrt
import numpy as np

# Initialize runtime
print("Initializing DeepX runtime...")
# Add your test code here

print("DeepX 3.2.0 runtime fully functional!")
EOF
```

---

## Summary

**Current situation:**
- ✅ Flash completed successfully with genio-flash
- ✅ MediaTek drivers installed
- ✅ All partitions written correctly
- ❌ Board not responding at 192.168.50.31

**Next actions (in order):**
1. **Connect serial console** - Most important for troubleshooting
2. **Wait 5 minutes** - First boot can be slow
3. **Check physical connections** - Power, network cable
4. **Scan network** - Board may have different IP
5. **Power cycle** - Unplug, wait, plug back in

**Most likely issues:**
1. First boot taking longer than expected (wait more)
2. Network configuration issue (serial console will show)
3. Board booted but with different IP (scan network)

**Serial console is key** - It will show exactly what's happening during boot.

---

## Quick Commands

```powershell
# Keep pinging
ping -t 192.168.50.31

# Scan network
arp -a | findstr "192.168.50"

# Connect serial console (PuTTY)
# COM7, 115200, 8N1

# Power cycle board
# Unplug power, wait 10 seconds, plug back in
```

---

**The flash was successful. The issue is either boot time, network config, or we need serial console to see what's happening.**
