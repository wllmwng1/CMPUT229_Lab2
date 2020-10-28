.data
colors:		#Should not be shorter than paletteSize
	#Size 20 Red->Yellow->White->Magenta->Red
	.byte	196 202 208 214 220 226 227 228 229 230 231 225 219 213 207 201 200 199 198 197

.text
main:
	la $t1 colors		#get address colors
	lbu $t2 0($t1)
	move $a0, $t2
	li $v0, 1
	syscall
	jr $ra