include \masm32\include\masm32rt.inc
include heinemannlib.inc
includelib heinemannlib.lib
include adp_gui.inc
includelib adp_gui.lib
.data

Square STRUCT
	x DWORD ?
	y DWORD ?
	w DWORD ?
	color DWORD ?
Square ENDS

start_button Button<>
name_field TextField<>

snake List<>
apple Square<0,0,20,RED>

score DWORD ?

score_str DWORD ?
name_str DWORD ?

in_game BYTE ?

snake_head DWORD ?

dirx DWORD 20
diry DWORD ?

background_img Img<>