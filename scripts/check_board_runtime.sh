#!/bin/bash
# Check if DeepX runtime is already installed on board

echo "=== Checking for existing DeepX runtime on board ==="
echo ""

echo "1. Python dxrt module:"
sshpass -p '' ssh -o StrictHostKeyChecking=no root@192.168.50.31 << 'EOF'
python3 -c "import dxrt; print('dxrt version:', dxrt.__version__)" 2>&1 || echo "dxrt not installed"
EOF

echo ""
echo "2. DeepX files in common locations:"
sshpass -p '' ssh -o StrictHostKeyChecking=no root@192.168.50.31 << 'EOF'
find /opt -name "*dxrt*" -o -name "*deepx*" 2>/dev/null | head -20
find /usr/lib -name "*dxrt*" -o -name "*deepx*" 2>/dev/null | head -20
find /usr/local -name "*dxrt*" 2>/dev/null | head -10
EOF

echo ""
echo "3. Installed opkg packages:"
sshpass -p '' ssh -o StrictHostKeyChecking=no root@192.168.50.31 << 'EOF'
opkg list-installed | grep -i deepx
opkg list-installed | grep -i dx
EOF

echo ""
echo "4. Python site-packages:"
sshpass -p '' ssh -o StrictHostKeyChecking=no root@192.168.50.31 << 'EOF'
find /usr/lib/python3.10 -name "*dxrt*" -o -name "*deepx*" 2>/dev/null
EOF
