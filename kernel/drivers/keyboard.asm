bits 32

KEYBOARD_DATA_PORT equ 0x60
KEYBOARD_STATUS_PORT equ 0x64

KEY_ENTER equ 0x1C
KEY_BACKSPACE equ 0x0E

global init_keyboard
global read_key

init_keyboard:
;for the later use
    ret

read_key:
    in al, KEYBOARD_STATUS_PORT
    test al, 0x01
    jz .no_key
    
    in al, KEYBOARD_DATA_PORT
    ret
    
.no_key:
    xor al, al
    ret
