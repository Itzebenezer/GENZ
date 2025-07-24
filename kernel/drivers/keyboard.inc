; keyboard.inc isnt usefull you can remove it if you want
; i thought i was going to use it but everything is covered up in keyboard.asm itself
KEYBOARD_DATA_PORT equ 0x60
KEYBOARD_STATUS_PORT equ 0x64

KEY_ENTER equ 0x1C
KEY_BACKSPACE equ 0x0E

global init_keyboard
global read_key
