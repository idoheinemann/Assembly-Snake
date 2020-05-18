include data.inc

.const
MAX_MEMORY_SIZE equ 20
NEGATIVE_SIGN equ 10000000000000000000000000000000b
.data

layer1 DWORD ?
layer2 DWORD ?
layer3 DWORD ?

replay_memory List<>

num1 REAL4 1.0
alpha REAL4 0.001

.code

forwardpass MACRO input,layer,var ; feed forward from the input through the layer to the output (var)
	invoke matrix_mul,input,layer ; matrix multiplication between the input and the layer
	;invoke matrix_elementwize,eax,offset sigmoid ; apply nonliniarity
	mov var,eax ; initialize output
endm

sigmoid PROC,x:REAL4
	or x,NEGATIVE_SIGN
	invoke exp,x
	fld1
	fld1
	fld_reg eax
	faddp st(1),st
	fdivp st(1),st
	fstp_reg eax
	ret
sigmoid ENDP

initialize PROC
	pusha
	invoke random_matrix,25*25*3,1200
	mov layer1,eax
	invoke random_matrix,1200,800
	mov layer2,eax
	invoke random_matrix,800,3
	mov layer3,eax
	popa
	ret
initialize ENDP

remember PROC,obs:DWORD
	pusha
	.if replay_memory.count >= MAX_MEMORY_SIZE
		invoke list_delete_at,offset replay_memory,0
	.endif
	invoke list_insert,offset replay_memory,obs
	popa
	ret
remember ENDP

get_observation PROC ; snake, head, apple
	local obs:DWORD
	push ebx
	push ecx
	push edx
	push edi
	push esi

	invoke zero_matrix,1,25*25*3
	mov obs,eax
	
	invoke list_get_item,offset snake,0
	mov ebx,eax
	mov ecx,20
	mov eax,[ebx.Square].x
	xor edx,edx
	div ecx
	mov edi,eax
	mov eax,[ebx.Square].y
	mov ecx,4
	div ecx
	mov ecx,5
	mul ecx
	add eax,edi
	mov ecx,3
	mul ecx
	inc eax
	invoke matrix_set_element,obs,1,eax,num1

	mov esi,1
	the_loop:
		invoke list_get_item,offset snake,esi
		mov ebx,eax
		mov ecx,20
		mov eax,[ebx.Square].x
		xor edx,edx
		div ecx
		mov edi,eax
		mov eax,[ebx.Square].y
		mov ecx,4
		div ecx
		mov ecx,5
		mul ecx
		add eax,edi
		mov ecx,3
		mul ecx
		invoke matrix_set_element,obs,1,eax,num1
	inc esi
	cmp esi,snake.count
	jl the_loop

	mov ecx,20
	mov eax,apple.x
	xor edx,edx
	div ecx
	mov edi,eax
	mov eax,apple.y
	mov ecx,4
	div ecx
	mov ecx,5
	mul ecx
	add eax,edi
	mov ecx,3
	mul ecx
	add eax,2
	invoke matrix_set_element,1,obs,eax,num1
	
	mov eax,obs
	pop esi
	pop edi
	pop edx
	pop ecx
	pop ebx
	ret
get_observation ENDP

hypot PROC, obs:DWORD
	local tmp1,tmp2
	forwardpass obs,layer1,tmp1
	forwardpass tmp1,layer2,tmp2
	forwardpass tmp2,layer3,eax
	invoke matrix_delete,tmp2
	invoke matrix_delete,tmp1
	ret
hypot ENDP

iteration PROC
	local tmp2:DWORD,tmp3:DWORD,output:DWORD,input1:DWORD,labels:DWORD ; temporary output for each layer
	local delta3:DWORD,delta2:DWORD,delta1:DWORD; temporary delta for neurons

	pusha

	;; TODO load minibatch

	;; forward pass
	forwardpass input1, layer1, tmp2
	forwardpass tmp2,layer2,tmp3
	forwardpass tmp3,layer3,output
	
	;; calculate delta

	invoke matrix_minus,labels,output ; error
	mov delta3,eax
	;invoke matrix_element_function,output,offset sigtag
	invoke matrix_elementwize_mul,delta3,output
	invoke matrix_delete,eax
	; output layer delta = error.*sigtag(output), .* stands for elementwize multiplication

	;invoke matrix_element_function,tmp3,offset sigtag
	invoke matrix_transpose,layer3
	mov ebx,eax
	invoke matrix_mul,delta3,eax
	invoke matrix_delete,ebx
	mov delta2,eax
	; layer2 delta = sigma(layer3_delta*layer3) .* sigtag(output)

	invoke matrix_transpose,layer2
	mov ebx,eax
	invoke matrix_mul,delta2,eax
	invoke matrix_delete,ebx
	mov delta1,eax 
	; layer1 delta = sigma (layer2_delta*layer2) .* sigtag(output)


	;; readjust the weights

	;; deltaWeight = deltaNeuron*input
	
	invoke matrix_transpose,tmp3
	mov ebx,eax
	invoke matrix_mul,eax,delta3 ; inp1'
	invoke matrix_delete,ebx
	invoke matrix_scalar_mul,eax,alpha
	invoke matrix_add,layer3,eax
	invoke matrix_delete,eax
	;; layer3

	invoke matrix_transpose,tmp2
	mov ebx,eax
	invoke matrix_mul,eax,delta2
	invoke matrix_delete,ebx
	invoke matrix_scalar_mul,eax,alpha
	invoke matrix_add,layer2,eax
	invoke matrix_delete,eax
	;; layer2


	invoke matrix_transpose,input1
	mov ebx,eax
	invoke matrix_mul,eax,delta1
	invoke matrix_delete,ebx
	invoke matrix_scalar_mul,eax,alpha
	invoke matrix_add,layer1,eax
	invoke matrix_delete,eax
	;; layer1

	;; delete locals
	invoke matrix_delete,tmp2
	invoke matrix_delete,tmp3
	invoke matrix_delete,output
	invoke matrix_delete,delta1
	invoke matrix_delete,delta2
	invoke matrix_delete,delta3



	popa
	ret
iteration ENDP