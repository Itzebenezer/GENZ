bits 32

extern init_keyboard
extern read_key
extern start_shell  

; Constants
VIDEO_MEMORY equ 0xB8000
WHITE_ON_BLACK equ 0x0F
GREEN_ON_BLACK equ 0x0A
RED_ON_BLACK equ 0x0C
USER_FIELD_POS equ (80 * 10 + 40) * 2
PASS_FIELD_POS equ (80 * 12 + 40) * 2
FIELD_LEN equ 20
MAX_INPUT_LEN equ 16
CAPSLOCK_SCANCODE equ 0x3A

section .data
username times MAX_INPUT_LEN db 0
username_len db 0
password times MAX_INPUT_LEN db 0
password_len db 0
current_field db 0  ; 0 for username field and 1 for pass field
capslock_state db 0 ; 0 for off, 1 for on

correct_username db 'root',0
correct_password db 'root',0

; msgs
title_msg db 'Welcome to GENZ', 0
user_msg db 'Username:', 0
pass_msg db 'Password:', 0
success_msg db 'Login successful! starting GENZ shell...', 0
error_msg db 'BRUH its litrally root/root', 0
capslock_msg db 'Caps', 0

; scancode to ascii mapping
scancode_to_ascii:
    db 0, 0, '1', '2', '3', '4', '5', '6', '7', '8'    ; 00-09
    db '9', '0', '-', '=', 0, 0, 'q', 'w', 'e', 'r'    ; 10-19
    db 't', 'y', 'u', 'i', 'o', 'p', '[', ']', 0, 0    ; 1A-23
    db 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';' ; 24-2D
    db "'", '`', 0, '\', 'z', 'x', 'c', 'v', 'b', 'n'  ; 2E-37
    db 'm', ',', '.', '/', 0, 0, 0, ' '                ; 38-3F
    times 256-64 db 0                                 

section .text
global init_gui

init_gui:
    pusha
    call clear_screen
    call draw_login
    call handle_input
    popa
    ret

clear_screen:
    pusha
    mov edi, VIDEO_MEMORY
    mov ecx, 80*25
    mov ah, WHITE_ON_BLACK
    mov al, ' '
    rep stosw
    popa
    ret

draw_login:
    pusha
    
    mov esi, title_msg
    mov edi, VIDEO_MEMORY + (80 * 5 + 30) * 2
    call print_string
    
    mov esi, user_msg
    mov edi, VIDEO_MEMORY + (80 * 10 + 30) * 2
    call print_string
    
    mov esi, pass_msg
    mov edi, VIDEO_MEMORY + (80 * 12 + 30) * 2
    call print_string
    
    call draw_capslock_indicator
    
    mov edi, VIDEO_MEMORY + USER_FIELD_POS
    mov ecx, FIELD_LEN
    mov ah, WHITE_ON_BLACK
    mov al, ' '
    rep stosw
    
    mov edi, VIDEO_MEMORY + PASS_FIELD_POS
    mov ecx, FIELD_LEN
    rep stosw
    
    popa
    ret

draw_capslock_indicator:
	;********************remember to fix this*********************** 	

    pusha
    mov edi, VIDEO_MEMORY + (80 * 24 + 0) * 2  ; Bottom left corner
    mov ah, WHITE_ON_BLACK
    mov al, '['
    stosw
    mov al, ' '
    stosw
    
    cmp byte [capslock_state], 1
    jne .caps_off
    mov esi, capslock_msg
    call print_string
    mov al, ' '
    stosw
    mov al, ']'
    stosw
    popa
    ret
.caps_off:
    mov al, ' '
    stosw
    stosw
    stosw
    stosw
    mov al, ']'
    stosw
    popa
    ret

handle_input:
    pusha
    call init_keyboard
    
.input_loop:
    call read_key
    test al, al
    jz .input_loop
    
    cmp al, CAPSLOCK_SCANCODE
    je .toggle_capslock
    
    cmp al, 0x1C
    je .check_login
    
    cmp al, 0x0E
    je .handle_backspace
    
    cmp al, 0x0F
    je .switch_field
    
    ; scancode to ascii convertor
    movzx ebx, al
    cmp ebx, 256
    jae .input_loop
    mov al, [scancode_to_ascii + ebx]
    test al, al
    jz .input_loop
    
    cmp byte [capslock_state], 1
    jne .no_caps
    cmp al, 'a'
    jb .no_caps
    cmp al, 'z'
    ja .no_caps
    sub al, 32  ;to uppercase
    
.no_caps:
    cmp byte [current_field], 0
    je .username_input
    jmp .password_input

.toggle_capslock:
    xor byte [capslock_state], 1
    call draw_capslock_indicator
    jmp .input_loop

.username_input:
    mov bl, [username_len]
    cmp bl, MAX_INPUT_LEN
    jae .input_loop
    
    movzx ebx, bl
    mov [username + ebx], al
    inc byte [username_len]
    mov edi, VIDEO_MEMORY + USER_FIELD_POS
    add edi, ebx
    add edi, ebx
    mov ah, WHITE_ON_BLACK
    stosw
    jmp .input_loop

.password_input:
    mov bl, [password_len]
    cmp bl, MAX_INPUT_LEN
    jae .input_loop
    
    movzx ebx, bl
    mov [password + ebx], al
    inc byte [password_len]
    mov edi, VIDEO_MEMORY + PASS_FIELD_POS
    add edi, ebx
    add edi, ebx
    mov ah, WHITE_ON_BLACK
    mov al, '*'
    stosw
    jmp .input_loop

.check_login:
    ; Compare username (case-sensitive)
    mov esi, username
    mov edi, correct_username
    call str_compare
    jne .login_failed
    
    ; Compare password (case-sensitive)
    mov esi, password
    mov edi, correct_password
    call str_compare
    jne .login_failed
    
    ; Login successful - jump to shell
    mov esi, success_msg
    mov edi, VIDEO_MEMORY + (80 * 15 + 30) * 2
    mov ah, GREEN_ON_BLACK
    call print_string_colored
    
    ; ***************************short delay before jumping to start_shell(dont forget to remove this after dbg)*************************
    mov ecx, 0x3FFFFF
.delay_loop:
    loop .delay_loop
    
    jmp start_shell

.login_failed:
    mov esi, error_msg
    mov edi, VIDEO_MEMORY + (80 * 15 + 30) * 2
    mov ah, RED_ON_BLACK
    call print_string_colored
    
    mov byte [username_len], 0
    mov byte [password_len], 0
    call draw_login
    jmp .input_loop

.switch_field:
    xor byte [current_field], 1
    jmp .input_loop

.handle_backspace:
    cmp byte [current_field], 0
    je .username_backspace
    jmp .password_backspace

.username_backspace:
    mov bl, [username_len]
    test bl, bl
    jz .input_loop
    dec byte [username_len]
    movzx ebx, byte [username_len]
    mov edi, VIDEO_MEMORY + USER_FIELD_POS
    add edi, ebx
    add edi, ebx
    mov ah, WHITE_ON_BLACK
    mov al, ' '
    stosw
    jmp .input_loop

.password_backspace:
    mov bl, [password_len]
    test bl, bl
    jz .input_loop
    dec byte [password_len]
    movzx ebx, byte [password_len]
    mov edi, VIDEO_MEMORY + PASS_FIELD_POS
    add edi, ebx
    add edi, ebx
    mov ah, WHITE_ON_BLACK
    mov al, ' '
    stosw
    jmp .input_loop

str_compare:
    pusha
.compare_loop:
    cmpsb
    jne .not_equal
    cmp byte [esi-1], 0
    jne .compare_loop
    popa
    ret
.not_equal:
    popa
    or eax, 1
    ret

print_string:
    pusha
    mov ah, WHITE_ON_BLACK
.loop:
    lodsb
    test al, al
    jz .done
    stosw
    jmp .loop
.done:
    popa
    ret

print_string_colored:
    pusha
.loop:
    lodsb
    test al, al
    jz .done
    stosw
    jmp .loop
.done:
    popa
    ret
