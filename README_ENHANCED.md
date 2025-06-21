# Enhanced Femboy Bootloader - Bypassing the 512-Byte Limit

## 🎀 Overview

This project demonstrates how to bypass the traditional 512-byte bootloader limit using a **two-stage bootloader architecture**. The enhanced femboy bootloader provides unlimited features while maintaining boot sector compatibility.

## 🚀 Solution: Two-Stage Architecture

### The Problem
- Traditional bootloaders are limited to 512 bytes (boot sector size)
- Complex features require more space than available
- Original enhanced bootloader was ~4,686 bytes (too large!)

### The Solution
**Two-Stage Bootloader:**
1. **Stage 1** (512 bytes): Minimal loader that fits in boot sector
2. **Stage 2** (unlimited): Full-featured bootloader loaded from disk

## 📁 File Structure

```
├── bootloader.asm              # Simple bootloader (512 bytes)
├── bootloader_stage1.asm       # Stage 1 loader (512 bytes)
├── bootloader_enhanced.asm     # Stage 2 enhanced bootloader (4,686 bytes)
├── config.inc                  # Configuration file
├── Makefile                    # Build system
├── compare_bootloaders.sh      # Comparison script
└── README_ENHANCED.md          # This file
```

## 🔧 Building

### Simple Bootloader
```bash
make clean
make bootloader.bin    # Creates 512-byte simple bootloader
make boot.img          # Creates bootable disk image
```

### Enhanced Two-Stage Bootloader
```bash
make enhanced          # Builds both Stage 1 and Stage 2
make enhanced-image    # Creates bootable disk image
```

### Compare Both
```bash
./compare_bootloaders.sh
```

## 📊 Size Comparison

| Bootloader | Stage 1 | Stage 2 | Total | Limit |
|------------|---------|---------|-------|-------|
| Simple     | 512 bytes | N/A | 512 bytes | ✅ Fits |
| Enhanced   | 512 bytes | 4,686 bytes | 5,198 bytes | ✅ No limit! |

## ✨ Feature Comparison

### Simple Bootloader
- ✅ Basic femboy branding
- ✅ Random quotes (4 quotes)
- ✅ Simple countdown
- ✅ Kernel loading
- ❌ Hardware detection
- ❌ Boot menu
- ❌ BIOS setup access

### Enhanced Bootloader
- ✅ Full femboy branding
- ✅ Random quotes (8 quotes)
- ✅ Advanced boot menu
- ✅ Hardware detection (CPU, Memory, Drives)
- ✅ BIOS setup access
- ✅ System reboot functionality
- ✅ First boot setup wizard
- ✅ Mode switching (Basic/Advanced)
- ✅ Retry logic for kernel loading
- ✅ Color-coded output
- ✅ Verbose boot options

## 🎯 How It Works

### Stage 1 Bootloader
```assembly
; Load Stage 2 from disk
mov ah, 0x02                ; Read sectors
mov al, 16                  ; Number of sectors (8KB)
mov ch, 0                   ; Cylinder 0
mov cl, 2                   ; Starting sector 2
mov dh, 0                   ; Head 0
mov dl, [boot_drive]        ; Drive
mov bx, 0x1000             ; Load address
int 0x13                   ; BIOS disk interrupt

; Jump to Stage 2
jmp 0x1000
```

### Stage 2 Bootloader
- Loaded at memory address `0x1000`
- No size restrictions
- Full feature set available
- Can be multiple sectors (up to 64KB easily)

## 🧪 Testing

### Prerequisites
```bash
# Ubuntu/Debian
sudo apt-get install nasm qemu-system-x86

# Arch Linux
sudo pacman -S nasm qemu

# macOS
brew install nasm qemu
```

### Run Tests
```bash
# Test simple bootloader
make test

# Test enhanced bootloader
make test-enhanced

# Test without QEMU (just build)
make enhanced-image
```

## 🔍 Technical Details

### Memory Layout
```
0x0000:0x7C00  - Stage 1 bootloader (loaded by BIOS)
0x0000:0x1000  - Stage 2 bootloader (loaded by Stage 1)
0x0000:0x2000  - Kernel (loaded by Stage 2)
0x0000:0x7000  - Stack
```

### Disk Layout
```
Sector 0:      Stage 1 bootloader (512 bytes)
Sectors 1-16:  Stage 2 bootloader (up to 8KB)
Sectors 17+:   Kernel and other data
```

## 🎨 Customization

### Adding Features to Stage 2
Since Stage 2 has no size limit, you can add:
- Graphics mode support
- File system drivers
- Network boot capabilities
- Advanced hardware detection
- Interactive configuration menus
- Multiple kernel support

### Configuration
Edit `config.inc` to customize:
- Memory detection options
- Boot timeout values
- Color schemes
- Feature toggles

## 🚀 Alternative Approaches

### 1. Multi-Stage (Current Solution)
- **Pros**: Unlimited size, maintains compatibility
- **Cons**: Slightly more complex

### 2. Extended Boot Record
- Use multiple sectors for bootloader
- **Pros**: Simpler than multi-stage
- **Cons**: Less compatible with some systems

### 3. UEFI Boot
- Modern systems support larger boot files
- **Pros**: No size limits, modern features
- **Cons**: Not compatible with legacy BIOS

## 🎯 Conclusion

The two-stage approach successfully bypasses the 512-byte limit while maintaining full compatibility with legacy BIOS systems. This allows for:

- **Unlimited features** in Stage 2
- **Full boot sector compatibility** with Stage 1
- **Gradual loading** of complex functionality
- **Maintainable code structure**

The enhanced femboy bootloader now supports all desired features without size constraints! 🎀✨
