.data
bitmapDisplay: .space 0x80000 # enough memory for a 512x256 bitmap display
resolution: .word  512 256    # width and height of the bitmap display

windowlrbt: 
.float -2.5 2.5 -1.25 1.25  					# good window for viewing Julia sets
#.float -3 2 -1.25 1.25  					# good window for viewing full Mandelbrot set
#.float -0.807298 -0.799298 -0.179996 -0.175996 		# double spiral
#.float -1.019741354 -1.013877846  -0.325120847 -0.322189093 	# baby Mandelbrot
 
bound: .float 100	# bound for testing for unbounded growth during iteration
maxIter: .word 16	# maximum iteration count to be used by drawJulia and drawMandelbrot
scale: .word 16		# scale parameter used by computeColour

# Julia constants for testing, or likewise for more examples see
# https://en.wikipedia.org/wiki/Julia_set#Quadratic_polynomials  
JuliaC0:  .float 0  0    # should give you a circle, a good test, though boring!
JuliaC1:  .float 0.25 0.5
JuliaC2:  .float 0    0.7 
JuliaC3:  .float 0    0.8 

# a demo starting point for iteration tests
z0: .float  0 0

plus:	.asciiz " + "
equal: 	.asciiz " = "
complex:	.asciiz  " i"
newline: .asciiz  "\n"
x:	.asciiz "x"
y:	.asciiz  "y"
seed: .word 12345678
two: .float 2.0
reverseMaxIter: .word 10000

########################################################################################
.text
	
	la $t0, JuliaC1
	lwc1 $f12, 0($t0)
	lwc1 $f13, 4($t0)
	jal drawJulia
	#jal drawMandelbrot
					
	li $v0 10 # exit
	syscall


#printComplex(float x, float y): Prints input in the form "x + y i"
printComplex:
	li $v0, 2 #Set syscall to float
	syscall #Print float x
	li $v0, 4 #Set syscall to string
	la $a0, plus
	syscall #Print " + "
	mov.s $f18, $f12
	mov.s $f12, $f13 #Set next value to be printed to the second input argument $f13
	li $v0, 2 #Set syscall to float
	syscall #Print float y
	mov.s $f12, $f18
	li $v0, 4 #Set syscall to string
	la $a0, complex
	syscall #print " i"
	jr $ra
	
	
#printNewLine(): Prints a new line
printNewLine:
	li $v0, 4 #Set syscall to string
	la $a0, newline
	syscall
	jr $ra
	
	
#multComplex(float a, float b, float c, float d): Computes complex product (ac-db)+(ad+bc)i
multComplex:
	mul.s $f4, $f12, $f14 #(ac)
	mul.s $f5, $f13, $f15 #(bd)
	sub.s $f0, $f4, $f5 #(ac - bd) This is the real part
	mul.s $f6, $f12, $f15 #(ad)
	mul.s $f7, $f13, $f14 #(bc)
	add.s $f1, $f6, $f7 #(ad + bc) This is the imaginary part
	jr $ra
	
	
#int iterateVerbose(int n, float a, float b, float x0, float y0): Compute n iterations of f(x, y) = (x^2 - y^2 + a, 2xy + b)
iterateVerbose: #The initial values x0 and y0 do not count as an iteration and the function will iterate from 1 to n.
	subi $sp, $sp, 8
	swc1 $f21, 4($sp)
	swc1 $f20, 0($sp) #Store constants float a and b in the stack to preserve value in case it is needed by the caller, as these save registers will be overwritten soon
	mov.s $f20, $f14 #Initialize total value of x to its first value (x0)
	mov.s $f21, $f15 #Initialize total value of y to its first value (y0)
	subi $sp, $sp, 4
	sw $s0, 0($sp) #Save $s0 to the stack in case it is used by the caller
	move $s0, $a0 #Store the maximum number of iterations n in a save register - this also means we no longer care about the value of $a0 and it can be overwritten without saving to the stack
	move $t0, $zero #Set the current iteration number, i, to 0
	move $a0, $t0 #Set the input integer for printIteration() to the current iteration number (which is currently 0 as the iteration hasn't started)
	subi $sp, $sp, 24
	swc1 $f15, 20($sp)
	swc1 $f14, 16($sp)
	swc1 $f13, 12($sp)
	swc1 $f12, 8($sp) #Save the argument registers to the stack so that they can be used later
	sw $t0, 4($sp) #Save the iteration number to the stack, as it will be called again after printIteration() is called
	sw $ra, 0($sp) #Saves $ra on stack
	mov.s $f12, $f14
	mov.s $f13, $f15 #Set the arguments for printIteration to x0 and y0
	jal printIteration
	lwc1 $f15, 20($sp)
	lwc1 $f14, 16($sp)
	lwc1 $f13, 12($sp)
	lwc1 $f12, 8($sp) #Load back the values for the argument registers
	lw $t0, 4($sp) #Load the iteration number from the stack
	lw $ra, 0($sp) #Load $ra from the stack
	addi $sp, $sp, 24
  	
  	iVLoop: #Start looping
		addi $t0 $t0, 1 #Increment the current iteration number by 1, because 0 is the initial value it does not count as an iteration so the loop begins at 1
		subi $sp, $sp, 8
		#swc1 $f15, 4($sp)
		#swc1 $f14, 0($sp)
		swc1 $f13, 4($sp)
		swc1 $f12, 0($sp) #Save the argument registers to the stack so that they can be used later
		subi $sp, $sp, 8
		sw $t0, 4($sp) #Save the current iteration number to the stack as it will be used later
		sw $ra, 0($sp) #Saves $ra on stack
		mov.s $f8, $f12
		mov.s $f9, $f13
		mov.s $f12, $f14
		mov.s $f13, $f15
		mov.s $f14, $f8
		mov.s $f15, $f9 #Invert order of input arguments $f12-$f15 to the correct format for equationOne(x, y, a, b)
		jal equationOne
		lw $t0, 4($sp) #Load the current iteration number to keep using it
		lw $ra, 0($sp) #Load $ra from the stack
		addi $sp, $sp, 8
		add.s $f20, $f20, $f0 #Increment the total value of x by the value of x at the current iteration
		add.s $f21, $f21, $f1 #Increment the total value of y by the value of y at the current iteration
		mul.s $f16, $f20, $f20 #x^2
		mul.s $f17, $f21, $f21 #y^2
		add.s $f11, $f16, $f17 #x^2 + y^2
		lwc1 $f18, bound #Load the maximum bound value from memory
		c.lt.s $f18, $f11 #Check if (x^2 + Y^2) is greater than the bound
		bc1t iVGreater #If (x^2 + y^2) is greater than the bounds
		#Continue the loop here if (x^2 + y^2) is not greater
		mov.s $f14, $f0
		mov.s $f15, $f1 #Set the input registers $f14 and $f15 to the return value of equationOne() to use to print the iteration number in printIteration()
		move $a0, $t0 #Set argument int n of printIteration to the current iteration number
		subi $sp, $sp, 8
		sw $t0, 4($sp) #Save the current iteration number to the stack as it will be used later
		sw $ra, 0($sp) #Saves $ra on stack
		jal printIteration
		lw $t0, 4($sp) #Load the current iteration number to keep using it
		lw $ra, 0($sp) #Load $ra from the stack
		addi $sp, $sp, 8
		lwc1 $f13, 4($sp)
		lwc1 $f12, 0($sp) #Load back the values for the argument registers
		addi $sp, $sp, 8
		bne $t0, $s0, iVLoop #Go back to the start of the loop if the maximum number of iterations is not reached
		j endOfVLoop
		
		iVGreater:
		subi $t0, $t0, 1 #Set the value of the current iteration to that of the previous iteration, since the required value is that which is immediately before reaching the bound
  	
  	endOfVLoop: #End of loop
	move $a0, $t0 #Set the value to print to the total amount of iterations
	li $v0, 1 #Set syscall to int
	syscall #Print the total amount of iterations completed
	move $v0, $t0 #Set the return value to the total amount of iterations completed
	lw $s0, 0($sp) #Restore the value of $s0 in case the caller needs it
	addi $sp, $sp, 4
  	lwc1 $f21, 4($sp)
	lwc1 $f20, 0($sp) #Restore the constants float a and b from the stack to reuse in the parent function
  	addi $sp, $sp, 8
	jr $ra


#printIteration(int i, float x, float y): Prints "xi + yi i = x + y i"
printIteration:
	move $t0, $a0 #Let $t0 = i, the iteration number
	li $v0, 4 #Set syscall to string
	la $a0, x
	syscall #Print "x"
	li $v0, 1 #Set syscall to int
	move $a0, $t0 #Set the value to print to the current iteration number
	syscall #Print iteration number i
	li $v0, 4 #Set syscall to string
	la $a0, plus
	syscall #Print " + "
	la $a0, y
	syscall #Print "y"
	li $v0, 1 #Set syscall to int
	move $a0, $t0 #Set the value to print to the current iteration number
	syscall #Print iteration number i
	li $v0, 4 #Set syscall to string
	la $a0, complex
	syscall #print " i"
	la $a0, equal
	syscall #print " = "
	subi $sp, $sp, 4
	sw $ra, 0($sp) # Saves $ra on stack
	jal printComplex #Use printComplex() to print the complex number after the equality, ie (x + y i)
	lw $ra, 0($sp) #Load $ra from the stack
  	addi $sp, $sp, 4
  	subi $sp, $sp, 4
	sw $ra, 0($sp) # Saves $ra on stack
	jal printNewLine
	lw $ra, 0($sp) #Load $ra from the stack
  	addi $sp, $sp, 4
	jr $ra
	
	
#equationOne(float x, float y, float a, float b): Computes one iteration of Equation 1: f(x, y) = (x^2 - y^2 + a, 2xy + b)
equationOne:
	subi $sp, $sp, 12
	swc1 $f15, 8($sp)
	swc1 $f14, 4($sp)
	sw $ra, 0($sp) #Saves $ra on stack
	mov.s $f14, $f12
	mov.s $f15, $f13 #Sets athe input values of multComplex to compute the square of (a + bi)
	jal multComplex #(a + bi)^2 = (x^2 - y^2) + 2xy
	lw $ra, 0($sp)
	lwc1 $f14, 4($sp)
	lwc1 $f15, 8($sp)
  	addi $sp, $sp, 12
	add.s $f0, $f0, $f14 #(x^2 - y^2 + a)
	add.s $f1, $f1, $f15 #(2xy + b)
	jr $ra
	
	
#int iterate(int n, float a, float b, float x0, float y0): Compute n iterations of f(x, y) = (x^2 - y^2 + a, 2xy + b)
iterate: #The initial values x0 and y0 do not count as an iteration and the function will iterate from 1 to n.
	subi $sp, $sp, 8
	swc1 $f21, 4($sp)
	swc1 $f20, 0($sp) #Store constants float a and b in the stack to preserve value
	mov.s $f8, $f12
	mov.s $f9, $f13
	mov.s $f12, $f14
	mov.s $f13, $f15
	mov.s $f14, $f8
	mov.s $f15, $f9 #Invert order of input arguments $f12-$f15 to the correct format for equationOne(x, y, a, b)
	mov.s $f20, $f12 #Initialize total value of x to its first value
	mov.s $f21, $f13 #Initialize total value of y to its first value
	move $s0, $a0 #Store the maximum number of iterations n in a save register so that it can easily be used in different labels
	move $t0, $zero #Set the current iteration number, i, to 0
	subi $sp, $sp, 4
	sw $ra, 0($sp) # Saves $ra on stack
	jal iLoop
	move $v0, $t0 #Set the return value to the total amount of iterations completed
	lw $ra, 0($sp) #Load $ra from the stack
  	addi $sp, $sp, 4
 	lwc1 $f21, 4($sp)
	lwc1 $f20, 0($sp) #Restore the constants float a and b from the stack to reuse in the parent function
  	addi $sp, $sp, 8
	jr $ra
	
iLoop:
	addi $t0, $t0, 1 #Increment the current iteration number by 1, because 0 is the initial values it does not count as an iteration so the loop begins at 1
	subi $sp, $sp, 4
	sw $ra, 0($sp) # Saves $ra on stack
	jal equationOne
	add.s $f20, $f20, $f0 #Increment the total value of x by the value of x at the current iteration
	add.s $f21, $f21, $f1 #Increment the total value of y by the value of y at the current iteration
	mul.s $f16, $f20, $f20 #x^2
	mul.s $f17, $f21, $f21 #y^2
	add.s $f11, $f16, $f17 #x^2 + y^2
	lwc1 $f18, bound #Load the maximum bound value from memory
	c.lt.s $f18, $f11 #Check if (x^2 + Y^2) is greater than the bound
	bc1t iGreater #If (x^2 + y^2) is greater than the bounds
	#Continue the loop here if (x^2 + y^2) is not greater
	mov.s $f12, $f0
	mov.s $f13, $f1 #Set the input registers $f12 and $f13 to the return value of equationOne() to pass back as input to the same function on the next iteration
	lw $ra, 0($sp) 
  	addi $sp, $sp, 4
	bne $t0, $s0, iLoop #Go back to the start of the loop if the maximum number of iterations is not reached
	jr $ra #Exit the loop when at the maximum number of iterations
	
	iGreater:
	subi $t0, $t0, 1 #Set the value of the current iteration to that of the previous iteration, since the required value is that which is immediately before reaching the bound
	lw $ra, 0($sp) #Load $ra from the stack
  	addi $sp, $sp, 4
	jr $ra #Exit the loop
	

#pixel2ComplexInWindow(int col, int row)
pixel2ComplexInWindow:
	la $t0, resolution
	la $t1, windowlrbt
	lw $t2, 0($t0) #Load the width
	lw $t3, 4($t0) #Load the height
	mtc1 $t2, $f8 #Width
	cvt.s.w $f8, $f8 #Cast the width as a float
	mtc1 $t3, $f9 #Height
	cvt.s.w $f9, $f9 #Cast the height as a float
	mtc1 $a0, $f12 #col
	cvt.s.w $f12, $f12 #Cast the column number as a float
	mtc1 $a1, $f13 #row
	cvt.s.w $f13, $f13 #Cast the row number as a float
	lwc1 $f4, 0($t1) #left
	lwc1 $f5, 4($t1) #right
	lwc1 $f6, 8($t1) #bottom
	lwc1 $f7, 12($t1) #top
	#Calculate x
	div.s $f0, $f12, $f8 #x = col/w
	sub.s $f10, $f5, $f4 #(r - l)
	mul.s $f0, $f0, $f10 #x = (col/w)(r - l)
	add.s $f0, $f0, $f4 #x = (col/w)(r - l) + l
	#Calculate y
	div.s $f1, $f13, $f9 #y = row/h
	sub.s $f11, $f7, $f6 #(t - b)
	mul.s $f1, $f1, $f11 #y = (row/h)(t - b)
	add.s $f1, $f1, $f6 #y = (row/h)(t - b) + b
	jr $ra
	
	
#drawJulia(float a, float b): Draws the Julia set for given constants a and b
drawJulia:
	li $t0, 0 #int i = 0 | Set the current pixel of the column to 0
	la $t1, resolution
	lw $s6 0($t1) #Width
	lw $s7 4($t1) #Height
	lw $s5, maxIter #Save the maximum number of iterations
	mov.s $f20, $f12 #Store float a in a save register for easier use
	mov.s $f21, $f13 #Store float b in a save register for easier use
	
	dJOuterLoop: #for (int i = 0; i <= width; i++)
		beq $t0, $s6, dJEnd #i <= width
		li $t1, 0 #int j = 0 | Set the current pixel of the row to 0
		addi $t0, $t0, 1 #i++
		
		dJInnerLoop: #for (int j = 0; j <= height; j++)
		beq $t1, $s7, dJOuterLoop #j <= height
		move $a0, $t0
		move $a1, $t1 #Set the input coordinate values to the current pixel for pixel2ComplexInWindow()
		subi $sp, $sp, 12
		sw $t1, 8($sp)
		sw $t0, 4($sp) #Store the current pixel value on the stack to reuse
		sw $ra, 0($sp) #Saves $ra on stack
		jal pixel2ComplexInWindow
		lw $ra, 0($sp) #Load $ra from the stack
		lw $t0, 4($sp)
		lw $t1, 8($sp) #Load the current pixel value from the stack to continue iterating
  		addi $sp, $sp, 12
		move $a0, $s5
		mov.s $f12, $f20
		mov.s $f13, $f21
		mov.s $f14, $f0
		mov.s $f15, $f1 #Set the input values for iterate()
		subi $sp, $sp, 12
		sw $t1, 8($sp)
		sw $t0, 4($sp) #Store the current pixel value on the stack to reuse
		sw $ra, 0($sp) #Saves $ra on stack
		jal iterate
		lw $ra, 0($sp) #Load $ra from the stack
		lw $t0, 4($sp)
		lw $t1, 8($sp) #Load the current pixel value from the stack to continue iterating
  		addi $sp, $sp, 12
		la $t3, resolution
		blt $v0, $s5, dJBoundReached #If the bound was reached during iterate
		beq $v0, $s5, dJNotReached #If the bound was not reached during iterate
		
		dJBoundReached:
		move $a0, $v0 #Set the number of iterations to the input for computeColour()
		subi $sp, $sp, 12
		sw $t1, 8($sp)
		sw $t0, 4($sp) #Store the current pixel value on the stack to reuse
		sw $ra, 0($sp) #Saves $ra on stack
		jal computeColour
		lw $ra, 0($sp) #Load $ra from the stack
		lw $t0, 4($sp)
		lw $t1, 8($sp) #Load the current pixel value from the stack to continue iterating
  		addi $sp, $sp, 12
		move $t3, $v0 #Set the colour value to the output of computerColour()
		j dJContinue
		
		dJNotReached:
		li $t3, 0 #Set the colour value to black
		
		dJContinue: #Continue from here, whether the bound was reached or not
		la $t5, bitmapDisplay
		mul $t4, $s6, $t1
		add $t4, $t4, $t0
		li $t6, 4
		mul $t4, $t4, $t6
		add $t5, $t5, $t4
		sw $t3, ($t5) #Store the computed value into the bitmapDisplay memory
		
		addi $t1, $t1, 1 #j++
		j dJInnerLoop #Repeat the inner loop
		
	dJEnd:
	jr $ra #End loop


#drawMandelbrot()
drawMandelbrot:
	li $t0, 0 #int i = 0 | Set the current pixel of the column to 0
	la $t1, resolution
	lw $s6 0($t1) #Width
	lw $s7 4($t1) #Height
	lw $s5, maxIter #Save the maximum number of iterations
	mov.s $f20, $f12 #Store float a in a save register for easier use
	mov.s $f21, $f13 #Store float b in a save register for easier use
	
	dMOuterLoop: #for (int i = 0; i <= width; i++)
		beq $t0, $s6, dMEnd #i <= width
		li $t1, 0 #int j = 0 | Set the current pixel of the row to 0
		addi $t0, $t0, 1 #i++
		
		dMInnerLoop: #for (int j = 0; j <= height; j++)
		beq $t1, $s7, dMOuterLoop #j <= height
		move $a0, $t0
		move $a1, $t1 #Set the input coordinate values to the current pixel for pixel2ComplexInWindow()
		subi $sp, $sp, 12
		sw $t1, 8($sp)
		sw $t0, 4($sp) #Store the current pixel value on the stack to reuse
		sw $ra, 0($sp) #Saves $ra on stack
		jal pixel2ComplexInWindow
		lw $ra, 0($sp) #Load $ra from the stack
		lw $t0, 4($sp)
		lw $t1, 8($sp) #Load the current pixel value from the stack to continue iterating
  		addi $sp, $sp, 12
		move $a0, $s5
		mov.s $f12, $f0
		mov.s $f13, $f1
		mov.s $f14, $f20
		mov.s $f15, $f21 #Set the input values for iterate(), the order is reversed from drawJulia in order to draw the Mandelbrot set instead
		subi $sp, $sp, 12
		sw $t1, 8($sp)
		sw $t0, 4($sp) #Store the current pixel value on the stack to reuse
		sw $ra, 0($sp) #Saves $ra on stack
		jal iterate
		lw $ra, 0($sp) #Load $ra from the stack
		lw $t0, 4($sp)
		lw $t1, 8($sp) #Load the current pixel value from the stack to continue iterating
  		addi $sp, $sp, 12
		la $t3, resolution
		blt $v0, $s5, dMBoundReached #If the bound was reached during iterate
		beq $v0, $s5, dMNotReached #If the bound was not reached during iterate
		
		dMBoundReached:
		move $a0, $v0 #Set the number of iterations to the input for computeColour()
		subi $sp, $sp, 12
		sw $t1, 8($sp)
		sw $t0, 4($sp) #Store the current pixel value on the stack to reuse
		sw $ra, 0($sp) #Saves $ra on stack
		jal computeColour
		lw $ra, 0($sp) #Load $ra from the stack
		lw $t0, 4($sp)
		lw $t1, 8($sp) #Load the current pixel value from the stack to continue iterating
  		addi $sp, $sp, 12
		move $t3, $v0 #Set the colour value to the output of computerColour()
		j dMContinue
		
		dMNotReached:
		li $t3, 0 #Set the colour value to black
		
		dMContinue: #Continue from here, whether the bound was reached or not
		la $t5, bitmapDisplay
		mul $t4, $s6, $t1
		add $t4, $t4, $t0
		li $t6, 4
		mul $t4, $t4, $t6
		add $t5, $t5, $t4
		sw $t3($t5) #Store the computed value into the bitmapDisplay memory
		
		addi $t1, $t1, 1 #j++
		j dMInnerLoop #Repeat the inner loop
		
	dMEnd:
	jr $ra #End loop
	


########################################################################################
# Computes a colour corresponding to a given iteration count in $a0
# The colours cycle smoothly through green blue and red, with a speed adjustable 
# by a scale parametre defined in the static .data segment
computeColour:
	la $t0 scale
	lw $t0 ($t0)
	mult $a0 $t0
	mflo $a0
ccLoop:
	slti $t0 $a0 256
	beq $t0 $0 ccSkip1
	li $t1 255
	sub $t1 $t1 $a0
	sll $t1 $t1 8
	add $v0 $t1 $a0
	jr $ra
ccSkip1:
  	slti $t0 $a0 512
	beq $t0 $0 ccSkip2
	addi $v0 $a0 -256
	li $t1 255
	sub $t1 $t1 $v0
	sll $v0 $v0 16
	or $v0 $v0 $t1
	jr $ra
ccSkip2:
	slti $t0 $a0 768
	beq $t0 $0 ccSkip3
	addi $v0 $a0 -512
	li $t1 255
	sub $t1 $t1 $v0
	sll $t1 $t1 16
	sll $v0 $v0 8
	or $v0 $v0 $t1
	jr $ra
ccSkip3:
 	addi $a0 $a0 -768
 	j ccLoop
