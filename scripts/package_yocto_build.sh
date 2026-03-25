#!/bin/bash
# Package Yocto build environment for transfer to another computer
# This creates a compressed archive with all necessary files for parallel compilation

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="/home/dvir/yocto_build"
PACKAGE_NAME="genio700-deepx-yocto-build-$(date +%Y%m%d-%H%M%S).tar.gz"
PACKAGE_DIR="/home/dvir/yocto_packages"

echo "=== Yocto Build Environment Packaging Script ==="
echo "Build directory: $BUILD_DIR"
echo "Package name: $PACKAGE_NAME"
echo ""

# Create package directory
mkdir -p "$PACKAGE_DIR"

echo "Step 1: Creating temporary staging directory..."
TEMP_DIR=$(mktemp -d)
STAGE_DIR="$TEMP_DIR/yocto_build"
mkdir -p "$STAGE_DIR"

echo "Step 2: Copying essential directories..."
echo "  - Copying meta-grinn-genio BSP..."
cp -a "$BUILD_DIR/meta-grinn-genio" "$STAGE_DIR/"

echo "  - Copying kas configuration..."
cp "$BUILD_DIR/genio700-deepx-build.yml" "$STAGE_DIR/"

echo "  - Copying build configuration files..."
mkdir -p "$STAGE_DIR/build/conf"
cp "$BUILD_DIR/build/conf/local.conf" "$STAGE_DIR/build/conf/"
cp "$BUILD_DIR/build/conf/bblayers.conf" "$STAGE_DIR/build/conf/"

echo "  - Copying downloads directory (this may take a while)..."
cp -a "$BUILD_DIR/build/downloads" "$STAGE_DIR/build/"

echo "  - Copying sstate-cache (shared state cache - speeds up build)..."
if [ -d "$BUILD_DIR/build/sstate-cache" ]; then
    cp -a "$BUILD_DIR/build/sstate-cache" "$STAGE_DIR/build/"
fi

echo "Step 3: Creating setup scripts..."

# Create setup script for target computer
cat > "$STAGE_DIR/setup_on_target.sh" << 'SETUP_EOF'
#!/bin/bash
# Setup script to run on target computer
set -e

echo "=== Yocto Build Setup on Target Computer ==="
echo ""

# Check system requirements
echo "Checking system requirements..."
if [ ! -f /etc/os-release ]; then
    echo "ERROR: Cannot detect OS"
    exit 1
fi

. /etc/os-release
echo "OS: $NAME $VERSION"

# Check for Ubuntu 22.04 or compatible
if [[ ! "$ID" =~ ^(ubuntu|debian)$ ]]; then
    echo "WARNING: This build was configured for Ubuntu 22.04"
    echo "Your OS: $ID"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Install dependencies
echo ""
echo "Installing Yocto build dependencies..."
sudo apt-get update
sudo apt-get install -y \
    gawk wget git diffstat unzip texinfo gcc build-essential chrpath socat \
    cpio python3 python3-pip python3-pexpect xz-utils debianutils iputils-ping \
    python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev xterm python3-subunit \
    mesa-common-dev zstd liblz4-tool file locales libncurses5-dev

# Install kas
echo ""
echo "Installing kas (Yocto build tool)..."
pip3 install kas

# Set locale
echo ""
echo "Configuring locale..."
sudo locale-gen en_US.UTF-8
sudo update-locale LANG=en_US.UTF-8

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Next steps:"
echo "1. Review the YOCTO_BUILD_GUIDE.md file"
echo "2. Run: ./start_build.sh"
echo ""
SETUP_EOF

chmod +x "$STAGE_DIR/setup_on_target.sh"

# Create start build script
cat > "$STAGE_DIR/start_build.sh" << 'BUILD_EOF'
#!/bin/bash
set -e

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

cd "$(dirname "$0")/build"

# Source Yocto environment
source ../poky/oe-init-build-env .

# Fix layer paths if needed
sed -i 's|\${TOPDIR}/../meta-grinn-genio-bsp|\${TOPDIR}/../meta-grinn-genio/meta-grinn-genio-bsp|g' conf/bblayers.conf
sed -i 's|\${TOPDIR}/../meta-grinn-genio-fixes|\${TOPDIR}/../meta-grinn-genio/meta-grinn-genio-fixes|g' conf/bblayers.conf

echo "=== Starting Yocto build for rity-demo-image with DeepX support ==="
echo "Machine: grinn-genio-700-sbc"
echo "This will take 4-8 hours on first build..."
echo ""

# Start the build
bitbake rity-demo-image
BUILD_EOF

chmod +x "$STAGE_DIR/start_build.sh"

echo "Step 4: Creating build information file..."
cat > "$STAGE_DIR/BUILD_INFO.txt" << INFO_EOF
Yocto Build Package for Grinn GenioSBC-700 with DeepX M1 NPU Support
====================================================================

Created: $(date)
Source Computer: $(hostname)
Build Directory: $BUILD_DIR

Target Board: Grinn GenioSBC-700
Machine: grinn-genio-700-sbc
Image: rity-demo-image
Yocto Release: Kirkstone (5.15 kernel)

DeepX Components Included:
- dx-rt (DeepX runtime library)
- dx-npu (NPU firmware)
- dx-app (Application layer)
- Kernel drivers: dx_dma.ko, dxrt_driver.ko

Package Contents:
- meta-grinn-genio/ - Grinn BSP layer
- genio700-deepx-build.yml - Kas configuration
- build/conf/ - Build configuration files
- build/downloads/ - Downloaded source packages
- build/sstate-cache/ - Shared state cache (if available)
- setup_on_target.sh - Setup script for target computer
- start_build.sh - Build execution script
- YOCTO_BUILD_GUIDE.md - Comprehensive setup guide

System Requirements:
- Ubuntu 22.04 LTS (or compatible Debian-based Linux)
- 90GB+ free disk space
- 8GB+ RAM (16GB recommended)
- 4+ CPU cores (8+ recommended for faster builds)
- Internet connection (for cloning Yocto layers)

Build Time Estimate:
- First build: 4-8 hours (depending on CPU/cores)
- Incremental builds: 30min-2 hours

Output Location (after build):
- Bootable image: build/tmp/deploy/images/grinn-genio-700-sbc/
- Runtime packages (.ipk): build/tmp/deploy/ipk/aarch64/dx-*.ipk

For detailed instructions, see YOCTO_BUILD_GUIDE.md
INFO_EOF

echo "Step 5: Compressing package..."
cd "$TEMP_DIR"
tar -czf "$PACKAGE_DIR/$PACKAGE_NAME" yocto_build/
PACKAGE_SIZE=$(du -h "$PACKAGE_DIR/$PACKAGE_NAME" | cut -f1)

echo ""
echo "=== Packaging Complete ==="
echo "Package: $PACKAGE_DIR/$PACKAGE_NAME"
echo "Size: $PACKAGE_SIZE"
echo ""
echo "Cleaning up temporary files..."
rm -rf "$TEMP_DIR"

echo ""
echo "=== Next Steps ==="
echo "1. Transfer $PACKAGE_NAME to target computer"
echo "2. Extract: tar -xzf $PACKAGE_NAME"
echo "3. Read: YOCTO_BUILD_GUIDE.md"
echo "4. Run: ./setup_on_target.sh"
echo "5. Run: ./start_build.sh"
echo ""
