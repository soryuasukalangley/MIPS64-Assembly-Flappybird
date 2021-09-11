
# Bitmap Display Configuration:
# - Unit width in pixels: 8				     
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
.data
	displayAddress:	.word	0x10008000
	#Screen 
	screenWidth: 	.word 	32
	screenHeight: 	.word 	32
	#color
	birdColor:  	.word  	0xf5e642
	pipeColor:  	.word  	0x56a106
	skyColor:   	.word  	0x44cff2
	#bird
	birdX: 		.word 	6
	birdY:		.word 	15
	
	#pipe starting position
	pipeX:		.word 	28
	#Hole starting position
	Hole:		.word   15
	
.globl main
.text
	
main:
	#store position data for bird and pipe on stack
	lw $t0, birdY
	lw $t1, pipeX
	lw $t2, Hole
	addi $sp, $sp, 12
	sw $t0, 0($sp)
	sw $t1, 4($sp)
	sw $t2, 8($sp)

	CheckInput:
		li $t0, 0xffff0000
		lw $t1, 0($t0)
		beq $t1, 0, noInput
	
	hasInput:
		li $t0, 0xffff0004
		lw $t1, 0($t0)
		addi $t1, $t1, -102
		beq $t1, 0, birdJump

	noInput:
		lw $t0, 0($sp)
		addi $t0, $t0, 1
		j Heightcheck
		
	birdJump:
		lw $t0, 0($sp)
		addi $t0, $t0, -2 #jump 2 units
	
	Heightcheck:
		#check collisions
		li $t2, 1
		sle $t1, $t2, $t0
		beq $t1, 0, DontGoTooHigh 
		j storeJump
		
	DontGoTooHigh:
		li $t0, 1#max height
	
	storeJump:
		sw $t0, 0($sp)
		
	#background
	DrawBackground:
		lw, $v1, pipeX
		lw $a0, screenWidth
		lw $a1, skyColor
		mul $a2, $a0, $a0 #total number of pixels on screen
		mul $a2, $a2, 4 #align addresses
		add $a2, $a2, $gp #add base of gp
		add $a0, $gp, $zero #loop counter
	
	FillLoop:
		beq $a0, $a2, DrawPipe
		sw $a1, 0($a0) #store color
		addi $a0, $a0, 4 #increment counter
		j FillLoop

	DrawPipe:
	
	lw $v1, 4($sp)
	bne $v1, 0, Loop
	li $v1, 28#generate a new pipe
	sw $v1, 4($sp)
	# space in pipe
  	li $v0, 42  # 42 is system call code to generate random int for x
	li $a1, 24    # $a1 is where you set the upper bound -> 30-6
	syscall     # your generated number will be at $a0
	add $a0, $a0, 8 # set lower bound 8
	sw $a0, 8($sp)
	
	
	Loop:
	#nested loop to draw pipe
	lw $v1, 4($sp) #pipe pos
	lw $a0, 8($sp) #hole pos
	addi $a0, $a0, -3 #upper and lower bound
	addi $a1, $a0, 6
	li $t7, 0 #from row 1
	LoopOneColumn:
		move $t6, $v1
		addi $t5, $t6, 4
		IF: #is this part of space?
				sle $t0, $a0, $t7
				slt $t1, $t7, $a1
				and $t0, $t1, $t0
				beq $t0, 1, ELSE	
		THEN:
			LoopOneRow:
				addi $sp, $sp, -12
				sw $t6, 0($sp)
				sw $t7, 4($sp)
				lw $t0, pipeColor
				sw $t0, 8($sp) #pass color into stack
				jal Draw
				
				addi $t6, $t6, 1
				bne $t6, $t5, LoopOneRow
		
		ELSE:		
			addi $t7, $t7, 1
			bne $t7, 32, LoopOneColumn
		
	DrawBird:
		#draw bird 
		lw $t1, 0($sp)#birdY
		addi $sp, $sp, -12 #pass 3 numbers to stack
		lw $t0, birdX
		lw $t2, birdColor
		sw $t0, 0($sp)
		sw $t1, 4($sp) 
		sw $t2, 8($sp)
		jal Draw	#draw color at pixel
	
	#check collision
	lw $t0, 0($sp)#load bird y-pos
	li $t2, 31
	sle $t1, $t2, $t0
	beq $t1, 1, Exit #if hits ground
	#check three sides
	lw $t1, birdX
	lw $t3, pipeColor
	mul $t0, $t0, 128
	mul $t1, $t1, 4
	lw $t2, displayAddress
	add $t1, $t1, $t0	#address of colorpixel
	add $t1, $t1, $t2
	#top
	addi $t1, $t1, -128
	lw $t0, 0($t1)
	beq $t3, $t0, Exit
	#bottom
	addi $t1, $t1, 256
	lw $t0, 0($t1)
	beq $t3, $t0, Exit
	#right
	addi $t1, $t1, -124
	lw $t0, 0($t1)
	beq $t3, $t0, Exit
	
	#sleep
	li $v0, 32
	li $a0, 300
	syscall
	
	addi $v1, $v1, -1 #move pipe left
	sw $v1, 4($sp)
	
	j CheckInput #refresh
	
	Exit:

		li $v0, 10 # terminate the program gracefully
		syscall

#Draw Function	
Draw:
	lw $t0, 0($sp)		#data from stack, t0=x, t1=y
	lw $t1, 4($sp)		
	lw $t3, 8($sp)		#color
	mul $t1, $t1, 128	#memory location
	mul $t0, $t0, 4 
	add $t2, $t0, $t1
	lw $t0, displayAddress
	add $t0, $t0, $t2
	sw $t3, 0($t0) 	#fill the coordinate with specified color
	addi $sp, $sp, 12
	jr $ra			# return 
