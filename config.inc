; Bootloader Configuration File
; Include this file in bootloader.asm to customize behavior

; Boot configuration
%define BOOT_TIMEOUT 5          ; Seconds to wait before auto-boot
%define DEFAULT_BOOT_DEVICE 0x80 ; 0x00 = floppy, 0x80 = first HDD

; Memory configuration
%define MEMORY_MAP_ENTRIES 20   ; Maximum memory map entries to store
%define STACK_SEGMENT 0x7C00    ; Stack pointer location

; Display configuration
%define SHOW_MEMORY_MAP 1       ; 1 = show detailed memory map, 0 = summary only
%define SHOW_DRIVE_DETAILS 1    ; 1 = show drive geometry, 0 = count only
%define SHOW_CPU_FEATURES 1     ; 1 = show CPU features, 0 = vendor only

; Kernel loading configuration
%define KERNEL_LOAD_SEGMENT 0x8000  ; Where to load the kernel
%define KERNEL_START_SECTOR 2       ; Which sector contains the kernel
%define KERNEL_SECTORS 1            ; How many sectors to load

; Auto-detection features
%define AUTO_DETECT_MEMORY 1    ; 1 = detect memory, 0 = skip
%define AUTO_DETECT_DRIVES 1    ; 1 = detect drives, 0 = skip  
%define AUTO_DETECT_CPU 1       ; 1 = detect CPU, 0 = skip
%define AUTO_DETECT_VGA 1       ; 1 = detect VGA modes, 0 = skip

; Error handling
%define HALT_ON_ERROR 1         ; 1 = halt on error, 0 = continue
%define RETRY_COUNT 3           ; Number of retries for disk operations

; Debug options
%define DEBUG_MODE 0            ; 1 = enable debug output, 0 = normal
%define VERBOSE_BOOT 1          ; 1 = show detailed boot process, 0 = minimal

; Color scheme (VGA text mode colors)
%define COLOR_NORMAL 0x07       ; White on black
%define COLOR_HEADER 0x0F       ; Bright white on black  
%define COLOR_SUCCESS 0x0A      ; Bright green on black
%define COLOR_ERROR 0x0C        ; Bright red on black
%define COLOR_WARNING 0x0E      ; Yellow on black
