; Example Kernel for FemBootloader
; This is a simple kernel that demonstrates basic functionality

[BITS 16]
[ORG 0x8000]

kernel_start:
    ; Clear screen with blue background
    mov ax, 0x0003
    int 0x10
    
    ; Set blue background
    mov ah, 0x06        ; Scroll up
    mov al, 0           ; Clear entire screen
    mov bh, 0x17        ; White on blue
    mov cx, 0           ; Upper left
    mov dx, 0x184F      ; Lower right (25x80)
    int 0x10
    
    ; Display kernel banner
    mov si, kernel_banner
    call print_string
    
    ; Display system info passed from bootloader
    call display_system_info
    
    ; Simple command loop
    call command_loop

; Print string function
print_string:
    push ax
    push bx
.loop:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0E
    mov bh, 0
    mov bl, 0x1F        ; Bright white on blue
    int 0x10
    jmp .loop
.done:
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

; Display system information
display_system_info:
    mov si, system_info_msg
    call print_string
    
    ; Get memory info
    mov si, memory_msg
    call print_string
    
    ; Simple memory detection
    mov ah, 0x88
    int 0x15
    call print_hex_word
    mov si, kb_msg
    call print_string
    
    ; Get current time
    mov si, time_msg
    call print_string
    
    mov ah, 0x02
    int 0x1A
    
    ; Print hours
    mov al, ch
    call print_bcd_byte
    mov al, ':'
    mov ah, 0x0E
    int 0x10
    
    ; Print minutes
    mov al, cl
    call print_bcd_byte
    mov al, ':'
    mov ah, 0x0E
    int 0x10
    
    ; Print seconds
    mov al, dh
    call print_bcd_byte
    
    call print_newline
    call print_newline
    ret

; Simple command loop
command_loop:
    mov si, prompt_msg
    call print_string
    
    ; Read command
    call read_command
    
    ; Process command
    call process_command
    
    jmp command_loop

; Read a simple command
read_command:
    mov di, command_buffer
    mov cx, 0
    
.read_loop:
    mov ah, 0x00
    int 0x16            ; Wait for keypress
    
    cmp al, 13          ; Enter key
    je .done
    
    cmp al, 8           ; Backspace
    je .backspace
    
    cmp cx, 79          ; Max command length
    jge .read_loop
    
    ; Echo character
    mov ah, 0x0E
    int 0x10
    
    ; Store character
    stosb
    inc cx
    jmp .read_loop
    
.backspace:
    test cx, cx
    jz .read_loop
    
    ; Move cursor back
    mov ah, 0x0E
    mov al, 8
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 8
    int 0x10
    
    ; Remove character from buffer
    dec di
    dec cx
    jmp .read_loop
    
.done:
    mov al, 0           ; Null terminate
    stosb
    call print_newline
    ret

; Process simple commands
process_command:
    mov si, command_buffer
    
    ; Check for "help" command
    mov di, help_cmd
    call compare_string
    jz .show_help
    
    ; Check for "reboot" command
    mov di, reboot_cmd
    call compare_string
    jz .reboot
    
    ; Check for "time" command
    mov di, time_cmd
    call compare_string
    jz .show_time
    
    ; Check for "clear" command
    mov di, clear_cmd
    call compare_string
    jz .clear_screen
    
    ; Unknown command
    mov si, unknown_cmd_msg
    call print_string
    ret
    
.show_help:
    mov si, help_msg
    call print_string
    ret
    
.reboot:
    mov si, reboot_msg
    call print_string
    ; Reboot via keyboard controller
    mov al, 0xFE
    out 0x64, al
    hlt
    
.show_time:
    call display_system_info
    ret
    
.clear_screen:
    mov ax, 0x0003
    int 0x10
    ; Set blue background again
    mov ah, 0x06
    mov al, 0
    mov bh, 0x17
    mov cx, 0
    mov dx, 0x184F
    int 0x10
    ret

; Compare two null-terminated strings
; SI = string1, DI = string2
; Returns ZF=1 if equal
compare_string:
    push si
    push di
.loop:
    lodsb
    mov ah, [di]
    inc di
    cmp al, ah
    jne .not_equal
    test al, al
    jz .equal
    jmp .loop
.equal:
    pop di
    pop si
    xor ax, ax          ; Set ZF=1
    ret
.not_equal:
    pop di
    pop si
    mov ax, 1           ; Clear ZF
    ret

; Print BCD byte
print_bcd_byte:
    push ax
    shr al, 4
    call .print_bcd_digit
    pop ax
    and al, 0x0F
.print_bcd_digit:
    add al, '0'
    mov ah, 0x0E
    int 0x10
    ret

; Print hex word
print_hex_word:
    push ax
    mov al, ah
    call print_hex_byte
    pop ax
    call print_hex_byte
    ret

; Print hex byte
print_hex_byte:
    push ax
    shr al, 4
    call .print_hex_digit
    pop ax
    and al, 0x0F
.print_hex_digit:
    add al, '0'
    cmp al, '9'
    jle .print_digit
    add al, 7
.print_digit:
    mov ah, 0x0E
    int 0x10
    ret

; Data section
kernel_banner db '╔══════════════════════════════════════════════════════════════════════════════╗', 13, 10
              db '║                        Femboy Boot Loader Example Kernel                    ║', 13, 10
              db '║                              Version 1.0 UwU                                ║', 13, 10
              db '╚══════════════════════════════════════════════════════════════════════════════╝', 13, 10, 13, 10, 0

system_info_msg db 'System Information:', 13, 10, 0
memory_msg db '  Extended Memory: ', 0
kb_msg db ' KB', 13, 10, 0
time_msg db '  Current Time: ', 0

prompt_msg db 'kernel> ', 0
unknown_cmd_msg db 'Unknown command. Type "help" for available commands.', 13, 10, 0

help_cmd db 'help', 0
reboot_cmd db 'reboot', 0
time_cmd db 'time', 0
clear_cmd db 'clear', 0

help_msg db 'Available commands:', 13, 10
         db '  help   - Show this help message', 13, 10
         db '  time   - Display current system time', 13, 10
         db '  clear  - Clear the screen', 13, 10
         db '  reboot - Restart the system', 13, 10, 13, 10, 0

reboot_msg db 'Rebooting system...', 13, 10, 0

; Command buffer
command_buffer times 80 db 0

; Padding to fill sector
times 512-($-$$) db 0
