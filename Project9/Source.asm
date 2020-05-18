include learn_snake.inc

.686

.const
WHITE equ 0ffffffh
BLUE equ 0ff0000h
GREEN equ 0ff00h
RED equ 0ffh
BLACK equ 0

.data


.code
keys_handle PROC,keycode:DWORD
	cmp keycode,VK_DOWN
	jnz not_down_key
		cmp diry,0
		jnz the_end
		mov diry,20
		mov dirx,0
	not_down_key:
	cmp keycode,VK_UP
	jnz not_up_key
		cmp diry,0
		jnz the_end
		mov diry,-20
		mov dirx,0
	not_up_key:
	cmp keycode,VK_RIGHT
	jnz not_right_key
		cmp dirx,0
		jnz the_end
		mov dirx,20
		mov diry,0
	not_right_key:
	cmp keycode,VK_LEFT
	jnz not_left_key
		cmp dirx,0
		jnz the_end
		mov dirx,-20
		mov diry,0
	not_left_key:
	the_end:
	ret
keys_handle ENDP

random_int PROC,min:DWORD,max:DWORD
	push edx
	push ebx
	rdrand eax
	mov ebx,max
	sub ebx,min ; range
	xor edx,edx
	div ebx
	mov eax,edx
	add eax,min
	pop ebx
	pop edx
	ret
random_int ENDP

new_square PROC,x:DWORD,y:DWORD,w:DWORD,color:DWORD
	push ebx
	push ecx
	push edx
	invoke Alloc,sizeof Square
	sq equ [eax.Square]
	mov ebx,x
	mov sq.x,ebx
	mov ebx,y
	mov sq.y,ebx
	mov ebx,w
	mov sq.w,ebx
	mov ebx,color
	mov sq.color,ebx
	pop edx
	pop ecx
	pop ebx
	ret
new_square ENDP

draw_square PROC,sqr:DWORD
	push ebx
	mov ebx,sqr
	sq equ [ebx.Square]
	invoke adp_fill_rect,sq.x,sq.y,sq.w,sq.w,sq.color
	invoke adp_draw_rect,sq.x,sq.y,sq.w,sq.w,BLACK
	pop ebx
	ret
draw_square endp

start_game PROC
	pusha
	mov in_game,1

	invoke adp_textfield_get_text,offset name_field
	push eax
	invoke concat, reparg("PLAYER: "),eax
	mov name_str,eax
	pop eax
	invoke Free,eax

	invoke adp_button_delete,offset start_button
	invoke adp_textfield_delete,offset name_field
	popa
	ret
start_game ENDP

colision PROC,rc1:DWORD,rc2:DWORD
	push ebx
	push ecx
	push edx
	mov ebx,rc1
	sq1 equ [ebx.Square]
	mov ecx,rc2
	sq2 equ [ecx.Square]
	
	mov edx,sq1.x
	add edx,sq1.w
	cmp edx,sq2.x
	jle retfalse

	mov edx,sq1.y
	add edx,sq1.w
	cmp edx,sq2.y
	jle retfalse

	mov edx,sq2.x
	add edx,sq2.w
	cmp edx,sq1.x
	jle retfalse

	mov edx,sq2.y
	add edx,sq2.w
	cmp edx,sq1.y
	jle retfalse

	mov eax,1
	jmp the_end
	retfalse:
	xor eax,eax
	the_end:
	pop edx
	pop ecx
	pop ebx
	ret
colision ENDP

snake_colision PROC,obj:DWORD
	push ebx
	push ecx
	push edx

	mov ecx,1
	jmp _test
	the_loop:
	invoke list_get_item,offset snake,ecx
	invoke colision,eax,obj
	test eax,eax
	jnz rettrue
	inc ecx
	_test:
	cmp ecx,snake.count
	jl the_loop
	xor eax,eax
	jmp the_end
	rettrue:
	mov eax,1
	the_end:
	pop edx
	pop ecx
	pop ebx
	ret
snake_colision ENDP

square_copy PROC,dst:DWORD,src:DWORD
	push edi
	push esi
	mov esi,src
	mov edi,dst
	movsd
	movsd
	pop edi
	pop esi
	ret
square_copy ENDP

move_apple PROC
	push eax
	push edx
	the_label:
	invoke random_int,0,24 ; 500/20 - 1
	mov edx,20
	mul edx
	mov apple.y,eax
	invoke random_int,0,24
	mov edx,20
	mul edx
	mov apple.x,eax
	invoke snake_colision,offset apple
	test eax,eax
	jnz the_label
	pop edx
	pop eax
	ret
move_apple ENDP

update_score PROC
	pusha
	cmp score_str,0
	jz dont_delete
		invoke Free,score_str
	dont_delete:
	invoke int_to_string,score
	push eax
	invoke concat,reparg("SCORE: "),eax
	mov score_str,eax
	pop eax
	invoke Free,eax
	popa
	ret
update_score ENDP

draw_snake PROC
	xor ecx,ecx
	jmp _test
	the_loop:
		invoke list_get_item,offset snake,ecx
		invoke draw_square,eax
	inc ecx
	_test:
	cmp ecx,snake.count
	jl the_loop
	ret
draw_snake ENDP

main proc
	invoke adp_open_window,540,540,reparg("ADP SNAKE")
	invoke adp_add_key_listener,keys_handle

	invoke adp_load_image,offset background_img,reparg("snake.jpg")

	invoke adp_create_button,offset start_button,207,45,100,30, reparg("Start Game"),offset start_game
	invoke adp_create_textfield,offset name_field,180,80,150,20
	
	invoke adp_set_icon,reparg("icon.ico")

	before_loop:
		invoke adp_clear_screen_to_color,WHITE
		Invoke adp_draw_image_scale,offset background_img,0,0,540,540
		invoke adp_main
		invoke Sleep,5
	cmp in_game,0
	jz before_loop

	;invoke adp_add_async_key_listener,VK_LEFT,left_key
	;invoke adp_add_async_key_listener,VK_RIGHT,right_key
	;invoke adp_add_async_key_listener,VK_UP,up_key
	;invoke adp_add_async_key_listener,VK_DOWN,down_key
	
	invoke new_square,240,240,20,GREEN
	mov snake_head,eax
	invoke list_insert,offset snake,eax
	invoke move_apple
	invoke update_score

	in_game_loop:
		invoke list_get_item,offset snake,0 ; head
		mov ebx,eax
		invoke snake_colision,eax
		test eax,eax
		jz no_end_game
			end_game:
			mov in_game,0
			jmp after_game_loop
		no_end_game:
		cmp [ebx.Square].x,0
		jl end_game
		cmp [ebx.Square].y,0
		jl end_game
		cmp [ebx.Square].x,500
		jg end_game
		cmp [ebx.Square].y,500
		jg end_game

		invoke colision,ebx,offset apple
		test eax,eax
		jz not_touched_apple
			inc score
			invoke update_score
			invoke move_apple
			invoke new_square,-50,-50,20,GREEN
			invoke list_insert,offset snake,eax
		not_touched_apple:

		mov ecx,snake.count
		dec ecx
		jmp _test
		the_loop:
			invoke list_get_item,offset snake,ecx
			mov ebx,eax
			dec ecx
			invoke list_get_item,offset snake,ecx
			inc ecx
			invoke square_copy,ebx,eax
		dec ecx
		_test:
		test ecx,ecx
		jnz the_loop

		mov ebx,snake_head
		mov eax,dirx
		add [ebx.Square].x,eax
		mov eax,diry
		add [ebx.Square].y,eax

		invoke adp_clear_screen_to_color,BLACK
		invoke draw_square,offset apple
		invoke draw_snake
		invoke adp_draw_text,5,5,name_str,20,WHITE
		invoke adp_draw_text,350,5,score_str,20,WHITE

		invoke adp_main
		invoke Sleep,70
		
	jmp in_game_loop

	after_game_loop:
		invoke adp_clear_screen_to_color,WHITE
		invoke adp_draw_text,30,30,reparg("GAME OVER"),80,BLACK
		invoke adp_draw_text,50,300,score_str,40,BLACK
		invoke adp_main
		invoke Sleep,5
	jmp after_game_loop
	ret
main endp
end main