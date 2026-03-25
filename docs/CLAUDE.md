# DeepX Runtime Installation — Claude Code Instructions (x86 WSL Host)

## Your job
Download the pre-compiled ARM64 DeepX runtime from developer.deepx.ai, create an
offline install script, SCP everything to the board, and install it via SSH.
Complete the full sequence without stopping unless a step fails.

## Environment facts (do not prompt the user for these)
- **Host**: WSL Ubuntu 22.04 on Windows
- **Working dir**: `/home/dvir/deepx_host_build/` (already exists from previous session)
- **dx-runtime repo**: already cloned at `/home/dvir/deepx_host_build/dx-runtime/`
- **Board IP**: 192.168.50.31
- **Board user/pass**: root / (no password — use `sshpass -p '' ssh` or configure key)
- **Board kernel**: 5.15.47-mtk+gd011e19cfc68 (aarch64)
- **Board Python**: 3.10.15 at `/usr/bin/python3`
- **Board package manager**: opkg (offline — no internet on board)
- **Board has NO**: gcc, cmake, apt, dpkg
- **Kernel drivers already installed** on board: dx_dma.ko, dxrt_driver.ko

## FIRST: Ask the user for DeepX credentials
Before running any commands, ask:
"Please provide your developer.deepx.ai credentials:
  - Username (email):
  - Password:"
Store as DX_USER and DX_PASS. Do not log or echo these.

---

## Step 1 — Verify SSH connectivity to the board
```bash
ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@192.168.50.31 "uname -r && echo SSH_OK"
```
Expected output contains `5.15.47-mtk+gd011e19cfc68` and `SSH_OK`.
If it fails: tell the user to check the board is powered and on the network, then stop.

---

## Step 2 — Verify host tools
```bash
which sshpass || sudo apt-get install -y sshpass
which ssh scp git python3 pip3
```
Install anything missing via apt-get.

---

## Step 3 — Update dx-runtime repo
```bash
cd /home/dvir/deepx_host_build/dx-runtime
git pull --recurse-submodules
git submodule update --init --recursive
```

---

## Step 4 — Download ARM64 runtime archives (uses credentials)
Run from the dx-runtime directory. The `--archive_mode=y` flag downloads
pre-compiled packages without installing anything on the host.

```bash
cd /home/dvir/deepx_host_build/dx-runtime
export DX_USERNAME="$DX_USER"
export DX_PASSWORD="$DX_PASS"
./install.sh --all --archive_mode=y
```

After completion, check what was downloaded:
```bash
ls -lh archives/ 2>/dev/null || ls -lh */archives/ 2>/dev/null || \
  find . -name "*.tar.gz" -newer ../dx-runtime/.git/index | head -20
```

**If archives/ is empty or the flag is not recognised:** the submodule install
scripts may handle downloading directly. In that case run each submodule
individually and capture what gets placed in the local directories:
```bash
cd /home/dvir/deepx_host_build/dx-runtime
for component in dx_rt dx_fw dx_app; do
    if [ -f "$component/install.sh" ]; then
        echo "=== $component ==="
        DX_USERNAME="$DX_USER" DX_PASSWORD="$DX_PASS" \
            ./"$component"/install.sh --archive_mode=y 2>&1 | tail -5 || true
    fi
done
```

---

## Step 5 — Locate downloaded ARM64 artefacts
After Step 4, find all ARM64 artefacts:
```bash
find /home/dvir/deepx_host_build/dx-runtime -type f \
  \( -name "*.tar.gz" -o -name "*.tar" -o -name "*.whl" \
     -o -name "*.deb" -o -name "*.fw" -o -name "libdxrt*" \) \
  | sort
```

Categorise what you find into these groups and note the paths:
- **Runtime lib**: files matching `*dxrt*.tar.gz`, `libdxrt*.so`, `*dxrt*.whl`
- **Firmware**: files matching `*.fw`, `*dx_fw*`, `*firmware*`
- **Python wheel**: `*.whl` files
- **App binaries**: `*dx_app*`, `*dxapp*`

If nothing useful is found, report the exact output to the user and stop.

---

## Step 6 — Build the staging directory
Create a clean staging tree that will be SCPed to the board:
```bash
STAGE=/home/dvir/deepx_host_build/runtime_stage
rm -rf "$STAGE"
mkdir -p "$STAGE"/{archives,scripts}

# Copy everything found in Step 5
find /home/dvir/deepx_host_build/dx-runtime -type f \
  \( -name "*.tar.gz" -o -name "*.tar" -o -name "*.whl" \
     -o -name "*.deb" -o -name "*.fw" -o -name "libdxrt*" \) \
  -exec cp {} "$STAGE/archives/" \;

echo "Staged files:"
ls -lh "$STAGE/archives/"
```

---

## Step 7 — Write the on-board offline install script
Write exactly this file to `$STAGE/scripts/install_runtime.sh`:

```bash
cat > "$STAGE/scripts/install_runtime.sh" << 'INSTALL_EOF'
#!/bin/sh
# Offline DeepX runtime install for Grinn GenioSBC-700 (Yocto Kirkstone, aarch64)
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ARCHIVES="$SCRIPT_DIR/archives"
INSTALL_PREFIX="/opt/deepx"

echo "=== DeepX Runtime Offline Install ==="
echo "Board   : $(cat /proc/device-tree/model 2>/dev/null | tr -d '\0')"
echo "Kernel  : $(uname -r)"
echo "Archives: $ARCHIVES"
echo ""

# -- 1. Load kernel drivers --
echo "[1/5] Loading kernel drivers..."
for mod in dx_dma dxrt_driver; do
    if ! lsmod | grep -q "^$mod "; then
        modprobe "$mod" && echo "  loaded $mod" || echo "  WARNING: $mod failed (PCIe may be down)"
    else
        echo "  $mod already loaded"
    fi
done

# -- 2. Extract runtime archives --
echo ""
echo "[2/5] Extracting runtime archives..."
mkdir -p "$INSTALL_PREFIX"
EXTRACTED=0
for f in "$ARCHIVES"/*.tar.gz "$ARCHIVES"/*.tar "$ARCHIVES"/*.tgz; do
    [ -f "$f" ] || continue
    echo "  Extracting: $(basename "$f")"
    tar xf "$f" -C "$INSTALL_PREFIX" 2>/dev/null || tar xzf "$f" -C "$INSTALL_PREFIX" 2>/dev/null || \
        { echo "  WARNING: failed to extract $f"; continue; }
    EXTRACTED=$((EXTRACTED + 1))
done
[ "$EXTRACTED" -eq 0 ] && echo "  WARNING: no archives extracted"

# -- 3. Extract any .deb packages (no dpkg — use ar + tar) --
for f in "$ARCHIVES"/*.deb; do
    [ -f "$f" ] || continue
    echo "  Extracting deb: $(basename "$f")"
    TMPD=$(mktemp -d)
    cd "$TMPD"
    ar x "$f" 2>/dev/null || { echo "  WARNING: ar failed on $f"; rm -rf "$TMPD"; continue; }
    for data in data.tar.gz data.tar.xz data.tar.zst data.tar; do
        [ -f "$data" ] && tar xf "$data" -C "$INSTALL_PREFIX" 2>/dev/null && break
    done
    cd - >/dev/null
    rm -rf "$TMPD"
done

# -- 4. Install Python wheel --
echo ""
echo "[3/5] Installing Python wheel..."
WHEEL=$(find "$ARCHIVES" "$INSTALL_PREFIX" -name "dxrt*.whl" -o -name "dx_rt*.whl" 2>/dev/null | head -1)
if [ -n "$WHEEL" ]; then
    echo "  wheel: $WHEEL"
    pip3 install --no-deps --break-system-packages "$WHEEL" 2>/dev/null || \
    pip3 install --no-deps "$WHEEL" 2>/dev/null || \
        echo "  WARNING: pip install failed (will try user install)" && \
        pip3 install --no-deps --user "$WHEEL" 2>/dev/null || true
else
    # Also check installed path for wheel
    WHEEL=$(find "$INSTALL_PREFIX" -name "*.whl" 2>/dev/null | head -1)
    if [ -n "$WHEEL" ]; then
        pip3 install --no-deps "$WHEEL" 2>/dev/null || true
    else
        echo "  No .whl found — Python bindings may not be available"
    fi
fi

# -- 5. Configure shared library path --
echo ""
echo "[4/5] Configuring linker..."
LIBDIR=$(find "$INSTALL_PREFIX" -name "libdxrt*.so*" 2>/dev/null | head -1 | xargs -I{} dirname {} 2>/dev/null)
if [ -n "$LIBDIR" ]; then
    echo "$LIBDIR" > /etc/ld.so.conf.d/deepx.conf
    ldconfig 2>/dev/null || true
    echo "  Added $LIBDIR to ldconfig"
else
    echo "  libdxrt.so not found — checking after extraction..."
    # Fallback: add entire install prefix lib dirs
    find "$INSTALL_PREFIX" -name "*.so" -exec dirname {} \; 2>/dev/null | sort -u | while read d; do
        echo "$d" >> /etc/ld.so.conf.d/deepx.conf
    done
    ldconfig 2>/dev/null || true
fi

# -- 5. Copy firmware if needed --
echo ""
echo "[5/5] Installing firmware..."
FW_DEST="/lib/firmware/deepx"
mkdir -p "$FW_DEST"
FW_COUNT=0
for fw in $(find "$ARCHIVES" "$INSTALL_PREFIX" -name "*.fw" -o -name "*deepx*.bin" 2>/dev/null); do
    cp "$fw" "$FW_DEST/" 2>/dev/null && FW_COUNT=$((FW_COUNT + 1))
done
echo "  Copied $FW_COUNT firmware file(s) to $FW_DEST"

# -- Summary --
echo ""
echo "=== Done ==="
echo "Install path : $INSTALL_PREFIX"
echo "Contents     :"
find "$INSTALL_PREFIX" -maxdepth 3 | sed 's|'"$INSTALL_PREFIX"'||' | head -40
echo ""
echo "=== Verification ==="
echo "dxrt_driver loaded: $(lsmod | grep -c dxrt_driver || echo 0)"
echo "dx_dma loaded     : $(lsmod | grep -c dx_dma || echo 0)"
python3 -c "import dxrt; print('dxrt version:', dxrt.__version__)" 2>/dev/null || \
    python3 -c "import dxrt; print('dxrt imported OK')" 2>/dev/null || \
    echo "Python dxrt module: not importable yet"
INSTALL_EOF
chmod +x "$STAGE/scripts/install_runtime.sh"
```

---

## Step 8 — SCP staging directory to the board
```bash
STAGE=/home/dvir/deepx_host_build/runtime_stage

# Remove old staging dir on board first
sshpass -p '' ssh -o StrictHostKeyChecking=no root@192.168.50.31 \
    "rm -rf /home/root/deepx_runtime_stage"

# Upload
sshpass -p '' scp -o StrictHostKeyChecking=no -r "$STAGE" \
    root@192.168.50.31:/home/root/deepx_runtime_stage

echo "Transfer complete. Contents on board:"
sshpass -p '' ssh -o StrictHostKeyChecking=no root@192.168.50.31 \
    "find /home/root/deepx_runtime_stage -type f | head -30"
```

---

## Step 9 — Run install on the board via SSH
```bash
sshpass -p '' ssh -o StrictHostKeyChecking=no root@192.168.50.31 \
    "sh /home/root/deepx_runtime_stage/scripts/install_runtime.sh 2>&1"
```

Capture the full output. Look for:
- Extraction success/failures
- Python wheel install result
- ldconfig result
- Final verification lines

---

## Step 10 — Verify on the board
```bash
sshpass -p '' ssh -o StrictHostKeyChecking=no root@192.168.50.31 << 'VERIFY'
echo "=== Loaded modules ==="
lsmod | grep -E "dx_dma|dxrt_driver" || echo "NONE"

echo ""
echo "=== DeepX files in /opt/deepx ==="
find /opt/deepx -maxdepth 3 2>/dev/null | head -30 || echo "empty"

echo ""
echo "=== Python test ==="
python3 -c "import dxrt; print('dxrt OK:', dxrt.__version__)" 2>&1 || \
python3 -c "import dxrt; print('dxrt imported')" 2>&1 || \
echo "dxrt not importable"

echo ""
echo "=== dmesg DeepX ==="
dmesg | grep -i "deepx\|dxrt\|dx_dma" | tail -10
VERIFY
```

---

## Step 11 — Report result to user
After Step 10, summarise:
1. Which components were installed (runtime lib, firmware, Python wheel, apps)
2. Whether `import dxrt` works
3. Whether the kernel drivers are loaded
4. What still needs the PCIe M.2 module to be inserted (modules will be there but
   the device won't be visible at `/dev/dxrt0` until PCIe link comes up)

---

## Failure handling

| Failure | Action |
|---------|--------|
| `--archive_mode=y` not recognised | Read `./install.sh --help` output and find the correct flag for offline/download-only mode, then retry |
| Archives downloaded but all x86_64 | Check if `--arch arm64` or `--target aarch64` flags exist on install.sh; pass them |
| `install.sh` needs internet on the board | Do NOT modify the board script; download on host only |
| pip3 install fails (no deps available) | Try `pip3 install --no-deps`; the wheel may have all deps bundled |
| SSH connection refused | Board may have rebooted; wait 10s and retry once |
| tar extraction fails | Try both `tar xf` and `tar xzf`; some archives use zstd (`tar --zstd -xf`) |
| Nothing in archives after install.sh | Run `./install.sh --help` and report full output to user before stopping |
