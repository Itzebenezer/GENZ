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
unknown_cmd db '[-]You just talked to the void', 0
help_msg db '[+]Available commands: help, clear, about, reboot, cd, pwd, ls', 0
about_msg db '[+]GenZ v0.2 - Built different. Built in Assembly.', 0
reboot_msg db '[*]System rebooting...', 0
current_line db 

cmd_help db 'help', 0
cmd_clear db 'clear', 0
cmd_about db 'about', 0
cmd_reboot db 'reboot', 0
cmd_cd db 'cd', 0
cmd_pwd db 'pwd', 0
cmd_ls db 'ls', 0

root_dir db '/', 0
current_dir dd root_dir
dir_separator db '/', 0
parent_dir db '..', 0

bin_dir db 'bin', 0
etc_dir db 'etc', 0
home_dir db 'home', 0
lib_dir db 'lib', 0
media_dir db 'media', 0
proc_dir db 'proc', 0
root_dir_user db 'root', 0
sys_dir db 'sys', 0
tmp_dir db 'tmp', 0
usr_dir db 'usr', 0
usr_bin_dir db 'usr/bin', 0
usr_lib_dir db 'usr/lib', 0
usr_local_dir db 'usr/local', 0
home_user_dir db 'home/user', 0
home_user_docs_dir db 'home/user/documents', 0
home_user_downloads_dir db 'home/user/downloads', 0

invalid_path_msg db 'No such directory', 0
dir_contents_msg db 'Directory contents:', 0
dir_entry_fmt db '  - ', 0

scancode_to_ascii:
    db 0, 0, '1', '2', '3', '4', '5', '6', '7', '8'
    db '9', '0', '-', '=', 0, 0, 'q', 'w', 'e', 'r'
    db 't', 'y', 'u', 'i', 'o', 'p', '[', ']', 0, 0
    db 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';'
    db "'", '`', 0, '\', 'z', 'x', 'c', 'v', 'b', 'n'
    db 'm', ',', '.', '/', 0, 0, 0, ' '
    times 256-64 db 0

section .text
start_shell:
    pusha
    call init_keyboard
    
    call init_filesystem
    
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

    mov edi, VIDEO_MEMORY + (80 * 24 + 2) * 2
    mov ecx, 78
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
    mov edi, VIDEO_MEMORY + (80 * 24 + 2) * 2
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
    imul eax, 160
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
    mov esi, input_buffer
    
    mov edi, cmd_cd
    call str_compare_prefix
    je .do_cd
    
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
    
    mov edi, cmd_pwd
    call str_compare
    je .do_pwd
    
    mov edi, cmd_ls
    call str_compare
    je .do_ls
    
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

.do_cd:
    mov esi, input_buffer + 3
    call fs_cd
    jmp .shell_loop

.do_pwd:
    call fs_pwd
    jmp .shell_loop

.do_ls:
    call fs_ls
    jmp .shell_loop

.print_response:
    movzx eax, byte [current_line]
    imul eax, 160
    mov edi, VIDEO_MEMORY
    add edi, eax
    call print_string
    mov esi, newline
    call print_string
    inc byte [current_line]
    jmp .shell_loop

.do_clear:
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
    
    jmp 0xFFFF:0x0000

init_filesystem:
    pusha
    mov dword [current_dir], root_dir
    popa
    ret

str_compare:
    push esi
    push edi
    .loop:
        mov al, [esi]
        mov bl, [edi]
        cmp al, bl
        jne .not_equal
        test al, al
        jz .equal
        inc esi
        inc edi
        jmp .loop
    .equal:
        xor eax, eax
        jmp .done
    .not_equal:
        mov eax, 1
    .done:
        pop edi
        pop esi
        test eax, eax
        ret

str_compare_prefix:
    push esi
    push edi
    .loop:
        mov al, [edi]
        test al, al
        jz .check_space
        cmp al, [esi]
        jne .not_equal
        inc esi
        inc edi
        jmp .loop
    .check_space:
        mov al, [esi]
        cmp al, ' '
        je .equal
        test al, al
        jz .equal
    .not_equal:
        mov eax, 1
        jmp .done
    .equal:
        xor eax, eax
    .done:
        pop edi
        pop esi
        test eax, eax
        ret

fs_cd:
    pusha
    
    cmp byte [esi], 0
    je .set_root
    
    cmp byte [esi], '/'
    je .set_root
    
    mov edi, parent_dir
    call str_compare
    je .parent_dir
    
    mov edi, bin_dir
    call str_compare
    je .set_bin
    
    mov edi, etc_dir
    call str_compare
    je .set_etc
    
    mov edi, home_dir
    call str_compare
    je .set_home
    
    mov edi, lib_dir
    call str_compare
    je .set_lib
    
    mov edi, media_dir
    call str_compare
    je .set_media
    
    mov edi, proc_dir
    call str_compare
    je .set_proc
    
    mov edi, root_dir_user
    call str_compare
    je .set_root_user
    
    mov edi, sys_dir
    call str_compare
    je .set_sys
    
    mov edi, tmp_dir
    call str_compare
    je .set_tmp
    
    mov edi, usr_dir
    call str_compare
    je .set_usr
    
    mov edi, usr_bin_dir
    call str_compare
    je .set_usr_bin
    
    mov edi, usr_lib_dir
    call str_compare
    je .set_usr_lib
    
    mov edi, usr_local_dir
    call str_compare
    je .set_usr_local
    
    mov edi, home_user_dir
    call str_compare
    je .set_home_user
    
    mov edi, home_user_docs_dir
    call str_compare
    je .set_home_user_docs
    
    mov edi, home_user_downloads_dir
    call str_compare
    je .set_home_user_downloads
    
    mov esi, invalid_path_msg
    jmp .print_error

.set_root:
    mov dword [current_dir], root_dir
    jmp .done

.parent_dir:
    mov eax, [current_dir]
    cmp eax, home_user_downloads_dir
    je .set_home_user
    cmp eax, home_user_docs_dir
    je .set_home_user
    cmp eax, home_user_dir
    je .set_home
    cmp eax, usr_bin_dir
    je .set_usr
    cmp eax, usr_lib_dir
    je .set_usr
    cmp eax, usr_local_dir
    je .set_usr
    cmp eax, home_dir
    je .set_root
    jmp .set_root

.set_bin:
    mov dword [current_dir], bin_dir
    jmp .done

.set_etc:
    mov dword [current_dir], etc_dir
    jmp .done

.set_home:
    mov dword [current_dir], home_dir
    jmp .done

.set_lib:
    mov dword [current_dir], lib_dir
    jmp .done

.set_media:
    mov dword [current_dir], media_dir
    jmp .done

.set_proc:
    mov dword [current_dir], proc_dir
    jmp .done

.set_root_user:
    mov dword [current_dir], root_dir_user
    jmp .done

.set_sys:
    mov dword [current_dir], sys_dir
    jmp .done

.set_tmp:
    mov dword [current_dir], tmp_dir
    jmp .done

.set_usr:
    mov dword [current_dir], usr_dir
    jmp .done

.set_usr_bin:
    mov dword [current_dir], usr_bin_dir
    jmp .done

.set_usr_lib:
    mov dword [current_dir], usr_lib_dir
    jmp .done

.set_usr_local:
    mov dword [current_dir], usr_local_dir
    jmp .done

.set_home_user:
    mov dword [current_dir], home_user_dir
    jmp .done

.set_home_user_docs:
    mov dword [current_dir], home_user_docs_dir
    jmp .done

.set_home_user_downloads:
    mov dword [current_dir], home_user_downloads_dir

.done:
    popa
    ret

.print_error:
    movzx eax, byte [current_line]
    imul eax, 160
    mov edi, VIDEO_MEMORY
    add edi, eax
    call print_string
    mov esi, newline
    call print_string
    inc byte [current_line]
    popa
    ret

fs_pwd:
    pusha
    movzx eax, byte [current_line]
    imul eax, 160
    mov edi, VIDEO_MEMORY
    add edi, eax
    
    mov esi, [current_dir]
    call print_string
    
    mov esi, newline
    call print_string
    
    inc byte [current_line]
    popa
    ret

fs_ls:
    pusha
    movzx eax, byte [current_line]
    imul eax, 160
    mov edi, VIDEO_MEMORY
    add edi, eax
    mov esi, dir_contents_msg
    call print_string
    
    mov esi, newline
    call print_string
    
    inc byte [current_line]
    
    mov eax, [current_dir]
    
    cmp eax, root_dir
    je .list_root
    
    cmp eax, home_dir
    je .list_home
    
    cmp eax, usr_dir
    je .list_usr
    
    cmp eax, home_user_dir
    je .list_home_user
    
    movzx eax, byte [current_line]
    imul eax, 160
    mov edi, VIDEO_MEMORY
    add edi, eax
    
    mov esi, dir_entry_fmt
    call print_string
    mov esi, [current_dir]
    call print_string
    
    mov esi, newline
    call print_string
    
    inc byte [current_line]
    jmp .done
    
.list_root:
    mov esi, bin_dir
    call print_dir_entry
    
    mov esi, etc_dir
    call print_dir_entry
    
    mov esi, home_dir
    call print_dir_entry
    
    mov esi, lib_dir
    call print_dir_entry
    
    mov esi, media_dir
    call print_dir_entry
    
    mov esi, proc_dir
    call print_dir_entry
    
    mov esi, root_dir_user
    call print_dir_entry
    
    mov esi, sys_dir
    call print_dir_entry
    
    mov esi, tmp_dir
    call print_dir_entry
    
    mov esi, usr_dir
    call print_dir_entry
    jmp .done
    
.list_home:
    mov esi, home_user_dir
    call print_dir_entry
    jmp .done
    
.list_usr:
    mov esi, usr_bin_dir
    call print_dir_entry
    
    mov esi, usr_lib_dir
    call print_dir_entry
    
    mov esi, usr_local_dir
    call print_dir_entry
    jmp .done
    
.list_home_user:
    mov esi, home_user_docs_dir
    call print_dir_entry
    
    mov esi, home_user_downloads_dir
    call print_dir_entry
    
.done:
    popa
    ret

print_dir_entry:
    push esi

    movzx eax, byte [current_line]
    imul eax, 160
    mov edi, VIDEO_MEMORY
    add edi, eax

    mov esi, dir_entry_fmt
    call print_string

    pop esi
    movzx eax, byte [current_line]
    imul eax, 160
    mov edi, VIDEO_MEMORY
    add edi, eax
    add edi, 8

    call print_string

    push esi
    mov esi, newline
    call print_string
    pop esi

    inc byte [current_line]
    ret

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
