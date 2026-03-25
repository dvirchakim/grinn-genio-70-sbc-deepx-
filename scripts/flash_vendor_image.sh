#!/bin/bash
# Flash vendor-supplied complete image with DeepX 3.2.0 runtime to Grinn GenioSBC-700
# Image location: C:\Users\dvir\OneDrive - Data JCE Electronics LTD\Desktop\NISKO\vendors\grinn\grinn genio 700 + deepx 3.2.0 rntime

set -e

BOARD_IP="192.168.50.31"
BOARD_USER="root"
IMAGE_DIR="/mnt/c/Users/dvir/OneDrive - Data JCE Electronics LTD/Desktop/NISKO/vendors/grinn/grinn genio 700 + deepx 3.2.0 rntime/rity-demo-image-grinn-genio-700-sbc-20260325125533"
IMAGE_FILE="rity-demo-image-grinn-genio-700-sbc.wic.img"

echo "=== Grinn GenioSBC-700 Complete Image Flash ==="
echo "Board: $BOARD_IP"
echo "Image: DeepX 3.2.0 Runtime (vendor-supplied)"
echo ""

# Check board connectivity
echo "Step 1: Checking board connectivity..."
if ! ssh -o ConnectTimeout=5 $BOARD_USER@$BOARD_IP "echo 'Board connected'" 2>/dev/null; then
    echo "ERROR: Cannot connect to board at $BOARD_IP"
    echo "Please check:"
    echo "  - Board is powered on"
    echo "  - Network cable connected"
    echo "  - IP address is correct"
    exit 1
fi
echo "✓ Board is accessible"
echo ""

# Check current board status
echo "Step 2: Checking current board status..."
ssh $BOARD_USER@$BOARD_IP "uname -a && df -h / | tail -1"
echo ""

# Check image file exists
echo "Step 3: Verifying image file..."
if [ ! -f "$IMAGE_DIR/$IMAGE_FILE" ]; then
    echo "ERROR: Image file not found: $IMAGE_DIR/$IMAGE_FILE"
    exit 1
fi
IMAGE_SIZE=$(du -h "$IMAGE_DIR/$IMAGE_FILE" | cut -f1)
echo "✓ Image file found: $IMAGE_SIZE"
echo ""

# Transfer image to board
echo "Step 4: Transferring image to board..."
echo "This will take several minutes (2.5GB file)..."
scp "$IMAGE_DIR/$IMAGE_FILE" $BOARD_USER@$BOARD_IP:/tmp/
echo "✓ Image transferred"
echo ""

# Flash image to eMMC
echo "Step 5: Flashing image to eMMC..."
echo "WARNING: This will ERASE all data on the board!"
read -p "Continue? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Flash cancelled"
    exit 0
fi

ssh $BOARD_USER@$BOARD_IP << 'FLASH_EOF'
set -e

echo "Finding eMMC device..."
EMMC_DEV=$(lsblk -d -n -o NAME,TYPE | grep disk | grep mmcblk | head -1 | awk '{print $1}')
if [ -z "$EMMC_DEV" ]; then
    echo "ERROR: Cannot find eMMC device"
    exit 1
fi
EMMC_PATH="/dev/$EMMC_DEV"
echo "eMMC device: $EMMC_PATH"

echo "Unmounting any mounted partitions..."
umount ${EMMC_PATH}* 2>/dev/null || true

echo "Flashing image to $EMMC_PATH..."
dd if=/tmp/rity-demo-image-grinn-genio-700-sbc.wic.img of=$EMMC_PATH bs=4M status=progress conv=fsync

echo "Syncing..."
sync

echo "Cleaning up..."
rm /tmp/rity-demo-image-grinn-genio-700-sbc.wic.img

echo "✓ Flash complete"
FLASH_EOF

echo ""
echo "Step 6: Rebooting board..."
ssh $BOARD_USER@$BOARD_IP "reboot" || true

echo ""
echo "=== Flash Complete ==="
echo ""
echo "The board is rebooting with the new image."
echo "Wait 1-2 minutes for boot to complete."
echo ""
echo "Next steps:"
echo "1. Wait for board to boot (1-2 minutes)"
echo "2. SSH to board: ssh root@192.168.50.31"
echo "3. Verify DeepX runtime:"
echo "   - Check kernel modules: lsmod | grep dx"
echo "   - Check device: ls -l /dev/dxg*"
echo "   - Test Python: python3 -c 'import dxrt; print(\"DeepX OK\")'"
echo ""
