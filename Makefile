# Simple Bootloader Makefile

# Tools
ASM = nasm
DD = dd
QEMU = qemu-system-x86_64

# Flags
ASMFLAGS = -f bin

# Files
BOOTLOADER_SRC = bootloader.asm
BOOTLOADER_BIN = bootloader.bin
DISK_IMG = boot.img

# Default target
all: $(DISK_IMG)

# Build bootloader binary
$(BOOTLOADER_BIN): $(BOOTLOADER_SRC)
	@echo "Assembling bootloader..."
	$(ASM) $(ASMFLAGS) $(BOOTLOADER_SRC) -o $(BOOTLOADER_BIN)
	@echo "Bootloader assembled successfully!"

# Create disk image
$(DISK_IMG): $(BOOTLOADER_BIN)
	@echo "Creating disk image..."
	$(DD) if=/dev/zero of=$(DISK_IMG) bs=512 count=2880 2>/dev/null
	$(DD) if=$(BOOTLOADER_BIN) of=$(DISK_IMG) conv=notrunc 2>/dev/null
	@echo "Disk image created: $(DISK_IMG)"

# Test with QEMU
test: $(DISK_IMG)
	@echo "Starting QEMU..."
	$(QEMU) -fda $(DISK_IMG) -boot a

# Test with QEMU (no graphics)
test-nographic: $(DISK_IMG)
	@echo "Starting QEMU (no graphics)..."
	$(QEMU) -fda $(DISK_IMG) -boot a -nographic

# Create a simple kernel for testing
test-kernel:
	@echo "Creating test kernel..."
	@echo -e "\x90\x90\x90\x90" > kernel.bin
	$(DD) if=kernel.bin of=$(DISK_IMG) bs=512 seek=1 conv=notrunc 2>/dev/null
	@echo "Test kernel added to disk image"

# Build example kernel
example-kernel: example_kernel.asm
	@echo "Building example kernel..."
	$(ASM) $(ASMFLAGS) example_kernel.asm -o example_kernel.bin
	@echo "Example kernel built successfully!"

# Test with example kernel
test-example: $(DISK_IMG) example-kernel
	@echo "Adding example kernel to disk image..."
	$(DD) if=example_kernel.bin of=$(DISK_IMG) bs=512 seek=1 conv=notrunc 2>/dev/null
	@echo "Testing bootloader with example kernel..."
	$(QEMU) -fda $(DISK_IMG) -boot a

# Build two-stage enhanced bootloader
enhanced: bootloader_stage1.asm bootloader_enhanced.asm
	@echo "Building two-stage enhanced bootloader..."
	@echo "Building Stage 1..."
	$(ASM) $(ASMFLAGS) bootloader_stage1.asm -o bootloader_stage1.bin
	@echo "Building Stage 2 (enhanced)..."
	$(ASM) $(ASMFLAGS) bootloader_enhanced.asm -o bootloader_enhanced.bin
	@echo "Two-stage enhanced bootloader built successfully!"

# Create enhanced disk image
enhanced-image: enhanced
	@echo "Creating enhanced disk image..."
	$(DD) if=/dev/zero of=enhanced_boot.img bs=512 count=2880 2>/dev/null
	@echo "Writing Stage 1 to boot sector..."
	$(DD) if=bootloader_stage1.bin of=enhanced_boot.img conv=notrunc 2>/dev/null
	@echo "Writing Stage 2 starting at sector 2..."
	$(DD) if=bootloader_enhanced.bin of=enhanced_boot.img bs=512 seek=1 conv=notrunc 2>/dev/null
	@echo "Enhanced disk image created: enhanced_boot.img"

# Test enhanced bootloader
test-enhanced: enhanced-image
	@echo "Testing enhanced bootloader..."
	$(QEMU) -fda enhanced_boot.img -boot a

# Clean build artifacts
clean:
	@echo "Cleaning..."
	rm -f $(BOOTLOADER_BIN) $(DISK_IMG) kernel.bin bootloader_enhanced.bin bootloader_stage1.bin enhanced_boot.img example_kernel.bin bootloader_simple.bin
	@echo "Clean complete!"

# Install dependencies (Ubuntu/Debian)
install-deps:
	@echo "Installing dependencies..."
	sudo apt-get update
	sudo apt-get install -y nasm qemu-system-x86

# Install dependencies (Arch Linux)
install-deps-arch:
	@echo "Installing dependencies..."
	sudo pacman -S nasm qemu

# Install dependencies (macOS)
install-deps-mac:
	@echo "Installing dependencies..."
	brew install nasm qemu

# UEFI bootloader targets
uefi:
	@echo "Building UEFI femboy bootloader..."
	$(MAKE) -f Makefile.uefi all

test-uefi:
	@echo "Testing UEFI bootloader..."
	$(MAKE) -f Makefile.uefi test-uefi

hybrid:
	@echo "Creating hybrid BIOS+UEFI image..."
	$(MAKE) -f Makefile.uefi hybrid-image

install-uefi-deps:
	@echo "Installing UEFI development dependencies..."
	$(MAKE) -f Makefile.uefi install-deps

# Show disk image info
info: $(DISK_IMG)
	@echo "Disk image information:"
	@ls -la $(DISK_IMG)
	@echo "First 512 bytes (hex dump):"
	@hexdump -C $(DISK_IMG) | head -32

# Create bootable USB (Linux only - BE CAREFUL!)
# Usage: make usb DEVICE=/dev/sdX
usb: $(DISK_IMG)
ifndef DEVICE
	@echo "Error: Please specify DEVICE=/dev/sdX"
	@echo "Example: make usb DEVICE=/dev/sdb"
	@echo "WARNING: This will overwrite the entire device!"
	@exit 1
endif
	@echo "WARNING: This will overwrite $(DEVICE)!"
	@echo "Press Ctrl+C to cancel, or Enter to continue..."
	@read
	sudo $(DD) if=$(DISK_IMG) of=$(DEVICE) bs=512

# Help
help:
	@echo "Available targets:"
	@echo "  all              - Build bootloader and disk image (default)"
	@echo "  test             - Test bootloader with QEMU"
	@echo "  test-nographic   - Test bootloader with QEMU (no graphics)"
	@echo "  test-kernel      - Add a simple test kernel to disk image"
	@echo "  example-kernel   - Build example kernel"
	@echo "  test-example     - Test bootloader with example kernel"
	@echo "  enhanced         - Build two-stage enhanced bootloader"
	@echo "  enhanced-image   - Create enhanced disk image"
	@echo "  test-enhanced    - Test enhanced bootloader"
	@echo "  uefi             - Build UEFI femboy bootloader"
	@echo "  test-uefi        - Test UEFI bootloader"
	@echo "  hybrid           - Create hybrid BIOS+UEFI image"
	@echo "  install-uefi-deps- Install UEFI development dependencies"
	@echo "  clean            - Remove build artifacts"
	@echo "  install-deps     - Install dependencies (Ubuntu/Debian)"
	@echo "  install-deps-arch- Install dependencies (Arch Linux)"
	@echo "  install-deps-mac - Install dependencies (macOS)"
	@echo "  info             - Show disk image information"
	@echo "  usb              - Create bootable USB (Linux only)"
	@echo "  help             - Show this help"

.PHONY: all test test-nographic test-kernel example-kernel test-example enhanced enhanced-image test-enhanced uefi test-uefi hybrid install-uefi-deps clean install-deps install-deps-arch install-deps-mac info usb help
