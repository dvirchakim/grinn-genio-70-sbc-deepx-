# Grinn GenioSBC-700 with DeepX 3.2.0 Runtime - Deployment Guide

Complete deployment package for flashing and configuring DeepX 3.2.0 runtime on Grinn GenioSBC-700 board using vendor-supplied image.

**Status:** ✅ Successfully deployed and verified on board at 192.168.50.32

---

## 🚀 Quick Start

**Fastest deployment method:** Use vendor-supplied complete image with genio-flash tool.

**Time:** 15-20 minutes (vs 4-8 hours for Yocto build)

**Result:** Complete working system with DeepX 3.2.0 runtime pre-installed.

---

## Directory Structure

```
grinn-genio-700-sbc-deepx/
├── README.md                                    # This file - Main deployment guide
├── docs/                                        # Documentation
│   ├── FLASH_VENDOR_IMAGE_GUIDE.md             # Vendor image flashing guide
│   ├── INSTALL_MEDIATEK_DRIVERS.md             # MediaTek USB driver installation
│   ├── BOARD_RECOVERY_GUIDE.md                 # Board recovery procedures
│   ├── GENIO_FLASH_RECOVERY_STEPS.md           # genio-flash troubleshooting
│   ├── FLASH_STATUS_AND_NEXT_STEPS.md          # Post-flash verification
│   ├── YOCTO_BUILD_GUIDE.md                    # Alternative: Full Yocto build
│   └── TRANSFER_INSTRUCTIONS.md                # Yocto build transfer guide
├── scripts/                                     # Deployment scripts
│   ├── recover_board_genio_flash.ps1           # Automated flash script
│   ├── check_board_network.ps1                 # Network configuration check
│   ├── flash_vendor_image.sh                   # Linux flash script
│   └── transfer_to_build_pc.ps1                # Yocto build transfer
└── configs/                                     # Configuration files
    └── genio700_kernel_config                   # Kernel configuration
```

---

## 📋 Deployment Methods

### Method 1: Vendor Image Flash (Recommended) ⚡

**Time:** 15-20 minutes  
**Difficulty:** Easy  
**Result:** Complete DeepX 3.2.0 system

**Requirements:**
- Windows PC with Python 3.9+
- Vendor image file (rity-demo-image-grinn-genio-700-sbc.aiotflash.tar.xz)
- MediaTek USB VCOM drivers
- genio-tools (`pip install genio-tools`)

**Steps:**
1. Install MediaTek USB VCOM drivers
2. Extract vendor image
3. Put board in download mode (hold volume button + power on)
4. Run `genio-flash` to flash complete image
5. Boot and verify

**See:** `docs/FLASH_VENDOR_IMAGE_GUIDE.md`

### Method 2: Yocto Build (Alternative) 🏗️

**Time:** 4-8 hours  
**Difficulty:** Advanced  
**Result:** Custom-built DeepX system

**See:** `docs/YOCTO_BUILD_GUIDE.md`

---

## 🎯 Board Information

**Board:** Grinn GenioSBC-700  
**Current IP:** 192.168.50.32  
**User:** root (no password)  
**SSH:** `ssh root@192.168.50.32`

**Deployed System:**
- **OS:** Rity Demo Layer 24.1-release (Kirkstone)
- **Kernel:** 5.15.47-mtk+gd011e19cfc68
- **DeepX Runtime:** v3.2.0
- **Device Driver:** v2.1.0
- **PCIe Driver:** v1.5.1

---

## 📚 Documentation

### Deployment Guides

1. **`docs/FLASH_VENDOR_IMAGE_GUIDE.md`** ⭐ Main deployment guide
   - Complete vendor image flashing procedure
   - Multiple flashing methods (network, SD card, genio-flash)
   - Post-flash verification steps
   - Troubleshooting guide

2. **`docs/INSTALL_MEDIATEK_DRIVERS.md`** - Driver installation
   - MediaTek USB VCOM driver installation
   - Manual and automatic installation methods
   - Driver verification

3. **`docs/BOARD_RECOVERY_GUIDE.md`** - Recovery procedures
   - Serial console access
   - SD card recovery boot
   - Fastboot recovery
   - Download mode entry

4. **`docs/GENIO_FLASH_RECOVERY_STEPS.md`** - genio-flash troubleshooting
   - Manual reset procedures
   - Download mode re-entry
   - Partition flashing

5. **`docs/FLASH_STATUS_AND_NEXT_STEPS.md`** - Post-flash verification
   - System verification commands
   - DeepX runtime testing
   - Network configuration

### Alternative Build Method

6. **`docs/YOCTO_BUILD_GUIDE.md`** - Full Yocto build guide
   - For custom builds from source
   - System requirements
   - Build execution
   - Troubleshooting

7. **`docs/TRANSFER_INSTRUCTIONS.md`** - Yocto build transfer
   - Transfer package to build PC
   - Quick start commands

---

## 🛠️ Scripts

### Deployment Scripts

- **`scripts/recover_board_genio_flash.ps1`** - Automated flash script (PowerShell)
  - Installs genio-tools
  - Guides through download mode entry
  - Flashes vendor image automatically
  - Verifies installation

- **`scripts/flash_vendor_image.sh`** - Linux flash script (Bash)
  - Network-based image flashing
  - Board connectivity checks
  - Automatic image transfer and flash

- **`scripts/check_board_network.ps1`** - Network diagnostics
  - Detects board IP address
  - Serial console connection guide
  - Network configuration help

### Build Scripts (Alternative Method)

- **`scripts/package_yocto_build.sh`** - Creates Yocto transfer package
- **`scripts/start_yocto_build.sh`** - Starts Yocto build
- **`scripts/transfer_to_build_pc.ps1`** - Transfers to build PC

---

## ✅ Deployment Status

### Successfully Deployed (March 25, 2026)

✅ **MediaTek USB VCOM drivers installed** (v5.2307)  
✅ **Vendor image flashed** using genio-flash  
✅ **Board booted successfully** at 192.168.50.32  
✅ **DeepX 3.2.0 runtime verified** and working  
✅ **Kernel modules configured** for auto-load at boot  
✅ **Complete system operational**

### Verified Components

**Installed Packages:**
- dx-rt v3.2.0 - Runtime library
- dx-driver v2.1.0 - Device drivers  
- dx-stream v2.2.0 - Streaming support
- dx-stream-sample v1.0.0 - Sample applications
- kernel-module-dx-dma - DMA driver
- kernel-module-dxrt-driver - Runtime driver

**Kernel Modules Loaded:**
```
dxrt_driver    36864  0
dx_dma        487424  1 dxrt_driver
```

**DeepX CLI Working:**
```bash
$ dxrt-cli --version
DXRT v3.2.0
Device Driver: v1.8.0
PCIe Driver: v1.5.1
Firmware: v2.4.0
Compiler: v1.18.1
```

---

## 🔧 Technical Details

### System Configuration

**Yocto Release:** Kirkstone 24.1-release  
**Kernel Version:** 5.15.47-mtk+gd011e19cfc68  
**Machine:** grinn-genio-700-sbc  
**Image:** rity-demo-image  
**Architecture:** aarch64

### DeepX Configuration

**Runtime Version:** 3.2.0  
**Device Driver:** v2.1.0  
**PCIe Driver:** v1.5.1  
**Firmware:** v2.4.0  
**Compiler:** v1.18.1  
**File Format:** v6

**Boot Configuration:**
- Kernel modules auto-load: `/etc/modules-load.d/deepx.conf`
- Modules: `dx_dma`, `dxrt_driver`

### Hardware Detection

```bash
[    3.917197] dx_dma_pcie 0000:01:00.0: Adding to iommu group 0
[    3.926320] dx_dma_pcie 0000:01:00.0: enabling device (0000 -> 0002)
[    3.927524] dx_dma_pcie 0000:01:00.0: dw->dx_ver: 3
[    4.076065] dx_dma_pcie 0000:01:00.0: [dx_dma_pcie_probe] Probe Done!!
[    4.100971] dxrt_driver_cdev_init: 1 devices
```

---

## 🚀 Quick Deployment Commands

### Flash Vendor Image

```powershell
# 1. Install genio-tools
pip3 install -U genio-tools

# 2. Put board in download mode (hold volume button + power on)

# 3. Navigate to image directory
cd "C:\path\to\vendor\image\directory"

# 4. Flash image
genio-flash

# 5. Wait for completion (~3 minutes)
# 6. Power cycle board
# 7. Wait for boot (1-2 minutes)
```

### Verify Installation

```bash
# SSH to board
ssh root@192.168.50.32

# Check system
uname -a
cat /etc/os-release

# Check DeepX drivers
lsmod | grep dx

# Check DeepX version
dxrt-cli --version

# Check installed packages
opkg list-installed | grep dx
```

---

## 🆘 Troubleshooting

### Board Won't Boot After Flash

**Solution:** Connect serial console to see boot messages
- Port: COM7 (UART debug port)
- Settings: 115200 baud, 8N1
- Tool: PuTTY or TeraTerm

**See:** `docs/BOARD_RECOVERY_GUIDE.md`

### genio-flash Stuck at "waiting for any device"

**Cause:** Missing MediaTek USB VCOM drivers

**Solution:** Install MediaTek drivers
- Download: MTK-Driver-v5.2307.zip
- Run installer as Administrator
- Retry genio-flash

**See:** `docs/INSTALL_MEDIATEK_DRIVERS.md`

### Board Not at Expected IP

**Solution:** Check router DHCP leases or use serial console
```bash
# Via serial console
ip addr show
ip route
```

**See:** `docs/FLASH_STATUS_AND_NEXT_STEPS.md`

### DeepX Drivers Not Loading

**Solution:** Manually load and configure auto-load
```bash
ssh root@192.168.50.32
modprobe dx_dma
modprobe dxrt_driver
echo 'dx_dma' > /etc/modules-load.d/deepx.conf
echo 'dxrt_driver' >> /etc/modules-load.d/deepx.conf
```

---

## 📦 What's Included

### Documentation (docs/)
- Complete deployment guides
- Driver installation instructions
- Recovery procedures
- Troubleshooting guides
- Alternative Yocto build method

### Scripts (scripts/)
- Automated flash scripts (PowerShell & Bash)
- Network diagnostics
- Board verification tools
- Yocto build scripts (alternative method)

### Configuration (configs/)
- Kernel configuration
- Build configurations

---

## 🎓 Learning Resources

### Key Technologies
- **Yocto Project:** Embedded Linux build system
- **genio-flash:** MediaTek board flashing tool
- **DeepX Runtime:** AI inference runtime for DeepX M1 NPU
- **Grinn GenioSBC-700:** MediaTek Genio 700 based SBC

### Useful Links
- [Grinn GenioSBC-700 Documentation](https://grinn-global.com/)
- [MediaTek Genio Tools](https://mediatek.gitlab.io/aiot/doc/aiot-dev-guide/)
- [DeepX Runtime Documentation](https://www.deepx.ai/)
- [Yocto Project](https://www.yoctoproject.org/)

---

## 📝 Notes

### Deployment Method Comparison

| Method | Time | Difficulty | Customization | Result |
|--------|------|------------|---------------|--------|
| Vendor Image | 15-20 min | Easy | None | DeepX 3.2.0 pre-installed |
| Yocto Build | 4-8 hours | Advanced | Full | Custom DeepX build |

**Recommendation:** Use vendor image for fastest deployment. Use Yocto build only if customization is needed.

### Important Files

- **Vendor Image:** `rity-demo-image-grinn-genio-700-sbc.aiotflash.tar.xz` (~750MB)
- **MediaTek Drivers:** `MTK-Driver-v5.2307.zip` (~9MB)
- **Yocto Package:** `genio700-deepx-yocto.tar.gz` (~26GB, optional)

---

## 🤝 Contributing

This deployment package was created to document the complete process of deploying DeepX 3.2.0 runtime on Grinn GenioSBC-700.

Feel free to:
- Report issues
- Suggest improvements
- Share your deployment experiences
- Contribute additional documentation

---

## 📄 License

This documentation is provided as-is for educational and deployment purposes.

---

**Last Updated:** March 25, 2026  
**Status:** ✅ Successfully deployed and verified  
**Board:** Grinn GenioSBC-700 at 192.168.50.32  
**DeepX Version:** 3.2.0  
**Deployment Method:** Vendor image with genio-flash
