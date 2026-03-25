# Manual Transfer Guide to Build PC

## Build PC Information

**IP Address:** 10.181.153.96
**Username:** nisko
**Target Directory:** `/home/nisko/yocto compile/grinn deepx/`

**Build PC Resources:**
- Disk Space: 319GB available ✅
- RAM: 7.4GB (5.9GB available) ✅
- Status: Ready for Yocto build

---

## Transfer Options

### Option 1: USB Drive (Recommended - Most Reliable)

```powershell
# 1. Copy package to USB drive (e.g., D:)
Copy-Item C:\Users\dvir\genio700-deepx-yocto.tar.gz D:\

# 2. Physically move USB drive to build PC

# 3. On build PC, mount USB and copy
sudo mkdir -p /mnt/usb
sudo mount /dev/sdb1 /mnt/usb  # Adjust device name as needed
cp /mnt/usb/genio700-deepx-yocto.tar.gz "/home/nisko/yocto compile/grinn deepx/"
sudo umount /mnt/usb
```

### Option 2: Network Transfer via SCP (If Connection Stable)

```powershell
# From Windows PC
scp C:\Users\dvir\genio700-deepx-yocto.tar.gz nisko@10.181.153.96:"/home/nisko/yocto\ compile/grinn\ deepx/"
```

**Note:** Transfer may take 20-40 minutes for 26GB file.

### Option 3: Split File Transfer (If Network Unstable)

```powershell
# On Windows - Split into 2GB chunks
$source = "C:\Users\dvir\genio700-deepx-yocto.tar.gz"
$chunkSize = 2GB
$chunks = [Math]::Ceiling((Get-Item $source).Length / $chunkSize)

# Split file
$stream = [System.IO.File]::OpenRead($source)
$buffer = New-Object byte[] $chunkSize
for ($i = 0; $i -lt $chunks; $i++) {
    $read = $stream.Read($buffer, 0, $chunkSize)
    $output = "$source.part$i"
    [System.IO.File]::WriteAllBytes($output, $buffer[0..($read-1)])
}
$stream.Close()

# Transfer each chunk
for ($i = 0; $i -lt $chunks; $i++) {
    scp "$source.part$i" nisko@10.181.153.96:"/home/nisko/yocto\ compile/grinn\ deepx/"
}
```

```bash
# On build PC - Reassemble
cd "/home/nisko/yocto compile/grinn deepx"
cat genio700-deepx-yocto.tar.gz.part* > genio700-deepx-yocto.tar.gz
rm genio700-deepx-yocto.tar.gz.part*
```

---

## After Transfer - On Build PC

### 1. Verify Transfer

```bash
ssh nisko@10.181.153.96

cd "/home/nisko/yocto compile/grinn deepx"
ls -lh genio700-deepx-yocto.tar.gz
# Should show ~26GB file
```

### 2. Extract Package

```bash
tar -xzf genio700-deepx-yocto.tar.gz
cd yocto_build
```

### 3. Copy Build Guide

Transfer `YOCTO_BUILD_GUIDE.md` to the build PC:

```powershell
# From Windows
scp "C:\Users\dvir\CascadeProjects\magal grinn\docs\YOCTO_BUILD_GUIDE.md" nisko@10.181.153.96:"/home/nisko/yocto\ compile/grinn\ deepx/yocto_build/"
```

### 4. Run Setup

```bash
cd "/home/nisko/yocto compile/grinn deepx/yocto_build"
chmod +x setup_on_target.sh
./setup_on_target.sh
```

### 5. Start Build

```bash
chmod +x start_build.sh
./start_build.sh
```

**Build Time:** 4-8 hours

---

## Monitor Build Progress

```bash
# SSH to build PC
ssh nisko@10.181.153.96

# Check build progress
cd "/home/nisko/yocto compile/grinn deepx/yocto_build/build"
tail -f tmp/log/cooker/grinn-genio-700-sbc/console-latest.log
```

---

## After Build Completes

### Extract DeepX Packages

```bash
cd "/home/nisko/yocto compile/grinn deepx/yocto_build/build/tmp/deploy/ipk/aarch64"
ls -lh dx-*.ipk
```

### Transfer to Board

```bash
# From build PC
scp dx-*.ipk root@192.168.50.31:/tmp/
```

### Install on Board

```bash
ssh root@192.168.50.31 'opkg install /tmp/dx-*.ipk'
```

### Verify Installation

```bash
ssh root@192.168.50.31 'python3 -c "import dxrt; print(\"DeepX runtime OK\")"'
```

---

## Troubleshooting

### Transfer Interrupted

If SCP transfer fails partway through:
1. Use USB drive method (most reliable)
2. Or use split file transfer method
3. Or use rsync with resume: `rsync -avz --partial --progress`

### Build Fails

See `YOCTO_BUILD_GUIDE.md` Troubleshooting section for:
- apusys fetch failure (already in downloads/)
- llvm-native compilation failure
- Disk space issues
- Network/download failures

---

## Quick Command Reference

```bash
# Connect to build PC
ssh nisko@10.181.153.96

# Navigate to build directory
cd "/home/nisko/yocto compile/grinn deepx/yocto_build"

# Check disk space
df -h /home/nisko

# Start build
./start_build.sh

# Monitor build
tail -f build/tmp/log/cooker/grinn-genio-700-sbc/console-latest.log

# After build - check packages
ls -lh build/tmp/deploy/ipk/aarch64/dx-*.ipk

# Transfer to board
scp build/tmp/deploy/ipk/aarch64/dx-*.ipk root@192.168.50.31:/tmp/

# Install on board
ssh root@192.168.50.31 'opkg install /tmp/dx-*.ipk'
```

---

## Files to Transfer

1. **genio700-deepx-yocto.tar.gz** (26GB) - Main package
   - Source: `C:\Users\dvir\genio700-deepx-yocto.tar.gz`
   - Target: `/home/nisko/yocto compile/grinn deepx/`

2. **YOCTO_BUILD_GUIDE.md** - Complete guide
   - Source: `C:\Users\dvir\CascadeProjects\magal grinn\docs\YOCTO_BUILD_GUIDE.md`
   - Target: `/home/nisko/yocto compile/grinn deepx/yocto_build/`

---

## Expected Timeline

| Step | Duration |
|------|----------|
| Transfer package | 20-40 min (network) or 5-10 min (USB) |
| Extract package | 5-10 min |
| Setup dependencies | 5-10 min |
| Yocto build | 4-8 hours |
| Extract packages | 1 min |
| Transfer to board | 1 min |
| Install on board | 2 min |

**Total:** ~5-9 hours from start to finish

---

## Success Criteria

✅ Package transferred to build PC
✅ Package extracted successfully
✅ Setup completed without errors
✅ Build completes: "Tasks Summary: ... all succeeded"
✅ DeepX packages exist: dx-rt_*.ipk, dx-npu_*.ipk, dx-app_*.ipk
✅ Packages installed on board
✅ Python import works: `import dxrt`

---

**Build PC is ready with 319GB free space and 7.4GB RAM. Choose your preferred transfer method and proceed!**
