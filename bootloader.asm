; Simple Bootloader with Auto Configuration
; Automatically detects memory, drives, and basic hardware
; Loads and jumps to a kernel or second stage

[BITS 16]
[ORG 0x7C00]

start:
    ; Initialize segments
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    ; Clear screen
    mov ax, 0x0003
    int 0x10

    ; Display boot message
    mov si, boot_msg
    call print_string

    ; Auto-detect memory
    call detect_memory
    
    ; Auto-detect drives
    call detect_drives
    
    ; Auto-detect CPU features
    call detect_cpu
    
    ; Display configuration summary
    call display_config
    
    ; Load second stage or kernel
    call load_kernel
    
    ; If we get here, something went wrong
    mov si, error_msg
    call print_string
    jmp halt

; Memory detection using INT 15h, EAX=E820h
detect_memory:
    mov si, mem_detect_msg
    call print_string
    
    mov di, memory_map      ; ES:DI points to memory map buffer
    xor ebx, ebx           ; EBX = 0 to start
    mov edx, 0x534D4150    ; 'SMAP' signature
    
.loop:
    mov eax, 0xE820        ; Function code
    mov ecx, 24            ; Buffer size
    int 0x15               ; Call BIOS
    
    jc .done               ; Carry flag set = error or done
    cmp eax, 0x534D4150    ; Check signature
    jne .done
    
    ; Process memory entry (simplified)
    add di, 24             ; Move to next entry
    inc word [memory_entries]
    
    test ebx, ebx          ; EBX = 0 means last entry
    jz .done
    jmp .loop
    
.done:
    ; Display total memory entries found
    mov ax, [memory_entries]
    call print_hex_word
    mov si, mem_entries_msg
    call print_string
    ret

; Drive detection
detect_drives:
    mov si, drive_detect_msg
    call print_string
    
    ; Check floppy drives
    mov ah, 0x08
    mov dl, 0x00           ; Drive A:
    int 0x13
    jc .check_hdd
    
    mov [floppy_count], dl
    inc dl
    mov [floppy_count], dl
    
.check_hdd:
    ; Check hard drives
    mov ah, 0x08
    mov dl, 0x80           ; First HDD
    int 0x13
    jc .drives_done
    
    mov [hdd_count], dl
    sub dl, 0x7F           ; Convert to count
    mov [hdd_count], dl
    
.drives_done:
    ret

; CPU detection
detect_cpu:
    mov si, cpu_detect_msg
    call print_string
    
    ; Check if CPUID is available
    pushf
    pop ax
    mov cx, ax
    xor ax, 0x4000         ; Flip AC bit
    push ax
    popf
    pushf
    pop ax
    xor ax, cx
    jz .no_cpuid
    
    ; CPUID is available
    mov eax, 0
    cpuid
    mov [cpu_vendor], ebx
    mov [cpu_vendor+4], edx
    mov [cpu_vendor+8], ecx
    mov byte [cpu_has_cpuid], 1
    ret
    
.no_cpuid:
    mov byte [cpu_has_cpuid], 0
    ret

; Display configuration summary
display_config:
    mov si, config_msg
    call print_string
    
    ; Display memory info
    mov si, mem_info_msg
    call print_string
    mov ax, [memory_entries]
    call print_hex_word
    call print_newline
    
    ; Display drive info
    mov si, drive_info_msg
    call print_string
    mov al, [floppy_count]
    call print_hex_byte
    mov si, floppy_msg
    call print_string
    mov al, [hdd_count]
    call print_hex_byte
    mov si, hdd_msg
    call print_string
    call print_newline
    
    ; Display CPU info
    mov si, cpu_info_msg
    call print_string
    cmp byte [cpu_has_cpuid], 1
    je .show_vendor
    mov si, no_cpuid_msg
    call print_string
    jmp .cpu_done
    
.show_vendor:
    mov si, cpu_vendor
    call print_string
    
.cpu_done:
    call print_newline
    ret

; Load kernel/second stage
load_kernel:
    mov si, loading_msg
    call print_string
    
    ; Try to load from sector 2
    mov ah, 0x02           ; Read sectors
    mov al, 1              ; Number of sectors
    mov ch, 0              ; Cylinder
    mov cl, 2              ; Sector (1-based)
    mov dh, 0              ; Head
    mov dl, [boot_drive]   ; Drive
    mov bx, 0x8000         ; Load address
    int 0x13
    
    jc .load_failed
    
    ; Jump to loaded code
    mov si, jump_msg
    call print_string
    jmp 0x8000
    
.load_failed:
    mov si, load_fail_msg
    call print_string
    ret

; Print string (SI = string address)
print_string:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp print_string
.done:
    ret

; Print newline
print_newline:
    mov al, 13
    mov ah, 0x0E
    int 0x10
    mov al, 10
    int 0x10
    ret

; Print hex byte (AL = byte)
print_hex_byte:
    push ax
    shr al, 4
    call .print_nibble
    pop ax
    and al, 0x0F
.print_nibble:
    add al, '0'
    cmp al, '9'
    jle .print_char
    add al, 7
.print_char:
    mov ah, 0x0E
    int 0x10
    ret

; Print hex word (AX = word)
print_hex_word:
    push ax
    mov al, ah
    call print_hex_byte
    pop ax
    call print_hex_byte
    ret

halt:
    hlt
    jmp halt

; Data section
boot_msg db 'Femboy Boot Loader v1.0 - Configuration', 13, 10, 0
mem_detect_msg db 'Detecting memory...', 0
drive_detect_msg db 'Detecting drives...', 0
cpu_detect_msg db 'Detecting CPU...', 0
config_msg db 13, 10, '=== System Configuration ===', 13, 10, 0
mem_info_msg db 'Memory entries: 0x', 0
mem_entries_msg db ' found', 13, 10, 0
drive_info_msg db 'Drives: ', 0
floppy_msg db ' floppy, ', 0
hdd_msg db ' HDD', 0
cpu_info_msg db 'CPU: ', 0
no_cpuid_msg db 'Pre-Pentium (no CPUID)', 0
loading_msg db 13, 10, 'Loading kernel...', 0
jump_msg db 'Jumping to kernel!', 13, 10, 0
load_fail_msg db 'Kernel load failed!', 13, 10, 0
error_msg db 'Boot error!', 13, 10, 0

; Variables
boot_drive db 0
memory_entries dw 0
floppy_count db 0
hdd_count db 0
cpu_has_cpuid db 0
cpu_vendor db '            ', 0

; Memory map buffer (simplified)
memory_map times 480 db 0  ; 20 entries * 24 bytes

; Boot signature
times 510-($-$$) db 0
dw 0xAA55
