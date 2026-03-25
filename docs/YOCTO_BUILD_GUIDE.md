# Yocto Build Guide for Grinn GenioSBC-700 with DeepX M1 NPU
## Complete Setup and Build Instructions for Claude Agent

---

## Table of Contents
1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Initial Setup](#initial-setup)
4. [Build Execution](#build-execution)
5. [Troubleshooting](#troubleshooting)
6. [Post-Build Steps](#post-build-steps)
7. [Known Issues and Solutions](#known-issues-and-solutions)

---

## Overview

**Objective:** Build a complete bootable Linux image for the Grinn GenioSBC-700 board with DeepX M1 NPU runtime support.

**Target Board:** Grinn GenioSBC-700 (ARM64 architecture)
**Yocto Release:** Kirkstone (Linux kernel 5.15.47)
**Image Name:** rity-demo-image
**Build System:** Yocto Project with kas build tool

**DeepX Components:**
- `dx-rt` - DeepX runtime library
- `dx-npu` - NPU firmware and drivers
- `dx-app` - Application layer
- Kernel drivers: `dx_dma.ko`, `dxrt_driver.ko`

**Expected Build Time:** 4-8 hours (first build), 30min-2 hours (incremental)

---

## Prerequisites

### System Requirements

**Operating System:**
- Ubuntu 22.04 LTS (strongly recommended)
- Ubuntu 20.04 LTS (compatible)
- Debian 11+ (may work with adjustments)

**Hardware Requirements:**
- **Disk Space:** 90GB+ free (100GB+ recommended)
- **RAM:** 8GB minimum, 16GB+ recommended
- **CPU:** 4+ cores (8+ cores significantly faster)
- **Internet:** Required for cloning Yocto layers

**Software Dependencies:**
All dependencies are installed by `setup_on_target.sh`, but here's the list:
```
gawk wget git diffstat unzip texinfo gcc build-essential chrpath socat
cpio python3 python3-pip python3-pexpect xz-utils debianutils iputils-ping
python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev xterm python3-subunit
mesa-common-dev zstd liblz4-tool file locales libncurses5-dev
```

**Python Tools:**
- kas (Yocto build tool) - installed via pip3

---

## Initial Setup

### Step 1: Extract the Package

```bash
# Extract the transferred package
tar -xzf genio700-deepx-yocto-build-*.tar.gz

# Navigate to the extracted directory
cd yocto_build
```

**Expected directory structure:**
```
yocto_build/
├── meta-grinn-genio/          # Grinn BSP layer
├── genio700-deepx-build.yml   # Kas configuration
├── build/
│   ├── conf/                  # Build configuration
│   │   ├── local.conf
│   │   └── bblayers.conf
│   ├── downloads/             # Downloaded source packages
│   └── sstate-cache/          # Shared state cache (optional)
├── setup_on_target.sh         # Setup script
├── start_build.sh             # Build script
├── BUILD_INFO.txt             # Package information
└── YOCTO_BUILD_GUIDE.md       # This file
```

### Step 2: Run Setup Script

```bash
# Make setup script executable (if not already)
chmod +x setup_on_target.sh

# Run setup script
./setup_on_target.sh
```

**What the setup script does:**
1. Checks OS compatibility (Ubuntu 22.04 recommended)
2. Installs all Yocto build dependencies via apt-get
3. Installs kas build tool via pip3
4. Configures system locale (en_US.UTF-8)

**Expected output:**
```
=== Yocto Build Setup on Target Computer ===
OS: Ubuntu 22.04.x LTS
Installing Yocto build dependencies...
Installing kas (Yocto build tool)...
Configuring locale...
=== Setup Complete ===
```

**If setup fails:**
- Check internet connectivity
- Ensure you have sudo privileges
- Verify Ubuntu version: `lsb_release -a`
- Check disk space: `df -h .`

### Step 3: Verify Setup

```bash
# Check kas is installed
kas --version
# Expected: kas 5.2 or higher

# Check disk space
df -h .
# Should show 90GB+ available

# Check locale
locale
# Should show LANG=en_US.UTF-8
```

---

## Build Execution

### Step 4: Start the Build

```bash
# Make build script executable (if not already)
chmod +x start_build.sh

# Start the build
./start_build.sh
```

**What happens during the build:**

1. **Initialization (0-5%):**
   - Sources Yocto environment
   - Fixes layer paths in bblayers.conf
   - Parses recipes and dependencies

2. **Setscene Tasks (5-10%):**
   - Loads cached/pre-built tasks from sstate-cache
   - Downloads source packages to build/downloads/

3. **Native Tools Build (10-30%):**
   - Compiles build tools for host system (x86_64)
   - Key packages: gcc-native, binutils-native, cmake-native, python3-native
   - **Longest phase:** llvm-native, rust-llvm-native (can take 1-2 hours)

4. **Cross-Compilation Toolchain (30-40%):**
   - Builds ARM64 cross-compiler
   - Packages: gcc-cross-aarch64, binutils-cross-aarch64

5. **Target Packages (40-80%):**
   - Compiles all packages for ARM64 target
   - Includes: glibc, kernel, bootloader, system libraries, DeepX runtime

6. **Kernel Compilation (60-70%):**
   - Builds Linux kernel 5.15.47 for MediaTek platform
   - Includes DeepX kernel drivers (dx_dma.ko, dxrt_driver.ko)

7. **DeepX Runtime (70-75%):**
   - Builds dx-rt (runtime library)
   - Builds dx-npu (NPU firmware)
   - Builds dx-app (application layer)

8. **Image Assembly (80-100%):**
   - Creates root filesystem
   - Packages everything into bootable image
   - Generates .ipk packages

**Build progress indicators:**
```
Setscene tasks: 3582 of 3582
Currently 12 running tasks (2214 of 8530)  25% |#######################|
```

**Expected build time:**
- Fast machine (16 cores, SSD): 3-4 hours
- Medium machine (8 cores, SSD): 5-6 hours
- Slow machine (4 cores, HDD): 7-10 hours

### Step 5: Monitor Build Progress

**Check build status:**
The build runs in the foreground and shows progress. You'll see:
- Percentage complete
- Number of tasks completed / total tasks
- Currently running tasks with time elapsed

**Build is successful when you see:**
```
NOTE: Tasks Summary: Attempted 8530 tasks of which 3582 didn't need to be rerun and all succeeded.
```

**Build output location:**
```
build/tmp/deploy/images/grinn-genio-700-sbc/
```

---

## Troubleshooting

### Common Issues and Solutions

#### Issue 1: apusys Fetch Failure

**Error:**
```
ERROR: apusys-1.0-r0 do_fetch: Fetcher failure
git clone https://gitlab.com/mediatek/aiot/bsp/mtk-apusys-driver.git failed
```

**Solution:**
The apusys repository should already be in `build/downloads/`. If the error persists:

```bash
cd build/downloads
git clone --bare --mirror https://gitlab.com/mediatek/aiot/bsp/mtk-apusys-driver.git \
  gitlab.com.mediatek.aiot.bsp.mtk-apusys-driver.git
```

Then restart the build.

#### Issue 2: llvm-native Compilation Failure

**Error:**
```
ERROR: llvm-native-18.1.6-r0 do_compile: ninja: build stopped: subcommand failed
```

**Solution:**
Clean the llvm-native build and retry:

```bash
cd build
source ../poky/oe-init-build-env .
bitbake -c cleansstate llvm-native
bitbake llvm-native
```

If it fails again, it may be due to insufficient RAM. Try:
1. Close other applications
2. Add swap space: `sudo fallocate -l 8G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile`
3. Reduce parallel builds: Edit `conf/local.conf` and add `BB_NUMBER_THREADS = "4"` and `PARALLEL_MAKE = "-j 4"`

#### Issue 3: Disk Space Running Out

**Error:**
```
ERROR: No space left on device
```

**Solution:**
```bash
# Check disk usage
df -h .

# Clean up build artifacts (keeps downloads and sstate-cache)
cd build
source ../poky/oe-init-build-env .
bitbake -c cleanall rity-demo-image

# If still not enough space, remove sstate-cache (will slow down next build)
rm -rf sstate-cache
```

#### Issue 4: Network/Download Failures

**Error:**
```
WARNING: Failed to fetch URL https://ftp.gnu.org/...
```

**Solution:**
These warnings are usually harmless - Yocto will retry with mirror sites. If downloads consistently fail:

1. Check internet connectivity
2. Check if behind a proxy - configure in `conf/local.conf`:
   ```
   HTTP_PROXY = "http://proxy.example.com:8080"
   HTTPS_PROXY = "http://proxy.example.com:8080"
   ```

#### Issue 5: Build Stops/Hangs

**Symptoms:**
- No progress for 30+ minutes
- No CPU activity

**Solution:**
1. Press Ctrl+C to stop
2. Check the last error in the output
3. Clean the failed task:
   ```bash
   cd build
   source ../poky/oe-init-build-env .
   bitbake -c cleansstate <failed-package>
   ```
4. Restart build: `./start_build.sh`

---

## Post-Build Steps

### Step 6: Verify Build Output

```bash
# Navigate to image output directory
cd build/tmp/deploy/images/grinn-genio-700-sbc/

# List generated files
ls -lh

# Expected files:
# - rity-demo-image-grinn-genio-700-sbc.wic.gz (bootable image)
# - rity-demo-image-grinn-genio-700-sbc.tar.gz (rootfs archive)
# - fitImage (kernel + device tree)
# - u-boot.bin (bootloader)
```

### Step 7: Extract DeepX Runtime Packages

```bash
# Navigate to package directory
cd build/tmp/deploy/ipk/aarch64/

# List DeepX packages
ls -lh dx-*.ipk

# Expected packages:
# - dx-rt_*.ipk (runtime library)
# - dx-npu_*.ipk (NPU firmware)
# - dx-app_*.ipk (application layer)

# Copy packages to a transfer directory
mkdir -p ~/deepx_packages
cp dx-*.ipk ~/deepx_packages/
```

### Step 8: Transfer to Board

**Option A: Install individual packages on existing board**

```bash
# From build computer, copy packages to board
scp ~/deepx_packages/dx-*.ipk root@192.168.50.31:/tmp/

# SSH to board
ssh root@192.168.50.31

# Install packages on board
opkg install /tmp/dx-*.ipk

# Verify installation
python3 -c "import dxrt; print('DeepX runtime version:', dxrt.__version__)"
```

**Option B: Flash complete image to board**

```bash
# Extract the bootable image
cd build/tmp/deploy/images/grinn-genio-700-sbc/
gunzip rity-demo-image-grinn-genio-700-sbc.wic.gz

# Flash to SD card (replace /dev/sdX with your SD card device)
sudo dd if=rity-demo-image-grinn-genio-700-sbc.wic of=/dev/sdX bs=4M status=progress
sync

# Insert SD card into board and boot
```

### Step 9: Verify DeepX Runtime on Board

```bash
# SSH to board
ssh root@192.168.50.31

# Check kernel drivers loaded
lsmod | grep dx
# Expected: dx_dma, dxrt_driver

# Check DeepX device
ls -l /dev/dxg*
# Expected: /dev/dxg0 or similar

# Test Python runtime
python3 -c "import dxrt; print('DeepX runtime OK')"

# Check NPU firmware
ls -l /lib/firmware/deepx/
```

---

## Known Issues and Solutions

### Issue: Layer Path Errors

**Error:**
```
ERROR: The following layer directories do not exist:
ERROR:    /path/to/meta-grinn-genio-bsp
```

**Solution:**
This is automatically fixed by `start_build.sh`. If you see this error, the script's sed commands should resolve it. If not, manually edit `build/conf/bblayers.conf`:

```bash
# Change:
${TOPDIR}/../meta-grinn-genio-bsp
# To:
${TOPDIR}/../meta-grinn-genio/meta-grinn-genio-bsp
```

### Issue: Locale Warnings

**Warning:**
```
WARNING: setlocale: LC_ALL: cannot change locale (en_US.UTF-8)
```

**Solution:**
```bash
sudo locale-gen en_US.UTF-8
sudo update-locale LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
```

### Issue: MACHINE Not Set

**Error:**
```
ERROR: MACHINE=unset is invalid
```

**Solution:**
Edit `build/conf/local.conf` and ensure it contains:
```
MACHINE = "grinn-genio-700-sbc"
```

---

## Build Configuration Details

### Key Configuration Files

**build/conf/local.conf:**
- Machine configuration: `MACHINE = "grinn-genio-700-sbc"`
- DeepX features: `MACHINE_FEATURES:append = " deepx"`
- DeepX device: `DX_DEVICE = "m1"`
- DeepX PCIe: `DX_PCIE = "deepx"`
- Image packages: `IMAGE_INSTALL:append = " dx-rt dx-npu"`

**build/conf/bblayers.conf:**
- Lists all Yocto layers used in the build
- Includes meta-deepx layer for DeepX support

**genio700-deepx-build.yml:**
- Kas configuration file
- Defines layer sources and versions
- Sets machine and target image

---

## Performance Optimization Tips

### Speed Up Builds

1. **Use more CPU cores:**
   Edit `conf/local.conf`:
   ```
   BB_NUMBER_THREADS = "16"  # Number of bitbake tasks in parallel
   PARALLEL_MAKE = "-j 16"   # Number of make jobs in parallel
   ```

2. **Use SSD instead of HDD:**
   Significantly faster I/O for builds

3. **Increase RAM:**
   16GB+ recommended for parallel builds

4. **Use sstate-cache:**
   The transferred sstate-cache speeds up builds significantly

5. **Use download cache:**
   The transferred downloads/ directory contains all source packages

### Reduce Disk Usage

1. **Remove build artifacts after successful build:**
   ```bash
   cd build
   rm -rf tmp/work
   ```
   (Keeps only final images and packages)

2. **Clean specific packages:**
   ```bash
   bitbake -c clean <package-name>
   ```

3. **Remove sstate-cache if needed:**
   ```bash
   rm -rf sstate-cache
   ```
   (Will slow down next build but frees ~20-30GB)

---

## Summary Checklist for Claude Agent

**Pre-Build:**
- [ ] Extract package: `tar -xzf genio700-deepx-yocto-build-*.tar.gz`
- [ ] Run setup: `./setup_on_target.sh`
- [ ] Verify disk space: `df -h .` (90GB+ free)
- [ ] Verify kas installed: `kas --version`

**Build:**
- [ ] Start build: `./start_build.sh`
- [ ] Monitor progress (4-8 hours)
- [ ] Handle any errors (see Troubleshooting section)
- [ ] Wait for completion message

**Post-Build:**
- [ ] Verify image: `ls build/tmp/deploy/images/grinn-genio-700-sbc/`
- [ ] Extract packages: `cp build/tmp/deploy/ipk/aarch64/dx-*.ipk ~/deepx_packages/`
- [ ] Transfer to board: `scp ~/deepx_packages/dx-*.ipk root@192.168.50.31:/tmp/`
- [ ] Install on board: `ssh root@192.168.50.31 'opkg install /tmp/dx-*.ipk'`
- [ ] Verify on board: `ssh root@192.168.50.31 'python3 -c "import dxrt"'`

---

## Support Information

**Board Details:**
- Board: Grinn GenioSBC-700
- IP Address: 192.168.50.31
- User: root
- Password: (none)
- SSH: `ssh root@192.168.50.31`

**Build Information:**
- Yocto Release: Kirkstone
- Kernel Version: 5.15.47-mtk
- Machine: grinn-genio-700-sbc
- Image: rity-demo-image

**DeepX Components:**
- Runtime: dx-rt
- Firmware: dx-npu
- Application: dx-app
- Drivers: dx_dma.ko, dxrt_driver.ko

**Expected Output:**
- Bootable image: ~2-4GB
- Runtime packages: ~50-100MB total
- Build artifacts: ~60-80GB

---

## End of Guide

This guide provides complete instructions for a Claude agent to set up and execute the Yocto build on a target computer. Follow the steps sequentially, and refer to the Troubleshooting section for any issues encountered during the build process.

**Build success criteria:**
- All 8530 tasks completed successfully
- Image files present in `build/tmp/deploy/images/grinn-genio-700-sbc/`
- DeepX packages present in `build/tmp/deploy/ipk/aarch64/`
- No ERROR messages in final build summary

Good luck with the build!
