#!/bin/sh
export PATH=/sbin:/usr/sbin:/bin:/usr/bin:$PATH
echo '=== Attempting insmod dx_dma ==='
insmod /lib/modules/5.15.47-mtk+gd011e19cfc68/extra/dx_dma.ko 2>&1
echo "dx_dma exit: $?"
echo '=== Attempting insmod dxrt_driver ==='
insmod /lib/modules/5.15.47-mtk+gd011e19cfc68/extra/dxrt_driver.ko 2>&1
echo "dxrt_driver exit: $?"
echo '=== Loaded modules with dx ==='
cat /proc/modules | grep dx
echo '=== Last 30 dmesg lines ==='
dmesg | tail -30
