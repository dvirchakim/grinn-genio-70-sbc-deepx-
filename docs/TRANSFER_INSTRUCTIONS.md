# Quick Transfer Instructions for Parallel Build

## Package Information

**Package Name:** `genio700-deepx-yocto-build-YYYYMMDD-HHMMSS.tar.gz`
**Location:** `/home/dvir/yocto_packages/` (in WSL)
**Windows Path:** `\\wsl$\Ubuntu-22.04\home\dvir\yocto_packages\`

**Package Size:** ~10-30GB (depending on sstate-cache inclusion)

---

## Transfer Methods

### Method 1: USB Drive (Recommended for large files)

```bash
# From WSL on source computer
cp /home/dvir/yocto_packages/genio700-deepx-yocto-build-*.tar.gz /mnt/d/
# (Replace /mnt/d/ with your USB drive mount point)
```

### Method 2: Network Transfer (SCP)

```bash
# From WSL on source computer to target computer
scp /home/dvir/yocto_packages/genio700-deepx-yocto-build-*.tar.gz user@target-computer:/home/user/
```

### Method 3: Cloud Storage

Upload to Google Drive, Dropbox, or similar, then download on target computer.

---

## On Target Computer - Quick Start

### 1. Extract Package

```bash
tar -xzf genio700-deepx-yocto-build-*.tar.gz
cd yocto_build
```

### 2. Run Setup

```bash
./setup_on_target.sh
```

### 3. Start Build

```bash
./start_build.sh
```

### 4. Wait 4-8 Hours

The build will run and show progress. When complete, packages will be in:
- `build/tmp/deploy/images/grinn-genio-700-sbc/` (bootable image)
- `build/tmp/deploy/ipk/aarch64/dx-*.ipk` (DeepX packages)

---

## For Claude Agent on Target Computer

**Read this file first:** `YOCTO_BUILD_GUIDE.md`

**Execute these commands in order:**

```bash
# 1. Extract
tar -xzf genio700-deepx-yocto-build-*.tar.gz
cd yocto_build

# 2. Setup
./setup_on_target.sh

# 3. Verify
df -h .  # Check disk space (need 90GB+)
kas --version  # Should show kas 5.2+

# 4. Build
./start_build.sh

# 5. Monitor
# Build will show progress percentage
# Wait for "Tasks Summary: ... all succeeded"

# 6. Extract packages
cd build/tmp/deploy/ipk/aarch64/
ls -lh dx-*.ipk
```

**If errors occur:** See Troubleshooting section in `YOCTO_BUILD_GUIDE.md`

---

## Package Contents

```
yocto_build/
├── YOCTO_BUILD_GUIDE.md       ← READ THIS FIRST (comprehensive guide)
├── BUILD_INFO.txt             ← Package information
├── setup_on_target.sh         ← Run this to install dependencies
├── start_build.sh             ← Run this to start build
├── genio700-deepx-build.yml   ← Kas configuration
├── meta-grinn-genio/          ← Grinn BSP layer
└── build/
    ├── conf/                  ← Build configuration
    ├── downloads/             ← Source packages (saves download time)
    └── sstate-cache/          ← Build cache (speeds up build)
```

---

## Expected Timeline

| Phase | Duration | Description |
|-------|----------|-------------|
| Transfer | 10min-2hrs | Depends on method and package size |
| Setup | 5-10min | Install dependencies |
| Build | 4-8hrs | Compile all packages |
| Extract | 1min | Copy packages |
| Transfer to board | 1min | SCP packages to board |
| Install on board | 2min | Install with opkg |

**Total:** ~5-10 hours from start to finish

---

## Success Criteria

✅ Build completes with: `Tasks Summary: Attempted 8530 tasks ... all succeeded`
✅ Image exists: `build/tmp/deploy/images/grinn-genio-700-sbc/rity-demo-image-*.wic.gz`
✅ Packages exist: `build/tmp/deploy/ipk/aarch64/dx-rt_*.ipk`, `dx-npu_*.ipk`, `dx-app_*.ipk`
✅ On board: `python3 -c "import dxrt"` works without errors

---

## Current Build Status on Source Computer

**This computer is also building in parallel.**

Check progress:
```bash
# In WSL
wsl -d Ubuntu-22.04 -- bash -c "cd /home/dvir/yocto_build/build && tail -100 tmp/log/cooker/grinn-genio-700-sbc/console-latest.log"
```

Both builds can run simultaneously - whichever finishes first can be used.

---

## Contact Information

**Board:** Grinn GenioSBC-700
**IP:** 192.168.50.31
**User:** root (no password)
**SSH:** `ssh root@192.168.50.31`

**Install packages on board:**
```bash
scp build/tmp/deploy/ipk/aarch64/dx-*.ipk root@192.168.50.31:/tmp/
ssh root@192.168.50.31 'opkg install /tmp/dx-*.ipk'
```

---

## Troubleshooting Quick Reference

| Error | Solution |
|-------|----------|
| `apusys fetch failed` | Already in downloads/, build will use it |
| `llvm-native compile failed` | Clean and retry: `bitbake -c cleansstate llvm-native` |
| `No space left` | Need 90GB+ free, clean up or use larger disk |
| `Network timeout` | Yocto will retry with mirrors, usually harmless |
| `Build hangs` | Ctrl+C, clean failed task, restart |

**Full troubleshooting:** See `YOCTO_BUILD_GUIDE.md` section "Troubleshooting"

---

## End

Transfer the package, extract it, read `YOCTO_BUILD_GUIDE.md`, and follow the instructions.

The guide is written specifically for a Claude agent to follow step-by-step.
