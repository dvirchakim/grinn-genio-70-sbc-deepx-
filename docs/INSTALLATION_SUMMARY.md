# DeepX M1 Installation Summary - Grinn GenioSBC-700

**Board:** Grinn GenioSBC-700 at 192.168.50.31  
**User:** root (no password)  
**Kernel:** 5.15.47-mtk+gd011e19cfc68  
**Date:** March 23, 2026

---

## ✅ COMPLETED: Kernel Drivers

### What was done on the x86 host:
1. **Cross-compiled kernel modules** for ARM64:
   - `dx_dma.ko` (3.4M) - PCIe DMA engine
   - `dxrt_driver.ko` (1.1M) - DeepX NPU runtime driver
   - **Vermagic:** `5.15.47-mtk+gd011e19cfc68 SMP preempt mod_unload aarch64` ✅ (exact match)

2. **Kernel source preparation:**
   - Used upstream Linux stable 5.15.y
   - Patched SUBLEVEL to 47
   - Applied board's kernel config from `/proc/config.gz`
   - Set LOCALVERSION to match board exactly

3. **Build environment:**
   - Host: WSL Ubuntu 22.04 on Windows
   - Cross-compiler: `aarch64-linux-gnu-gcc 11.4.0`
   - Working directory: `/home/dvir/deepx_host_build/`

### What was installed on the board:
- **Module location:** `/lib/modules/5.15.47-mtk+gd011e19cfc68/extra/deepx/`
  - `dx_dma.ko`
  - `dxrt_driver.ko`

- **Configuration files:**
  - `/etc/modprobe.d/deepx.conf` - Load order dependency (dx_dma before dxrt_driver)
  - `/etc/modules-load.d/deepx.conf` - Auto-load on boot

- **Dependency database:** Updated via `depmod -a`

### Verification:
```bash
# Check modules are present
ls -lh /lib/modules/$(uname -r)/extra/deepx/

# Load modules manually
modprobe dx_dma
modprobe dxrt_driver

# Verify loaded
cat /proc/modules | grep -E "dx_dma|dxrt_driver"

# Check device (if lspci available)
lspci -d 1ff4:
```

---

## ⏳ PENDING: DeepX Runtime (dx_rt, dx_fw, dx_app)

The DeepX runtime components need to be **built from source on the ARM64 board** (not cross-compiled).

### Files transferred to board:
- **Location:** `/home/root/deepx_setup/`
- **Script:** `board_install_runtime.sh` - Automated installation script

### Installation steps on the board:

#### Option 1: Automated (Recommended)
```bash
ssh root@192.168.50.31
cd /home/root/deepx_setup
chmod +x board_install_runtime.sh
./board_install_runtime.sh
```

This script will:
1. Verify kernel drivers are loaded
2. Clone dx-runtime repository with submodules
3. Build and install dx_rt (runtime core)
4. Build and install dx_fw (firmware)
5. Build and install dx_app (application layer)

#### Option 2: Manual Installation
```bash
ssh root@192.168.50.31
cd /home/root
git clone --recurse-submodules https://github.com/DEEPX-AI/dx-runtime.git
cd dx-runtime

# Install dx_rt
cd dx_rt
./install.sh --arch aarch64 --dep --all
cd ..

# Install dx_fw
cd dx_fw
./install.sh
cd ..

# Install dx_app
cd dx_app
./install.sh
cd ..
```

### Prerequisites on the board:
The board needs these tools (check with Yocto/opkg):
- `git`
- `cmake` (>= 3.16)
- `gcc` / `g++`
- `python3` (>= 3.9)
- `python3-dev`
- `ninja-build` (optional, speeds up builds)

Install missing packages:
```bash
opkg update
opkg install git cmake gcc g++ python3-dev
```

### Post-installation verification:
```bash
# Check Python module
python3 -c "import dxrt; print(dxrt.__version__)"

# Run example (if available)
cd /home/root/dx-runtime/dx_app/examples
python3 <example_script.py>
```

---

## Build Artifacts on x86 Host

**Location:** `/home/dvir/deepx_host_build/` (in WSL)

### Directory structure:
```
deepx_host_build/
├── genio700_kernel_config          # Board's kernel config
├── kernel_src/                     # Linux 5.15.47 source (patched)
├── dkms_src/                       # DeepX driver source (extracted from deb)
├── dx_rt_npu_linux_driver/         # Driver git repo
├── dx-runtime/                     # Runtime git repo (for reference)
├── output/
│   ├── ko/
│   │   ├── dx_dma.ko
│   │   └── dxrt_driver.ko
│   └── modprobe.d/
│       └── deepx.conf
└── deepx_genio700_20260323.tar.gz  # Packaged drivers
```

### Recreating the build:
```bash
# In WSL
cd /home/dvir/deepx_host_build/dkms_src/usr/src/dxrt-driver-dkms-2.1.0-2/modules

# Clean
make DEVICE=m1 PCIE=deepx KERNEL_DIR=/home/dvir/deepx_host_build/kernel_src \
     ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- clean

# Build
make DEVICE=m1 PCIE=deepx KERNEL_DIR=/home/dvir/deepx_host_build/kernel_src \
     ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu-

# Verify
file rt/dxrt_driver.ko pci_deepx/dx_dma.ko
modinfo rt/dxrt_driver.ko | grep vermagic
```

---

## Troubleshooting

### Kernel modules won't load
```bash
# Check vermagic match
modinfo /lib/modules/$(uname -r)/extra/deepx/dx_dma.ko | grep vermagic
uname -r

# Try manual load with verbose errors
insmod /lib/modules/$(uname -r)/extra/deepx/dx_dma.ko
dmesg | tail -20

# Check for missing symbols
modprobe -v dx_dma
```

### Runtime build fails
```bash
# Check dependencies
cmake --version
gcc --version
python3 --version

# Check available RAM
free -h

# Check disk space
df -h /home

# View detailed build logs
cd /home/root/dx-runtime/dx_rt
./install.sh --arch aarch64 --dep --all --verbose
```

### Device not detected
```bash
# Check PCI devices
lspci -v -d 1ff4:

# Check kernel messages
dmesg | grep -i deepx
dmesg | grep -i dx_

# Verify drivers loaded
lsmod | grep dx
cat /proc/modules | grep dx
```

---

## References

- **DeepX Driver GitHub:** https://github.com/DEEPX-AI/dx_rt_npu_linux_driver
- **DeepX Runtime GitHub:** https://github.com/DEEPX-AI/dx-runtime
- **Grinn Global GitHub:** https://github.com/grinn-global
- **Board BSP Layer:** https://github.com/grinn-global/meta-grinn-genio
- **DeepX Meta Layer:** https://github.com/grinn-global/meta-deepx

---

## Next Steps

1. **SSH to the board:**
   ```bash
   ssh root@192.168.50.31
   ```

2. **Run the runtime installation script:**
   ```bash
   cd /home/root/deepx_setup
   chmod +x board_install_runtime.sh
   ./board_install_runtime.sh
   ```

3. **Verify everything works:**
   ```bash
   # Check drivers
   lsmod | grep dx
   
   # Check runtime
   python3 -c "import dxrt; print(dxrt.__version__)"
   
   # Check device
   lspci -d 1ff4:
   ```

4. **Test with your AI models** using the DeepX runtime API

---

**Installation completed by:** Cascade AI  
**Build host:** Windows 11 + WSL Ubuntu 22.04  
**Target board:** Grinn GenioSBC-700 (ARM64)
