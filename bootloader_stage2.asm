; Femboy Bootloader - Stage 2
; Enhanced bootloader with full features (no size limit!)

[BITS 16]
[ORG 0x1000]

; Configuration constants
KERNEL_LOAD_SEGMENT equ 0x2000
KERNEL_START_SECTOR equ 10
KERNEL_SECTORS equ 4
BOOT_TIMEOUT equ 10
RETRY_COUNT equ 3

; Color constants
COLOR_NORMAL equ 0x07
COLOR_HEADER equ 0x0F
COLOR_SUCCESS equ 0x0A
COLOR_ERROR equ 0x0C
COLOR_WARNING equ 0x0E
COLOR_FEMBOY equ 0x0D       ; Bright magenta for femboy theme

start_stage2:
    ; Store boot drive (passed from Stage 1)
    mov [boot_drive], dl

    ; Set femboy color scheme
    mov ah, 0x06
    mov al, 0
    mov bh, COLOR_NORMAL
    mov cx, 0
    mov dx, 0x184F
    int 0x10

    ; Display Stage 2 header
    call set_header_color
    mov si, stage2_header
    call print_string
    call set_normal_color

    ; Display random femboy quote
    call display_random_quote

    ; Auto-configuration phase
    call detect_memory
    call detect_drives
    call detect_cpu

    ; Display configuration summary
    call display_config

    ; Display boot menu
    call display_boot_menu

    ; Handle user input
    call handle_boot_menu

    ; Load and execute kernel
    call load_kernel
    
    ; Error handling
    call set_error_color
    mov si, critical_error_msg
    call print_string
    jmp halt

; Memory detection
detect_memory:
    mov si, mem_detect_msg
    call print_string
    
    ; Try INT 15h, AH=88h for extended memory
    mov ah, 0x88
    int 0x15
    jc .mem_error
    
    mov [extended_memory], ax
    mov ax, [extended_memory]
    call print_decimal
    mov si, kb_msg
    call print_string
    ret

.mem_error:
    mov si, mem_error_msg
    call print_string
    ret

; Drive detection
detect_drives:
    mov si, drive_detect_msg
    call print_string
    
    ; Check for hard drives
    mov dl, 0x80
    mov ah, 0x08
    int 0x13
    jc .no_hdd
    
    mov si, hdd_found_msg
    call print_string
    ret

.no_hdd:
    mov si, no_hdd_msg
    call print_string
    ret

; CPU detection
detect_cpu:
    mov si, cpu_detect_msg
    call print_string
    
    ; Simple CPU detection
    mov si, cpu_detected_msg
    call print_string
    ret

; Display configuration summary
display_config:
    call set_header_color
    mov si, config_header
    call print_string
    call set_normal_color
    
    mov si, config_summary
    call print_string
    ret

; Display random femboy quote
display_random_quote:
    ; Get pseudo-random number
    mov ah, 0x00
    int 0x1A
    mov ax, dx
    and ax, 7           ; Modulo 8 for 8 quotes
    shl ax, 1
    mov bx, ax
    mov si, [quote_table + bx]
    
    call set_femboy_color
    call print_string
    call set_normal_color
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
    mov si, menu_option4
    call print_string
    call print_newline

    call set_warning_color
    mov si, menu_prompt
    call print_string
    call set_normal_color
    ret
