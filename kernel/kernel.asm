bits 32
global kmain
extern init_gui               

kmain:
	    call init_gui
	    hlt
