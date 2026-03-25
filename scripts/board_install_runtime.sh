#!/bin/sh
# DeepX Runtime Installation Script for Grinn GenioSBC-700
# Run this on the ARM64 board after kernel drivers are installed

set -e
export PATH=/sbin:/usr/sbin:/bin:/usr/bin:$PATH

echo "=== DeepX Runtime Installation for ARM64 Board ==="
echo ""

# Check if running on ARM64
ARCH=$(uname -m)
if [ "$ARCH" != "aarch64" ]; then
    echo "ERROR: This script must run on ARM64 (aarch64), detected: $ARCH"
    exit 1
fi

# Check kernel version
KERNEL_VER=$(uname -r)
echo "Kernel version: $KERNEL_VER"
if [ "$KERNEL_VER" != "5.15.47-mtk+gd011e19cfc68" ]; then
    echo "WARNING: Expected kernel 5.15.47-mtk+gd011e19cfc68, got $KERNEL_VER"
fi

# Check if drivers are loaded
echo ""
echo "=== Checking DeepX kernel drivers ==="
if ! cat /proc/modules | grep -q dx_dma; then
    echo "Loading dx_dma..."
    modprobe dx_dma || { echo "ERROR: Failed to load dx_dma"; exit 1; }
fi

if ! cat /proc/modules | grep -q dxrt_driver; then
    echo "Loading dxrt_driver..."
    modprobe dxrt_driver || { echo "ERROR: Failed to load dxrt_driver"; exit 1; }
fi

echo "Drivers loaded:"
cat /proc/modules | grep -E "dx_dma|dxrt_driver"

# Check for DeepX PCI device
echo ""
echo "=== Checking for DeepX M1 device (vendor 0x1ff4) ==="
if command -v lspci >/dev/null 2>&1; then
    lspci -d 1ff4: || echo "WARNING: DeepX device not detected via lspci"
else
    echo "lspci not available, skipping PCI device check"
fi

# Create runtime directory
RUNTIME_DIR=/home/root/dx-runtime
echo ""
echo "=== Setting up runtime directory: $RUNTIME_DIR ==="
mkdir -p $RUNTIME_DIR
cd $RUNTIME_DIR

# Clone dx-runtime if not present
if [ ! -d "dx-runtime" ]; then
    echo "Cloning dx-runtime repository..."
    if command -v git >/dev/null 2>&1; then
        git clone --recurse-submodules https://github.com/DEEPX-AI/dx-runtime.git
    else
        echo "ERROR: git not found. Please install git or transfer dx-runtime source manually."
        exit 1
    fi
fi

cd dx-runtime

# Check Python version
echo ""
echo "=== Checking Python environment ==="
PYTHON_VER=$(python3 --version 2>&1 | awk '{print $2}')
echo "Python version: $PYTHON_VER"

# Install dx_rt (core runtime)
echo ""
echo "=== Installing dx_rt (DeepX Runtime Core) ==="
cd dx_rt
./install.sh --arch aarch64 --dep --all || {
    echo "ERROR: dx_rt installation failed"
    echo "You may need to install dependencies manually:"
    echo "  - cmake >= 3.16"
    echo "  - gcc/g++"
    echo "  - python3-dev"
    exit 1
}
cd ..

# Install dx_fw (firmware)
echo ""
echo "=== Installing dx_fw (DeepX Firmware) ==="
cd dx_fw
./install.sh || {
    echo "ERROR: dx_fw installation failed"
    exit 1
}
cd ..

# Install dx_app (application layer)
echo ""
echo "=== Installing dx_app (DeepX Application Layer) ==="
cd dx_app
./install.sh || {
    echo "ERROR: dx_app installation failed"
    exit 1
}
cd ..

echo ""
echo "=== DeepX Runtime Installation Complete ==="
echo ""
echo "Installed components:"
echo "  - dx_rt (Runtime Core)"
echo "  - dx_fw (Firmware)"
echo "  - dx_app (Application Layer)"
echo ""
echo "Next steps:"
echo "  1. Verify installation: python3 -c 'import dxrt; print(dxrt.__version__)'"
echo "  2. Run example: cd dx_app/examples && python3 <example_script.py>"
echo ""
