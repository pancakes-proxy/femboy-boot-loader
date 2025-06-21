; Enhanced Femboy Bootloader - Stage 1
; Loads the enhanced bootloader as Stage 2

[BITS 16]
[ORG 0x7C00]

; Constants
STAGE2_LOAD_SEGMENT equ 0x1000
STAGE2_START_SECTOR equ 2
STAGE2_SECTORS equ 16       ; Enhanced bootloader needs more space (8KB)

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

    ; Display loading message
    mov si, stage1_msg
    call print_string

    ; Display femboy loading quote
    mov si, loading_quote
    call print_string

    ; Load Stage 2 bootloader
    call load_stage2
    
    ; Jump to Stage 2
    mov si, jumping_msg
    call print_string
    
    ; Pass boot drive to Stage 2
    mov dl, [boot_drive]
    jmp STAGE2_LOAD_SEGMENT

; Load Stage 2 bootloader
load_stage2:
    mov si, loading_stage2_msg
    call print_string
    
    ; Reset disk system
    mov ah, 0x00
    mov dl, [boot_drive]
    int 0x13
    jc .load_error
    
    ; Load Stage 2 (multiple sectors)
    mov ah, 0x02                ; Read sectors
    mov al, STAGE2_SECTORS      ; Number of sectors to read
    mov ch, 0                   ; Cylinder 0
    mov cl, STAGE2_START_SECTOR ; Starting sector
    mov dh, 0                   ; Head 0
    mov dl, [boot_drive]        ; Drive
    mov bx, STAGE2_LOAD_SEGMENT ; Load address
    int 0x13
    jc .load_error
    
    mov si, stage2_loaded_msg
    call print_string
    ret

.load_error:
    mov si, load_error_msg
    call print_string
    jmp halt

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

halt:
    hlt
    jmp halt

; Data section
stage1_msg db 'Femboy Bootloader Stage 1 v1.0', 13, 10,
           db '================================', 13, 10, 13, 10, 0

loading_quote db '"Loading cuteness protocols..." UwU', 13, 10, 13, 10, 0

loading_stage2_msg db 'Loading Stage 2 bootloader...', 0
stage2_loaded_msg db 'OK', 13, 10, 0
jumping_msg db 'Jumping to Stage 2...', 13, 10, 0
load_error_msg db 'ERROR: Failed to load Stage 2!', 13, 10, 
               db 'Please check your disk.', 13, 10, 0

; Variables
boot_drive db 0

; Padding and boot signature
times 510-($-$$) db 0
dw 0xAA55
