# Recover Grinn GenioSBC-700 board using genio-flash tool
# This is the CORRECT method for flashing the vendor image

Write-Host "=== Grinn GenioSBC-700 Recovery with genio-flash ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Install genio-tools
Write-Host "Step 1: Installing genio-tools..." -ForegroundColor Yellow
pip3 install -U genio-tools

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to install genio-tools" -ForegroundColor Red
    Write-Host "Try installing dependencies first:" -ForegroundColor Yellow
    Write-Host "pip3 install wheel setuptools_scm gpiod libusb1 packaging pyserial pyftdi pyusb pyyaml pyparsing enum34 oyaml windows-curses"
    exit 1
}

# Step 2: Verify installation
Write-Host ""
Write-Host "Step 2: Verifying genio-tools installation..." -ForegroundColor Yellow
genio-config

# Step 3: Install fastboot (if not already installed)
Write-Host ""
Write-Host "Step 3: Checking fastboot..." -ForegroundColor Yellow
$fastbootVersion = fastboot --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Fastboot not found. Please install Android Platform Tools:" -ForegroundColor Red
    Write-Host "Download from: https://developer.android.com/studio/releases/platform-tools"
    exit 1
}
Write-Host "Fastboot version: $fastbootVersion"

# Step 4: Navigate to image directory
Write-Host ""
Write-Host "Step 4: Navigating to image directory..." -ForegroundColor Yellow
$imagePath = "C:\Users\dvir\OneDrive - Data JCE Electronics LTD\Desktop\NISKO\vendors\grinn\grinn genio 700 + deepx 3.2.0 rntime\rity-demo-image-grinn-genio-700-sbc-20260325125533"

if (-not (Test-Path $imagePath)) {
    Write-Host "ERROR: Image directory not found: $imagePath" -ForegroundColor Red
    exit 1
}

Set-Location $imagePath
Write-Host "Image directory: $imagePath"

# Step 5: Instructions for entering download mode
Write-Host ""
Write-Host "=== IMPORTANT: Put Board in Download Mode ===" -ForegroundColor Red
Write-Host ""
Write-Host "To enter Download Mode on Grinn GenioSBC-700:" -ForegroundColor Yellow
Write-Host "1. Power off the board completely (unplug power)"
Write-Host "2. Connect USB cable from board to PC"
Write-Host "3. While holding Volume Down button (or both volume buttons):"
Write-Host "   - Plug in power to the board"
Write-Host "   - Keep holding for 5-10 seconds"
Write-Host "4. Board should enter Download Mode"
Write-Host ""
Write-Host "Alternative: If board has a 'Download' or 'Recovery' button, hold it while powering on"
Write-Host ""
$ready = Read-Host "Is the board in Download Mode and connected via USB? (yes/no)"

if ($ready -ne "yes") {
    Write-Host "Please put board in Download Mode first, then run this script again." -ForegroundColor Yellow
    exit 0
}

# Step 6: Check if board is detected
Write-Host ""
Write-Host "Step 6: Checking if board is detected..." -ForegroundColor Yellow
fastboot devices

if ($LASTEXITCODE -ne 0) {
    Write-Host "WARNING: Board not detected in fastboot mode" -ForegroundColor Yellow
    Write-Host "The board may be in Download Mode (not fastboot mode)"
    Write-Host "genio-flash will handle this automatically"
}

# Step 7: Flash with genio-flash
Write-Host ""
Write-Host "Step 7: Flashing image with genio-flash..." -ForegroundColor Yellow
Write-Host "This will take 5-10 minutes..."
Write-Host ""

genio-flash --image rity-demo-image

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=== Flash Complete! ===" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "1. Disconnect USB cable"
    Write-Host "2. Power cycle the board"
    Write-Host "3. Wait 1-2 minutes for boot"
    Write-Host "4. Test SSH: ssh root@192.168.50.31"
    Write-Host "5. Verify DeepX: python3 -c 'import dxrt; print(\"DeepX OK\")'"
} else {
    Write-Host ""
    Write-Host "=== Flash Failed ===" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:"
    Write-Host "1. Ensure board is in Download Mode (not normal boot)"
    Write-Host "2. Try different USB port (USB 2.0 preferred)"
    Write-Host "3. Check USB cable (use data cable, not charge-only)"
    Write-Host "4. Install MediaTek USB drivers if on Windows"
    Write-Host "5. Try running as Administrator"
    Write-Host ""
    Write-Host "For serial console access, connect UART at 115200 8N1"
}
