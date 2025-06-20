#!/bin/bash

# FemBootloader Test Script
# Builds and tests the bootloader

set -e

echo "=== FemBootloader Test Script ==="
echo

# Check dependencies
echo "Checking dependencies..."
if ! command -v nasm &> /dev/null; then
    echo "Error: NASM not found. Please install it first:"
    echo "  Ubuntu/Debian: sudo apt-get install nasm"
    echo "  Arch Linux: sudo pacman -S nasm"
    echo "  macOS: brew install nasm"
    exit 1
fi

if ! command -v qemu-system-x86_64 &> /dev/null; then
    echo "Warning: QEMU not found. Install it to test the bootloader:"
    echo "  Ubuntu/Debian: sudo apt-get install qemu-system-x86"
    echo "  Arch Linux: sudo pacman -S qemu"
    echo "  macOS: brew install qemu"
    echo
fi

echo "Dependencies OK!"
echo

# Build basic bootloader
echo "Building basic bootloader..."
make clean
make bootloader.bin
echo "Basic bootloader built successfully!"
echo

# Build enhanced bootloader
echo "Building enhanced bootloader..."
nasm -f bin bootloader_enhanced.asm -o bootloader_enhanced.bin
echo "Enhanced bootloader built successfully!"
echo

# Create disk images
echo "Creating disk images..."
dd if=/dev/zero of=basic_boot.img bs=512 count=2880 2>/dev/null
dd if=bootloader.bin of=basic_boot.img conv=notrunc 2>/dev/null

dd if=/dev/zero of=enhanced_boot.img bs=512 count=2880 2>/dev/null  
dd if=bootloader_enhanced.bin of=enhanced_boot.img conv=notrunc 2>/dev/null
echo "Disk images created!"
echo

# Show disk info
echo "Disk image information:"
ls -la *.img
echo

echo "Bootloader signature check:"
echo "Basic bootloader:"
hexdump -C basic_boot.img | tail -1
echo "Enhanced bootloader:"  
hexdump -C enhanced_boot.img | tail -1
echo

# Test with QEMU if available
if command -v qemu-system-x86_64 &> /dev/null; then
    echo "QEMU found! You can test the bootloaders with:"
    echo "  Basic: qemu-system-x86_64 -fda basic_boot.img -boot a"
    echo "  Enhanced: qemu-system-x86_64 -fda enhanced_boot.img -boot a"
    echo
    
    read -p "Test basic bootloader now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Starting basic bootloader test..."
        qemu-system-x86_64 -fda basic_boot.img -boot a
    fi
    
    read -p "Test enhanced bootloader now? (y/N): " -n 1 -r  
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Starting enhanced bootloader test..."
        qemu-system-x86_64 -fda enhanced_boot.img -boot a
    fi
else
    echo "QEMU not available. Install it to test the bootloaders."
fi

echo
echo "=== Test Complete ==="
echo "Files created:"
echo "  bootloader.bin - Basic bootloader binary"
echo "  bootloader_enhanced.bin - Enhanced bootloader binary"
echo "  basic_boot.img - Bootable disk image (basic)"
echo "  enhanced_boot.img - Bootable disk image (enhanced)"
echo
echo "Use 'make help' to see all available build targets."
