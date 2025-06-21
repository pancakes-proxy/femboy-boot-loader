#!/bin/bash

echo "=== Femboy Bootloader Comparison ==="
echo

# Build both bootloaders
echo "Building simple bootloader..."
make clean > /dev/null 2>&1
make bootloader.bin > /dev/null 2>&1

echo "Building enhanced two-stage bootloader..."
make enhanced > /dev/null 2>&1

echo
echo "=== Size Comparison ==="
echo

if [ -f "bootloader.bin" ]; then
    simple_size=$(stat -c%s bootloader.bin)
    echo "Simple Bootloader:     $simple_size bytes (fits in 512-byte boot sector)"
else
    echo "Simple Bootloader:     NOT BUILT"
fi

if [ -f "bootloader_stage1.bin" ] && [ -f "bootloader_enhanced.bin" ]; then
    stage1_size=$(stat -c%s bootloader_stage1.bin)
    stage2_size=$(stat -c%s bootloader_enhanced.bin)
    total_size=$((stage1_size + stage2_size))
    echo "Enhanced Stage 1:      $stage1_size bytes (fits in 512-byte boot sector)"
    echo "Enhanced Stage 2:      $stage2_size bytes (NO SIZE LIMIT!)"
    echo "Enhanced Total:        $total_size bytes"
else
    echo "Enhanced Bootloader:   NOT BUILT"
fi

echo
echo "=== Feature Comparison ==="
echo

echo "Simple Bootloader Features:"
echo "  ✓ Basic femboy branding"
echo "  ✓ Random quotes (4 quotes)"
echo "  ✓ Simple countdown"
echo "  ✓ Kernel loading"
echo "  ✗ Hardware detection"
echo "  ✗ Boot menu"
echo "  ✗ BIOS setup access"
echo "  ✗ Advanced configuration"

echo
echo "Enhanced Bootloader Features:"
echo "  ✓ Full femboy branding"
echo "  ✓ Random quotes (8 quotes)"
echo "  ✓ Advanced boot menu"
echo "  ✓ Hardware detection (CPU, Memory, Drives)"
echo "  ✓ BIOS setup access"
echo "  ✓ System reboot functionality"
echo "  ✓ First boot setup wizard"
echo "  ✓ Mode switching (Basic/Advanced)"
echo "  ✓ Retry logic for kernel loading"
echo "  ✓ Color-coded output"
echo "  ✓ Verbose boot options"

echo
echo "=== Disk Images ==="
echo

# Create disk images if they don't exist
if [ ! -f "boot.img" ]; then
    make boot.img > /dev/null 2>&1
fi

if [ ! -f "enhanced_boot.img" ]; then
    make enhanced-image > /dev/null 2>&1
fi

if [ -f "boot.img" ]; then
    echo "Simple disk image:     boot.img ($(stat -c%s boot.img) bytes)"
fi

if [ -f "enhanced_boot.img" ]; then
    echo "Enhanced disk image:   enhanced_boot.img ($(stat -c%s enhanced_boot.img) bytes)"
fi

echo
echo "=== How to Test ==="
echo "1. Install QEMU: sudo apt-get install qemu-system-x86"
echo "2. Test simple:  make test"
echo "3. Test enhanced: make test-enhanced"
echo
echo "=== Bypassing 512-byte Limit ==="
echo "The enhanced bootloader uses a two-stage approach:"
echo "• Stage 1 (512 bytes): Minimal loader that fits in boot sector"
echo "• Stage 2 (unlimited): Full-featured bootloader loaded from disk"
echo "This allows unlimited features while maintaining boot compatibility!"
