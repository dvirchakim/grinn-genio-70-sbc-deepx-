# Check board network configuration via serial console or direct connection

Write-Host "=== Grinn GenioSBC-700 Network Configuration Check ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "Your PC is on network: 192.168.10.x" -ForegroundColor Yellow
Write-Host "Board is expected at: 192.168.50.31" -ForegroundColor Yellow
Write-Host ""

Write-Host "Options to connect to the board:" -ForegroundColor Cyan
Write-Host ""

Write-Host "Option 1: Serial Console (Recommended)" -ForegroundColor Green
Write-Host "----------------------------------------"
Write-Host "1. Open PuTTY"
Write-Host "2. Connection type: Serial"
Write-Host "3. Serial line: COM7"
Write-Host "4. Speed: 115200"
Write-Host "5. Click Open"
Write-Host ""
Write-Host "Once connected, login as root (no password) and run:"
Write-Host "  ip addr show"
Write-Host "  ip route"
Write-Host ""
Write-Host "This will show the actual IP address the board has."
Write-Host ""

Write-Host "Option 2: Check Router DHCP Leases" -ForegroundColor Green
Write-Host "-----------------------------------"
Write-Host "1. Login to your router/switch"
Write-Host "2. Check DHCP client list"
Write-Host "3. Look for device named 'grinn-genio-700-sbc'"
Write-Host "4. Note the IP address it was assigned"
Write-Host ""

Write-Host "Option 3: Network Scan" -ForegroundColor Green
Write-Host "----------------------"
Write-Host "If you have nmap installed:"
Write-Host "  nmap -sn 192.168.50.0/24"
Write-Host "  nmap -sn 192.168.10.0/24"
Write-Host ""

Write-Host "Option 4: Direct Connection" -ForegroundColor Green
Write-Host "---------------------------"
Write-Host "1. Connect board directly to your PC with ethernet cable"
Write-Host "2. Set your PC's ethernet adapter to:"
Write-Host "   IP: 192.168.50.1"
Write-Host "   Subnet: 255.255.255.0"
Write-Host "3. Try: ssh root@192.168.50.31"
Write-Host ""

Write-Host "=== Most Likely Issue ===" -ForegroundColor Yellow
Write-Host ""
Write-Host "The board is probably on the 192.168.10.x network (same as your PC)"
Write-Host "but you're trying to reach it at 192.168.50.31"
Write-Host ""
Write-Host "Check your router's DHCP leases or use serial console to find the actual IP."
Write-Host ""

$choice = Read-Host "Would you like to open PuTTY for serial console? (yes/no)"

if ($choice -eq "yes") {
    # Check if PuTTY is installed
    $puttyPath = "C:\Program Files\PuTTY\putty.exe"
    if (Test-Path $puttyPath) {
        Write-Host "Opening PuTTY..." -ForegroundColor Green
        Start-Process $puttyPath -ArgumentList "-serial COM7 -sercfg 115200,8,n,1,N"
    } else {
        Write-Host "PuTTY not found at $puttyPath" -ForegroundColor Red
        Write-Host "Please install PuTTY or open your serial terminal manually"
        Write-Host "Settings: COM7, 115200, 8N1"
    }
}
