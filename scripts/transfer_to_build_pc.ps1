# Transfer package to build PC at 10.181.153.96
# This script handles large file transfer with progress indication

$sourcePath = "C:\Users\dvir\genio700-deepx-yocto.tar.gz"
$targetUser = "nisko"
$targetHost = "10.181.153.96"
$targetPath = "/home/nisko/yocto\ compile/grinn\ deepx/"

Write-Host "=== Transfer to Build PC ===" -ForegroundColor Cyan
Write-Host "Source: $sourcePath"
Write-Host "Target: ${targetUser}@${targetHost}:${targetPath}"
Write-Host ""

# Check if source file exists
if (-not (Test-Path $sourcePath)) {
    Write-Host "ERROR: Source file not found: $sourcePath" -ForegroundColor Red
    exit 1
}

$fileSize = (Get-Item $sourcePath).Length / 1GB
Write-Host "File size: $([math]::Round($fileSize, 2)) GB"
Write-Host ""

# Use SCP for transfer
Write-Host "Starting transfer..." -ForegroundColor Yellow
Write-Host "Note: This may take 20-40 minutes depending on network speed"
Write-Host ""

scp "$sourcePath" "${targetUser}@${targetHost}:${targetPath}"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=== Transfer Complete ===" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "1. SSH to build PC: ssh nisko@10.181.153.96"
    Write-Host "2. Navigate: cd '/home/nisko/yocto compile/grinn deepx'"
    Write-Host "3. Extract: tar -xzf genio700-deepx-yocto.tar.gz"
    Write-Host "4. Follow YOCTO_BUILD_GUIDE.md"
} else {
    Write-Host ""
    Write-Host "=== Transfer Failed ===" -ForegroundColor Red
    Write-Host "Exit code: $LASTEXITCODE"
    Write-Host ""
    Write-Host "Alternative: Use USB drive or split the file"
}
