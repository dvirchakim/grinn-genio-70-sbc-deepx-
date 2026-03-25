#!/bin/bash
set -e

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

cd /home/dvir/yocto_build/build

# Source Yocto environment
source ../poky/oe-init-build-env .

# Fix layer paths in bblayers.conf
sed -i 's|\${TOPDIR}/../meta-grinn-genio-bsp|\${TOPDIR}/../meta-grinn-genio/meta-grinn-genio-bsp|g' conf/bblayers.conf
sed -i 's|\${TOPDIR}/../meta-grinn-genio-fixes|\${TOPDIR}/../meta-grinn-genio/meta-grinn-genio-fixes|g' conf/bblayers.conf

# Set machine and DeepX feature in local.conf if not already set
if ! grep -q "^MACHINE.*grinn-genio-700-sbc" conf/local.conf; then
    echo 'MACHINE = "grinn-genio-700-sbc"' >> conf/local.conf
fi

if ! grep -q "deepx" conf/local.conf; then
    echo 'MACHINE_FEATURES:append = " deepx"' >> conf/local.conf
    echo 'DX_DEVICE = "m1"' >> conf/local.conf
    echo 'DX_PCIE = "deepx"' >> conf/local.conf
    echo 'IMAGE_INSTALL:append = " dx-rt dx-npu"' >> conf/local.conf
fi

echo "=== Starting Yocto build for rity-demo-image with DeepX support ==="
echo "Machine: grinn-genio-700-sbc"
echo "This will take 4-8 hours on first build..."
echo ""

# Start the build
bitbake rity-demo-image
