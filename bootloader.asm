; Simple Femboy Bootloader
; Fits in 512 bytes

[BITS 16]
[ORG 0x7C00]

start:
    ; Store boot drive
    mov [boot_drive], dl

    ; Initialize segments
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7000
    sti

    ; Set video mode and clear screen
    mov ax, 0x0003
    int 0x10

    ; Display boot header
    mov si, boot_header
    call print_string

    ; Display random femboy quote
    call display_random_quote

    ; Simple countdown and boot
    mov cx, 3
countdown_loop:
    push cx
    mov si, countdown_msg
    call print_string
    pop cx
    push cx
    mov ax, cx
    call print_decimal
    mov si, seconds_msg
    call print_string

    ; Wait 1 second
    mov ah, 0x86
    mov cx, 0x0F
    mov dx, 0x4240
    int 0x15

    pop cx
    loop countdown_loop

    ; Load and execute kernel
    call load_kernel
    
    ; Error - halt
    jmp halt

; Display random femboy quote
display_random_quote:
    ; Get a pseudo-random number based on system time
    mov ah, 0x00
    int 0x1A
    mov ax, dx
    and ax, 3           ; Simple modulo 4
    shl ax, 1           ; Multiply by 2 (word size)
    mov bx, ax
    mov si, [quote_table + bx]
    call print_string
    call print_newline
    ret

; Simple kernel loading
load_kernel:
    mov si, loading_msg
    call print_string
    
    ; Reset disk system
    mov ah, 0x00
    mov dl, [boot_drive]
    int 0x13
    
    ; Load kernel (1 sector from sector 2)
    mov ah, 0x02
    mov al, 1
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, [boot_drive]
    mov bx, 0x1000
    int 0x13
    
    jc halt
    
    mov si, success_msg
    call print_string
    
    ; Jump to kernel
    jmp 0x1000

; Print string
print_string:
.loop:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp .loop
.done:
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
    int 0x10
    loop .print_loop
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Print newline
print_newline:
    mov al, 13
    mov ah, 0x0E
    int 0x10
    mov al, 10
    int 0x10
    ret

halt:
    hlt
    jmp halt

; Data section
boot_header db 'Femboy Boot Loader v1.1', 13, 10,
            db '=======================', 13, 10, 0

countdown_msg db 'Booting in ', 0
seconds_msg db ' seconds...', 13, 10, 0
loading_msg db 'Loading kernel...', 0
success_msg db 'OK', 13, 10, 0

; Quote table (pointers to quotes)
quote_table dw quote1, quote2, quote3, quote4

; Femboy quotes (shortened)
quote1 db '"Femboys: Redefining masculinity."', 13, 10, 0
quote2 db '"Confidence is the best accessory."', 13, 10, 0
quote3 db '"Breaking norms like boot sectors."', 13, 10, 0
quote4 db '"Soft boys, strong code."', 13, 10, 0

; Variables
boot_drive db 0

; Boot signature
times 510-($-$$) db 0
dw 0xAA55
