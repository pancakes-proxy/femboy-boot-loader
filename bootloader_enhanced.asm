; Enhanced Femboy Bootloader - Stage 2
; Full-featured bootloader (no 512-byte limit!)

[BITS 16]
[ORG 0x1000]

; Include configuration
%include "config.inc"

start_stage2:
    ; Store boot drive
    mov [boot_drive], dl

    ; Initialize segments
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, STACK_SEGMENT
    sti

    ; Set video mode and clear screen
    mov ax, 0x0003
    int 0x10

    ; Check for first boot or F2 key
    call check_boot_mode
    
    ; Set color attribute
    mov ah, 0x06        ; Scroll up
    mov al, 0           ; Clear entire screen
    mov bh, COLOR_NORMAL
    mov cx, 0           ; Upper left
    mov dx, 0x184F      ; Lower right (25x80)
    int 0x10

    ; Display boot header
    call set_header_color
    mov si, boot_header
    call print_string

    ; Display random femboy quote
    call display_random_quote
    call set_normal_color

%if VERBOSE_BOOT
    mov si, verbose_start_msg
    call print_string
%endif

    ; Auto-configuration phase
%if AUTO_DETECT_MEMORY
    call detect_memory_enhanced
%endif

%if AUTO_DETECT_DRIVES  
    call detect_drives_enhanced
%endif

%if AUTO_DETECT_CPU
    call detect_cpu_enhanced
%endif

%if AUTO_DETECT_VGA
    call detect_vga_modes
%endif

    ; Display configuration summary
    call display_enhanced_config
    
    ; Display menu options
    call display_boot_menu

    ; Handle user input
    call handle_boot_menu

    ; Load and execute kernel
    call load_kernel_enhanced
    
    ; Error handling
    call set_error_color
    mov si, critical_error_msg
    call print_string
    
%if HALT_ON_ERROR
    jmp halt
%else
    ; Try alternative boot methods
    call try_alternative_boot
%endif

; Enhanced memory detection with detailed reporting
detect_memory_enhanced:
%if VERBOSE_BOOT
    mov si, mem_detect_start_msg
    call print_string
%endif
    
    mov di, memory_map
    xor ebx, ebx
    mov edx, 0x534D4150
    xor bp, bp              ; Entry counter
    
.loop:
    mov eax, 0xE820
    mov ecx, 24
    int 0x15
    
    jc .error
    cmp eax, 0x534D4150
    jne .error
    
    ; Process entry
    inc bp
    add di, 24
    
    cmp bp, MEMORY_MAP_ENTRIES
    jge .done
    
    test ebx, ebx
    jz .done
    jmp .loop
    
.error:
    ; Fallback to INT 15h, AX=E801h
    mov ax, 0xE801
    int 0x15
    jc .legacy_detect
    ; Store extended memory info
    mov [extended_mem_1m], ax
    mov [extended_mem_16m], bx
    jmp .done
    
.legacy_detect:
    ; Fallback to INT 15h, AH=88h
    mov ah, 0x88
    int 0x15
    mov [legacy_mem_kb], ax
    
.done:
    mov [memory_entries], bp
    ret

; Enhanced drive detection
detect_drives_enhanced:
%if VERBOSE_BOOT
    mov si, drive_detect_start_msg
    call print_string
%endif
    
    ; Reset drive counters
    mov byte [floppy_count], 0
    mov byte [hdd_count], 0
    
    ; Check floppy drives (0x00-0x03)
    mov dl, 0x00
.check_floppy:
    mov ah, 0x08
    int 0x13
    jc .check_hdd_start
    inc byte [floppy_count]
    inc dl
    cmp dl, 0x04
    jl .check_floppy
    
.check_hdd_start:
    ; Check hard drives (0x80-0x8F)
    mov dl, 0x80
.check_hdd:
    mov ah, 0x08
    int 0x13
    jc .drives_done
    inc byte [hdd_count]
    inc dl
    cmp dl, 0x90
    jl .check_hdd
    
.drives_done:
    ret

; Enhanced CPU detection
detect_cpu_enhanced:
%if VERBOSE_BOOT
    mov si, cpu_detect_start_msg
    call print_string
%endif
    
    ; Test for CPUID availability
    pushf
    pop ax
    mov cx, ax
    xor ax, 0x4000
    push ax
    popf
    pushf
    pop ax
    xor ax, cx
    jz .no_cpuid
    
    ; Get CPU vendor
    mov eax, 0
    cpuid
    mov [cpu_vendor], ebx
    mov [cpu_vendor+4], edx
    mov [cpu_vendor+8], ecx
    mov byte [cpu_has_cpuid], 1
    
    ; Get CPU features
    mov eax, 1
    cpuid
    mov [cpu_features], edx
    ret
    
.no_cpuid:
    mov byte [cpu_has_cpuid], 0
    ret

; VGA mode detection
detect_vga_modes:
%if VERBOSE_BOOT
    mov si, vga_detect_msg
    call print_string
%endif
    
    ; Get current video mode
    mov ah, 0x0F
    int 0x10
    mov [current_video_mode], al
    mov [video_columns], ah
    ret

; Enhanced configuration display
display_enhanced_config:
    call set_header_color
    mov si, config_header
    call print_string
    call set_normal_color
    
    ; Memory information
    mov si, mem_config_msg
    call print_string
    mov ax, [memory_entries]
    call print_decimal
    mov si, entries_found_msg
    call print_string
    
    ; Drive information  
    mov si, drive_config_msg
    call print_string
    mov al, [floppy_count]
    call print_decimal_byte
    mov si, floppy_drives_msg
    call print_string
    mov al, [hdd_count]
    call print_decimal_byte
    mov si, hard_drives_msg
    call print_string
    
    ; CPU information
    mov si, cpu_config_msg
    call print_string
    cmp byte [cpu_has_cpuid], 1
    je .show_cpu_vendor
    mov si, legacy_cpu_msg
    call print_string
    jmp .config_done
    
.show_cpu_vendor:
    mov si, cpu_vendor
    call print_string_fixed
    
.config_done:
    call print_newline
    ret

; Display boot menu
display_boot_menu:
    call set_header_color
    mov si, menu_header
    call print_string
    call set_normal_color

    mov si, menu_option1
    call print_string
    mov si, menu_option2
    call print_string
    mov si, menu_option3
    call print_string
    call print_newline

    call set_warning_color
    mov si, menu_prompt
    call print_string
    call set_normal_color
    ret

; Handle boot menu input
handle_boot_menu:
    mov cx, BOOT_TIMEOUT

.menu_loop:
    push cx

    ; Display countdown
    call set_warning_color
    mov si, countdown_msg
    call print_string
    pop cx
    push cx

    mov ax, cx
    call print_decimal
    mov si, seconds_msg
    call print_string
    call set_normal_color

    ; Wait 1 second and check for keypress
    mov ah, 0x86
    mov cx, 0x0F        ; High word of microseconds
    mov dx, 0x4240      ; Low word of microseconds (1 second)
    int 0x15

    ; Check for keypress
    mov ah, 0x01
    int 0x16
    jnz .key_pressed

    ; Clear countdown line
    mov ah, 0x06
    mov al, 1
    mov bh, COLOR_NORMAL
    mov ch, 24          ; Row 24
    mov cl, 0           ; Column 0
    mov dh, 24          ; Row 24
    mov dl, 79          ; Column 79
    int 0x10

    pop cx
    loop .menu_loop

    ; Timeout - proceed with default boot
    ret

.key_pressed:
    ; Get the key
    mov ah, 0x00
    int 0x16
    pop cx

    ; Check which key was pressed
    cmp al, '1'
    je .boot_kernel
    cmp al, '2'
    je .enter_bios
    cmp al, '3'
    je .reboot_system
    cmp al, 13          ; Enter key - default boot
    je .boot_kernel
    cmp al, 27          ; Escape key - show menu again
    je handle_boot_menu

    ; Invalid key - show menu again
    jmp handle_boot_menu

.boot_kernel:
    call set_success_color
    mov si, booting_msg
    call print_string
    call set_normal_color
    ret

.enter_bios:
    call enter_bios_setup
    ; If we return from BIOS, show menu again
    jmp handle_boot_menu

.reboot_system:
    call reboot_system
    ; Should not return
    jmp halt

; Enter BIOS setup
enter_bios_setup:
    call set_warning_color
    mov si, bios_enter_msg
    call print_string
    call set_normal_color

    ; Try different methods to enter BIOS setup

    ; Method 1: INT 15h, AX=5F01h (APM BIOS Setup)
    mov ax, 0x5F01
    int 0x15
    jnc .bios_entered

    ; Method 2: Try keyboard controller reset with setup flag
    mov al, 0xFE
    out 0x64, al

    ; Method 3: Try CMOS setup flag (some BIOSes)
    mov al, 0x8F        ; CMOS register for setup flag
    out 0x70, al
    mov al, 0x01        ; Set setup flag
    out 0x71, al

    ; Reboot to enter setup
    call reboot_system

.bios_entered:
    mov si, bios_success_msg
    call print_string
    ret

; Reboot system
reboot_system:
    call set_error_color
    mov si, reboot_msg
    call print_string
    call set_normal_color

    ; Wait a moment
    mov ah, 0x86
    mov cx, 0x07        ; High word
    mov dx, 0xA120      ; Low word (0.5 seconds)
    int 0x15

    ; Method 1: Keyboard controller reset
    mov al, 0xFE
    out 0x64, al

    ; Method 2: Triple fault (if keyboard controller fails)
    cli
    lidt [null_idt]     ; Load null IDT
    int 3               ; Generate interrupt with null IDT

    ; Method 3: Jump to BIOS reset vector
    jmp 0xFFFF:0x0000

    ; Should not reach here
    jmp halt

; Enhanced kernel loading with retry logic
load_kernel_enhanced:
    call set_normal_color
    mov si, loading_kernel_msg
    call print_string
    
    mov cx, RETRY_COUNT
    
.retry_load:
    push cx
    
    ; Reset disk system
    mov ah, 0x00
    mov dl, [boot_drive]
    int 0x13
    
    ; Load kernel
    mov ah, 0x02
    mov al, KERNEL_SECTORS
    mov ch, 0
    mov cl, KERNEL_START_SECTOR
    mov dh, 0
    mov dl, [boot_drive]
    mov bx, KERNEL_LOAD_SEGMENT
    int 0x13
    
    jnc .load_success
    
    pop cx
    loop .retry_load
    
    ; Load failed after retries
    call set_error_color
    mov si, load_failed_msg
    call print_string
    ret
    
.load_success:
    pop cx
    call set_success_color
    mov si, load_success_msg
    call print_string
    call set_normal_color
    
    ; Jump to kernel
    jmp KERNEL_LOAD_SEGMENT

; Color setting functions
set_normal_color:
    mov bl, COLOR_NORMAL
    jmp set_color
set_header_color:
    mov bl, COLOR_HEADER
    jmp set_color
set_success_color:
    mov bl, COLOR_SUCCESS
    jmp set_color
set_error_color:
    mov bl, COLOR_ERROR
    jmp set_color
set_warning_color:
    mov bl, COLOR_WARNING
set_color:
    mov [current_color], bl
    ret

; Print string with current color
print_string:
    push ax
    push bx
    mov bl, [current_color]
.loop:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp .loop
.done:
    pop bx
    pop ax
    ret

; Print fixed-length string (12 chars)
print_string_fixed:
    push cx
    mov cx, 12
.loop:
    lodsb
    mov ah, 0x0E
    mov bl, [current_color]
    int 0x10
    loop .loop
    pop cx
    ret

; Print decimal number (AX)
print_decimal:
    push ax
    push bx
    push cx
    push dx
    
    mov bx, 10
    xor cx, cx
    
.divide_loop:
    xor dx, dx
    div bx
    push dx
    inc cx
    test ax, ax
    jnz .divide_loop
    
.print_loop:
    pop ax
    add al, '0'
    mov ah, 0x0E
    mov bl, [current_color]
    int 0x10
    loop .print_loop
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Print decimal byte (AL)
print_decimal_byte:
    xor ah, ah
    call print_decimal
    ret

; Print newline
print_newline:
    mov al, 13
    mov ah, 0x0E
    int 0x10
    mov al, 10
    int 0x10
    ret

; Display random femboy quote
display_random_quote:
    ; Get a pseudo-random number based on system time
    mov ah, 0x00
    int 0x1A            ; Get system time
    mov ax, dx          ; Use low word of tick count

    ; Simple modulo operation to get quote index (0-7)
    mov bl, 8           ; Number of quotes
    div bl              ; AL = quotient, AH = remainder
    mov al, ah          ; Use remainder as index

    ; Calculate quote address
    mov bl, al
    xor bh, bh
    shl bx, 1           ; Multiply by 2 (word size)
    mov si, [quote_table + bx]

    call set_warning_color
    call print_string
    call print_newline
    ret

; Check boot mode (first boot setup or F2 pressed)
check_boot_mode:
    ; Check if F2 is being pressed
    mov ah, 0x02        ; Get keyboard shift status
    int 0x16
    test al, 0x40       ; Check if F2 equivalent (we'll use a different method)

    ; Check keyboard buffer for F2 (scan code 0x3C)
    mov ah, 0x01        ; Check keyboard buffer
    int 0x16
    jz .check_first_boot

    ; Get the key
    mov ah, 0x00
    int 0x16
    cmp ah, 0x3C        ; F2 scan code
    je .show_mode_setup

.check_first_boot:
    ; Check CMOS for boot mode flag (using CMOS byte 0x3F)
    mov al, 0x3F        ; CMOS register for our boot mode flag
    out 0x70, al
    in al, 0x71

    cmp al, 0xFF        ; 0xFF means first boot (uninitialized)
    je .show_first_boot_setup
    cmp al, 0x00        ; 0x00 means basic mode
    je .basic_mode
    cmp al, 0x01        ; 0x01 means advanced mode
    je .advanced_mode

    ; Default to first boot setup if invalid value
    jmp .show_first_boot_setup

.basic_mode:
    mov byte [current_mode], 0
    call run_basic_mode
    ret

.advanced_mode:
    mov byte [current_mode], 1
    call run_advanced_mode
    ret

.show_first_boot_setup:
    call first_boot_setup
    ret

.show_mode_setup:
    call mode_setup
    ret

; First boot setup
first_boot_setup:
    ; Clear screen with special color
    mov ah, 0x06
    mov al, 0
    mov bh, 0x5F        ; Bright white on magenta
    mov cx, 0
    mov dx, 0x184F
    int 0x10

    ; Display first boot message
    call set_header_color
    mov si, first_boot_header
    call print_string
    call set_normal_color

    mov si, first_boot_msg
    call print_string

    call set_warning_color
    mov si, mode_options
    call print_string
    call set_normal_color

    mov si, mode_prompt
    call print_string

.wait_choice:
    ; Wait for user input
    mov ah, 0x00
    int 0x16

    cmp al, '1'
    je .choose_basic
    cmp al, '2'
    je .choose_advanced
    cmp al, 13          ; Enter - default to basic
    je .choose_basic

    ; Invalid choice, wait again
    jmp .wait_choice

.choose_basic:
    ; Save basic mode to CMOS
    mov al, 0x3F
    out 0x70, al
    mov al, 0x00        ; Basic mode
    out 0x71, al

    mov byte [current_mode], 0
    call run_basic_mode
    ret

.choose_advanced:
    ; Save advanced mode to CMOS
    mov al, 0x3F
    out 0x70, al
    mov al, 0x01        ; Advanced mode
    out 0x71, al

    mov byte [current_mode], 1
    call run_advanced_mode
    ret

; Mode setup (F2 pressed)
mode_setup:
    ; Clear screen
    mov ah, 0x06
    mov al, 0
    mov bh, 0x1F        ; Bright white on blue
    mov cx, 0
    mov dx, 0x184F
    int 0x10

    call set_header_color
    mov si, mode_setup_header
    call print_string
    call set_normal_color

    ; Show current mode
    mov si, current_mode_msg
    call print_string

    cmp byte [current_mode], 0
    je .show_basic_current
    mov si, advanced_mode_name
    jmp .show_current_done
.show_basic_current:
    mov si, basic_mode_name
.show_current_done:
    call print_string
    call print_newline
    call print_newline

    call set_warning_color
    mov si, mode_options
    call print_string
    call set_normal_color

    mov si, mode_prompt
    call print_string

.wait_mode_choice:
    mov ah, 0x00
    int 0x16

    cmp al, '1'
    je .set_basic
    cmp al, '2'
    je .set_advanced
    cmp al, 27          ; Escape - keep current mode
    je .keep_current

    jmp .wait_mode_choice

.set_basic:
    mov al, 0x3F
    out 0x70, al
    mov al, 0x00
    out 0x71, al
    mov byte [current_mode], 0
    call run_basic_mode
    ret

.set_advanced:
    mov al, 0x3F
    out 0x70, al
    mov al, 0x01
    out 0x71, al
    mov byte [current_mode], 1
    call run_advanced_mode
    ret

.keep_current:
    cmp byte [current_mode], 0
    je .run_basic_keep
    call run_advanced_mode
    ret
.run_basic_keep:
    call run_basic_mode
    ret

; Run basic mode
run_basic_mode:
    ; Set normal screen colors
    mov ah, 0x06
    mov al, 0
    mov bh, COLOR_NORMAL
    mov cx, 0
    mov dx, 0x184F
    int 0x10

    ; Display basic boot header
    call set_header_color
    mov si, boot_header
    call print_string
    call display_random_quote
    call set_normal_color

    ; Show F2 hint
    mov si, f2_hint_msg
    call print_string
    call print_newline

    ; Basic auto-detection (minimal)
%if AUTO_DETECT_MEMORY
    call detect_memory_basic
%endif

    ; Simple boot countdown
    call basic_boot_countdown

    ; Load kernel
    call load_kernel_enhanced
    ret

; Run advanced mode
run_advanced_mode:
    ; Set normal screen colors
    mov ah, 0x06
    mov al, 0
    mov bh, COLOR_NORMAL
    mov cx, 0
    mov dx, 0x184F
    int 0x10

    ; Display boot header
    call set_header_color
    mov si, boot_header
    call print_string
    call display_random_quote
    call set_normal_color

    ; Show F2 hint
    mov si, f2_hint_msg
    call print_string
    call print_newline

%if VERBOSE_BOOT
    mov si, verbose_start_msg
    call print_string
%endif

    ; Full auto-configuration
%if AUTO_DETECT_MEMORY
    call detect_memory_enhanced
%endif

%if AUTO_DETECT_DRIVES
    call detect_drives_enhanced
%endif

%if AUTO_DETECT_CPU
    call detect_cpu_enhanced
%endif

%if AUTO_DETECT_VGA
    call detect_vga_modes
%endif

    ; Display configuration summary
    call display_enhanced_config

    ; Display menu options
    call display_boot_menu

    ; Handle user input
    call handle_boot_menu

    ; Load kernel
    call load_kernel_enhanced
    ret

; Basic memory detection (simplified)
detect_memory_basic:
    mov si, mem_detect_basic_msg
    call print_string

    ; Just use legacy method
    mov ah, 0x88
    int 0x15
    mov [legacy_mem_kb], ax

    mov ax, [legacy_mem_kb]
    call print_decimal
    mov si, kb_found_msg
    call print_string
    ret

; Basic boot countdown
basic_boot_countdown:
    mov cx, 3           ; Shorter countdown for basic mode

.countdown_loop:
    push cx

    call set_warning_color
    mov si, basic_countdown_msg
    call print_string
    pop cx
    push cx

    mov ax, cx
    call print_decimal
    mov si, seconds_msg
    call print_string
    call set_normal_color

    ; Wait 1 second and check for F2
    mov ah, 0x86
    mov cx, 0x0F
    mov dx, 0x4240
    int 0x15

    ; Check for F2 key
    mov ah, 0x01
    int 0x16
    jnz .check_f2

    ; Clear countdown line
    mov ah, 0x06
    mov al, 1
    mov bh, COLOR_NORMAL
    mov ch, 24
    mov cl, 0
    mov dh, 24
    mov dl, 79
    int 0x10

    pop cx
    loop .countdown_loop
    ret

.check_f2:
    mov ah, 0x00
    int 0x16
    cmp ah, 0x3C        ; F2 scan code
    je .switch_mode
    pop cx
    loop .countdown_loop
    ret

.switch_mode:
    pop cx
    call mode_setup
    ret

; Try alternative boot methods
try_alternative_boot:
    mov si, trying_alt_boot_msg
    call print_string
    ; Implementation for alternative boot methods
    ret

halt:
    hlt
    jmp halt

; Data section
boot_header db 'Femboy Boot Loader v1.1', 13, 10,
            db '=======================', 13, 10, 0
config_header db 13, 10, '=== Auto-Configuration Results ===', 13, 10, 0
verbose_start_msg db 'Starting auto-configuration...', 13, 10, 0
mem_detect_start_msg db 'Probing memory...', 0
drive_detect_start_msg db 'Scanning drives...', 0  
cpu_detect_start_msg db 'Identifying CPU...', 0
vga_detect_msg db 'Detecting VGA...', 0
mem_config_msg db 'Memory: ', 0
entries_found_msg db ' regions detected', 13, 10, 0
drive_config_msg db 'Storage: ', 0
floppy_drives_msg db ' floppy, ', 0
hard_drives_msg db ' HDD', 13, 10, 0
cpu_config_msg db 'CPU: ', 0
legacy_cpu_msg db 'Legacy (pre-Pentium)', 13, 10, 0
countdown_msg db 13, 'Auto-boot in ', 0
seconds_msg db ' seconds (press any key to interrupt)', 0
loading_kernel_msg db 13, 10, 'Loading kernel...', 0
load_success_msg db 'OK', 13, 10, 0
load_failed_msg db 'FAILED', 13, 10, 0
trying_alt_boot_msg db 'Trying alternative boot methods...', 13, 10, 0
critical_error_msg db 'Critical boot error!', 13, 10, 0

; Boot menu messages (missing definitions)
menu_header db 13, 10, '=== Enhanced Boot Menu ===', 13, 10, 0
menu_option1 db '  [1] Boot Kernel (default)', 13, 10, 0
menu_option2 db '  [2] Enter BIOS Setup', 13, 10, 0
menu_option3 db '  [3] Reboot System', 13, 10, 0
menu_prompt db 'Select option (1-3, Enter=Boot): ', 0
booting_msg db 'Booting kernel...', 13, 10, 0
bios_enter_msg db 'Attempting to enter BIOS setup...', 13, 10, 0
bios_success_msg db 'BIOS setup entered successfully.', 13, 10, 0
reboot_msg db 'Rebooting system...', 13, 10, 0

; First boot and mode setup messages
first_boot_header db '╔══════════════════════════════════════════════════════════════════════════════╗', 13, 10
                  db '║                           FEMBOY BOOT LOADER SETUP                          ║', 13, 10
                  db '║                              First Boot Setup                               ║', 13, 10
                  db '╚══════════════════════════════════════════════════════════════════════════════╝', 13, 10, 13, 10, 0

first_boot_msg db 'Welcome to Femboy Boot Loader! UwU', 13, 10
               db 'This appears to be your first boot. Please choose your preferred mode:', 13, 10, 13, 10, 0

mode_setup_header db '╔══════════════════════════════════════════════════════════════════════════════╗', 13, 10
                  db '║                           FEMBOY BOOT LOADER SETUP                          ║', 13, 10
                  db '║                              Mode Configuration                             ║', 13, 10
                  db '╚══════════════════════════════════════════════════════════════════════════════╝', 13, 10, 13, 10, 0

mode_options db '  [1] Basic Mode     - Simple, fast boot with minimal info', 13, 10
             db '  [2] Advanced Mode  - Full hardware detection and boot menu', 13, 10, 13, 10, 0

mode_prompt db 'Choose mode (1-2, Enter=Basic): ', 0

current_mode_msg db 'Current mode: ', 0
basic_mode_name db 'Basic Mode', 0
advanced_mode_name db 'Advanced Mode', 0

f2_hint_msg db 'Press F2 to change boot mode', 0
mem_detect_basic_msg db 'Memory: ', 0
kb_found_msg db ' KB detected', 13, 10, 0
basic_countdown_msg db 'Booting in ', 0

; Variables
boot_drive db 0
current_color db COLOR_NORMAL
current_mode db 0xFF        ; 0xFF = uninitialized, 0 = basic, 1 = advanced
memory_entries dw 0
extended_mem_1m dw 0
extended_mem_16m dw 0
legacy_mem_kb dw 0
floppy_count db 0
hdd_count db 0
cpu_has_cpuid db 0
cpu_features dd 0
current_video_mode db 0
video_columns db 0
cpu_vendor db '            ', 0

; Quote table (pointers to quotes)
quote_table dw quote1, quote2, quote3, quote4, quote5, quote6, quote7, quote8

; Femboy quotes
quote1 db '"Femboys: Redefining masculinity one thigh-high at a time."', 0
quote2 db '"Confidence is the best accessory, even with cat ears."', 0
quote3 db '"Breaking gender norms like breaking boot sectors."', 0
quote4 db '"Soft boys, strong code."', 0
quote5 db '"Programming in pink and proud of it."', 0
quote6 db '"Cute > Conventional"', 0
quote7 db '"Femboy energy: Maximum adorability, minimum toxic masculinity."', 0
quote8 db '"Booting up with style and grace."', 0

; Memory map buffer
memory_map times (MEMORY_MAP_ENTRIES * 24) db 0

; Null IDT for triple fault reboot
null_idt:
    dw 0    ; Limit
    dd 0    ; Base

; No boot signature needed for Stage 2
