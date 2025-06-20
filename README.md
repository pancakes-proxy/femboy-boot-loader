# Femboy Boot Loader - Simple Bootloader with Auto Configuration

A lightweight, educational x86 bootloader that automatically detects and configures system hardware. Perfect for learning about low-level system programming and boot processes. Features femboy-themed branding with random inspirational quotes!

## Features

### Auto-Configuration
- **Memory Detection**: Uses BIOS INT 15h (E820h, E801h, 88h) to detect system memory
- **Drive Detection**: Automatically detects floppy drives and hard drives
- **CPU Identification**: Detects CPU vendor and features using CPUID when available
- **VGA Detection**: Identifies current video mode and capabilities

### User Experience
- **First Boot Setup**: Choose between Basic and Advanced modes on first run
- **Mode Switching**: Press F2 to change boot modes anytime
- **Colorized Output**: Different colors for headers, success, error, and warning messages
- **Random Quotes**: Inspirational femboy quotes displayed at boot
- **Boot Countdown**: Configurable timeout with interrupt capability
- **Error Recovery**: Retry logic for disk operations and alternative boot methods
- **Dual Modes**: Basic mode for fast boot, Advanced mode for full features

### Customization
- **Configuration File**: Easy customization through `config.inc`
- **Flexible Loading**: Configurable kernel load address and sector count
- **Debug Options**: Built-in debugging and verbose output modes

## Quick Start

### Prerequisites

Install the required tools:

```bash
# Ubuntu/Debian
make install-deps

# Arch Linux  
make install-deps-arch

# macOS
make install-deps-mac
```

### Build and Test

```bash
# Build the bootloader
make

# Test in QEMU
make test

# Test without graphics (useful for headless systems)
make test-nographic
```

### Create Test Kernel

```bash
# Add a simple test kernel to the disk image
make test-kernel
make test
```

## Boot Modes

### Basic Mode
- Fast boot with minimal hardware detection
- 3-second countdown
- Simple memory detection only
- Clean, minimal interface
- Perfect for quick boots

### Advanced Mode
- Full hardware detection and configuration display
- Boot menu with multiple options
- Detailed system information
- 5-second countdown with menu options
- Complete feature set

### Mode Selection
- **First Boot**: Setup wizard automatically appears
- **F2 Key**: Press during boot to change modes
- **CMOS Storage**: Mode preference saved between boots

## File Structure

```
fembootloader/
├── bootloader.asm          # Basic bootloader source
├── bootloader_enhanced.asm # Enhanced bootloader with dual modes
├── config.inc              # Configuration options
├── example_kernel.asm      # Example kernel with commands
├── Makefile               # Build system
├── test.sh                # Test script
└── README.md              # This file
```

## Configuration Options

Edit `config.inc` to customize bootloader behavior:

### Boot Settings
```assembly
%define BOOT_TIMEOUT 5          ; Auto-boot countdown (seconds)
%define DEFAULT_BOOT_DEVICE 0x80 ; Boot device (0x00=floppy, 0x80=HDD)
```

### Memory Settings
```assembly
%define MEMORY_MAP_ENTRIES 20   ; Max memory regions to detect
%define STACK_SEGMENT 0x7C00    ; Stack location
```

### Display Settings
```assembly
%define SHOW_MEMORY_MAP 1       ; Show detailed memory info
%define SHOW_DRIVE_DETAILS 1    ; Show drive geometry
%define VERBOSE_BOOT 1          ; Detailed boot messages
```

### Kernel Loading
```assembly
%define KERNEL_LOAD_SEGMENT 0x8000  ; Where to load kernel
%define KERNEL_START_SECTOR 2       ; Kernel location on disk
%define KERNEL_SECTORS 1            ; Kernel size in sectors
```

## Build Targets

| Target | Description |
|--------|-------------|
| `make` or `make all` | Build bootloader and disk image |
| `make test` | Test with QEMU (graphical) |
| `make test-nographic` | Test with QEMU (text only) |
| `make test-kernel` | Add simple test kernel |
| `make clean` | Remove build artifacts |
| `make info` | Show disk image information |
| `make usb DEVICE=/dev/sdX` | Create bootable USB (Linux) |
| `make help` | Show all available targets |

## Auto-Detection Details

### Memory Detection
1. **INT 15h, EAX=E820h**: Modern memory map detection
2. **INT 15h, AX=E801h**: Extended memory detection (fallback)
3. **INT 15h, AH=88h**: Legacy memory detection (final fallback)

### Drive Detection
- Scans floppy drives (0x00-0x03)
- Scans hard drives (0x80-0x8F)
- Reports drive count and basic geometry

### CPU Detection
- Tests CPUID availability
- Reads CPU vendor string (Intel, AMD, etc.)
- Detects CPU features when available
- Falls back to "Legacy CPU" for older processors

## Creating a Bootable USB

**⚠️ WARNING: This will erase all data on the target device!**

```bash
# Find your USB device
lsblk

# Create bootable USB (replace /dev/sdX with your device)
make usb DEVICE=/dev/sdX
```

## Kernel Development

The bootloader loads a kernel from sector 2 of the boot device. Your kernel should:

1. Be compiled as a flat binary
2. Have an entry point at the beginning
3. Be placed at the configured load address (default: 0x8000)

Example minimal kernel:
```assembly
[BITS 16]
[ORG 0x8000]

kernel_start:
    mov si, kernel_msg
    call print_string
    jmp $

print_string:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp print_string
.done:
    ret

kernel_msg db 'Hello from kernel!', 13, 10, 0
```

## Troubleshooting

### Build Issues
- Ensure NASM is installed: `nasm --version`
- Check file permissions: `ls -la *.asm`

### QEMU Issues
- Install QEMU: `qemu-system-x86_64 --version`
- Try text mode: `make test-nographic`

### Boot Issues
- Check disk image: `make info`
- Verify boot signature: `hexdump -C boot.img | head -32`

## Technical Details

### Memory Layout
- **0x7C00-0x7DFF**: Bootloader code and data
- **0x8000+**: Kernel load area (configurable)
- **Stack**: Grows down from 0x7C00

### Boot Process
1. BIOS loads bootloader at 0x7C00
2. Initialize segments and stack
3. Auto-detect hardware
4. Display configuration
5. Boot countdown
6. Load kernel from disk
7. Jump to kernel

## Contributing

This is an educational project. Feel free to:
- Add new auto-detection features
- Improve error handling
- Add support for different file systems
- Create example kernels

## License

This project is released into the public domain. Use it for learning, teaching, or as a base for your own bootloader projects.

## References

- [OSDev Wiki](https://wiki.osdev.org/)
- [Intel Software Developer Manuals](https://software.intel.com/content/www/us/en/develop/articles/intel-sdm.html)
- [BIOS Interrupt Reference](http://www.ctyme.com/intr/int.htm)
