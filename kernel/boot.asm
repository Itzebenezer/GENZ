bits 32
section .multiboot
    	align 4
    	dd 0x1BADB002             
    	dd 0x00                   
	dd -(0x1BADB002 + 0x00)   

section .text
global start
extern kmain                  

disable_cursor:
   	 pusha
   	 mov dx, 0x3D4
   	 mov al, 0x0A  
   	 out dx, al
     	 mov dx, 0x3D5
    	mov al, 0x20  
   	 out dx, al
   	 popa
   	 ret

start:
    	cli                         
    	mov esp, stack_space       
   
    	call disable_cursor        
    	call kmain                 
       	hlt                        

section .bss
resb 8192                      
stack_space:
