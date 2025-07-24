bits 32

global start_shell

extern init_keyboard
extern read_key

VIDEO_MEMORY equ 0xB8000
WHITE_ON_BLACK equ 0x0F
BUFFER_SIZE equ 256
PROMPT_STRING equ '> '

section .data
input_buffer times BUFFER_SIZE db 0
buffer_pos dd 0
prompt db PROMPT_STRING, 0
newline db 13, 10, 0
unknown_cmd db 'You just talked to the void', 0
help_msg db 'GENZ knows: help | clear | about | reboot', 0
about_msg db 'GENZ v0.1 – Built different. Built in Assembly.', 0
reboot_msg db 'System reboot in progress...', 0
current_line db 1  

; Command strings
cmd_help db 'help', 0
cmd_clear db 'clear', 0
cmd_about db 'about', 0
cmd_reboot db 'reboot', 0

; Keyboard mapping
scancode_to_ascii:
    db 0, 0, '1', '2', '3', '4', '5', '6', '7', '8'    ; 00-09
    db '9', '0', '-', '=', 0, 0, 'q', 'w', 'e', 'r'    ; 10-19
    db 't', 'y', 'u', 'i', 'o', 'p', '[', ']', 0, 0    ; 1A-23
    db 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';' ; 24-2D
    db "'", '`', 0, '\', 'z', 'x', 'c', 'v', 'b', 'n'  ; 2E-37
    db 'm', ',', '.', '/', 0, 0, 0, ' '                ; 38-3F
    times 256-64 db 0                                  ; Pad to 256 bytes

section .text
start_shell:
    pusha
    call init_keyboard
    
    mov edi, VIDEO_MEMORY
    mov ecx, 80*25
    mov ah, WHITE_ON_BLACK
    mov al, ' '
    rep stosw
    
    mov byte [current_line], 1
    
.shell_loop:
    mov esi, prompt
    mov edi, VIDEO_MEMORY + (80 * 24) * 2
    call print_string
    
    mov dword [buffer_pos], 0
    mov edi, input_buffer
    mov ecx, BUFFER_SIZE
    mov al, 0
    rep stosb

    ;clears input    
    mov edi, VIDEO_MEMORY + (80 * 24 + 2) * 2  ; After prompt
    mov ecx, 78  ; 80 - prompt length
    mov ah, WHITE_ON_BLACK
    mov al, ' '
    rep stosw
    
.input_loop:
    call read_key
    test al, al
    jz .input_loop
    
    cmp al, 0x1C
    je .execute_command
    
    cmp al, 0x0E
    je .handle_backspace
    
    movzx ebx, al
    cmp ebx, 256
    jae .input_loop
    mov al, [scancode_to_ascii + ebx]
    test al, al
    jz .input_loop
    
    mov ebx, [buffer_pos]
    cmp ebx, BUFFER_SIZE-1
    jae .input_loop
    
    mov [input_buffer + ebx], al
    inc dword [buffer_pos]
    
    mov ah, WHITE_ON_BLACK
    mov edi, VIDEO_MEMORY + (80 * 24 + 2) * 2  ; After '> '
    add edi, ebx
    add edi, ebx
    stosw
    
    jmp .input_loop

.handle_backspace:
    mov ebx, [buffer_pos]
    test ebx, ebx
    jz .input_loop
    
    dec dword [buffer_pos]
    
    mov edi, VIDEO_MEMORY + (80 * 24 + 2) * 2
    add edi, ebx
    add edi, ebx
    sub edi, 2
    mov ah, WHITE_ON_BLACK
    mov al, ' '
    stosw
    
    jmp .input_loop

.execute_command:
    mov ebx, [buffer_pos]
    mov byte [input_buffer + ebx], 0
    
    movzx eax, byte [current_line]
    imul eax, 160  ; 80 chars * 2 bytes
    mov edi, VIDEO_MEMORY
    add edi, eax
    
    mov esi, prompt
    call print_string
    mov esi, input_buffer
    call print_string
    
    inc byte [current_line]
    cmp byte [current_line], 23
    jb .no_scroll
    call scroll_screen
    mov byte [current_line], 22
    
.no_scroll:
    ; checking...
    mov esi, input_buffer
    
    mov edi, cmd_help
    call str_compare
    je .do_help
    
    mov edi, cmd_clear
    call str_compare
    je .do_clear
    
    mov edi, cmd_about
    call str_compare
    je .do_about
    
    mov edi, cmd_reboot
    call str_compare
    je .do_reboot
    
    mov esi, unknown_cmd
    movzx eax, byte [current_line]
    imul eax, 160
    mov edi, VIDEO_MEMORY
    add edi, eax
    call print_string
    inc byte [current_line]
    jmp .shell_loop

.do_help:
    mov esi, help_msg
    jmp .print_response

.do_about:
    mov esi, about_msg
    jmp .print_response

.print_response:
    movzx eax, byte [current_line]
    imul eax, 160
    mov edi, VIDEO_MEMORY
    add edi, eax
    call print_string
    inc byte [current_line]
    jmp .shell_loop

.do_clear:
    ;clear screen except the last line
    mov edi, VIDEO_MEMORY
    mov ecx, 80*23  
    mov ah, WHITE_ON_BLACK
    mov al, ' '
    rep stosw
    
    mov byte [current_line], 1
    jmp .shell_loop

.do_reboot:
    mov esi, reboot_msg
    movzx eax, byte [current_line]
    imul eax, 160
    mov edi, VIDEO_MEMORY
    add edi, eax
    call print_string
    
    mov ecx, 0x3FFFFF
.delay:
    loop .delay
    
    ;reboot    
    jmp 0xFFFF:0x0000

; scroll the screen
scroll_screen:
    pusha
    mov esi, VIDEO_MEMORY + 160  
    mov edi, VIDEO_MEMORY       
    mov ecx, 80*23*2 / 4         
    rep movsd
    
    mov edi, VIDEO_MEMORY + 160*23
    mov ecx, 80
    mov ah, WHITE_ON_BLACK
    mov al, ' '
    rep stosw
    popa
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
