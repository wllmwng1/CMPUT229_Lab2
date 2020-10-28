#
# CMPUT 229 Public Materials License
# Version 1.1
#
# Copyright 2017 University of Alberta
# Copyright 2017 Austin Crapo
#
# This software is distributed to students in the course
# CMPUT 229 - Computer Organization and Architecture I at the University of
# Alberta, Canada. 
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the disclaimer below in the documentation
#    and/or other materials provided with the distribution.
# 
# 2. Neither the name of the copyright holder nor the names of its
#    contributors may be used to endorse or promote products derived from this
#    software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
######################
#Author: Austin Crapo
#Date: July 2017
#Version 1.0
#
# Fractal renderer to terminal via GLIM library.
# Uses floating point coprocessor for precision.
#
# Some notes for people wanting to make pretty renders
# if using monospace font 1, the ratio of columns
# to rows should equal 5.25 if rendering a portion
# of the complex plane where the ratio of real
# units in the field to imaginary units is 3.5/2
# which just so happens to include (real, imaginary)
# section ([-2.5, 1], [-1, 1])
#
######################

.data
	.align 2
symbols:		#Should not be shorter than paletteSize
	.asciiz "."
	.asciiz "_"
	.asciiz "~"
	.asciiz ":"
	.asciiz "+"
	.asciiz "="
	.asciiz "["
	.asciiz "{"
	.asciiz "$"
	.asciiz "#"
	.asciiz "@"
	.asciiz "&"
	.asciiz "}"
	.asciiz "}"
	.asciiz "*"
	.asciiz "+"
	.asciiz ";"
	.asciiz "~"
	.asciiz "-"
	.asciiz ","

	
inSetSymbol:
	.asciiz "M"
inSetColor:
	.byte 0
	
	.align 2
paletteSize:		#min(#symbols, #colors)
	.word	20
colors:		#Should not be shorter than paletteSize
	#Size 20 Red->Yellow->White->Magenta->Red
	.byte	196 202 208 214 220 226 227 228 229 230 231 225 219 213 207 201 200 199 198 197
	.align 2
x_0:
	.double 0.0
y_0:
	.double 0.0
x_n:
	.double 0.0
y_n:
	.double 0.0
prompt1:
	.asciiz "Number of rows to render (int): "
prompt2:
	.asciiz "Number of columns to render (int): "
prompt3:
	.asciiz "Maximum imaginary value (double): "
prompt4:
	.asciiz "Minimum imaginary value (double): "
prompt5:
	.asciiz "Maximum real value (double): "
prompt6:
	.asciiz "Minimum real value (double): "
prompt7:
	.asciiz "Max iterations to calculate (int): "
	.align 2
gameRows:
	.space 4
gameCols:
	.space 4
.text
main:	
	# Stack Adjustments
	addi	$sp, $sp, -4
	sw	$fp, 0($sp)
	add	$fp, $zero, $sp
	addi	$sp, $sp, -16
	sw	$ra, -4($fp)
	sw	$s0, -8($fp)
	sw	$s1, -12($fp)
	sw	$s2, -16($fp)
	
	##read the display size
	#Rows
	li	$v0, 4
	la	$a0, prompt1
	syscall
	li	$v0, 5
	syscall
	move	$s0, $v0
	#Cols
	li	$v0, 4
	la	$a0, prompt2
	syscall
	li	$v0, 5
	syscall
	move	$s1, $v0
	
	
	#get coordinates and set them for map_coords
	li	$v0, 4
	la	$a0, prompt3
	syscall
	li	$v0, 7
	syscall
	mov.d	$f12, $f0

	li	$v0, 4
	la	$a0, prompt4
	syscall
	li	$v0, 7
	syscall
	mov.d	$f14, $f0

	li	$v0, 4
	la	$a0, prompt5
	syscall
	li	$v0, 7
	syscall
	mov.d	$f16, $f0

	li	$v0, 4
	la	$a0, prompt6
	syscall
	li	$v0, 7
	syscall
	mov.d	$f18, $f0
	
	#provide the screen dimensions as well
	move	$a0, $s0
	move	$a1, $s1
	
	jal	set_size

	#get the max iterations value
	li	$v0, 4
	la	$a0, prompt7
	syscall
	li	$v0, 5
	syscall
	move	$s2, $v0
	
	#set the display size
	move	$a0, $s0
	move	$a1, $s1
	jal	startGLIM
	la	$t0, gameRows
	sw	$s0, 0($t0)
	la	$t0, gameCols
	sw	$s1, 0($t0)
	#prepare the screen
	#jal	clearScreen

	move	$a0, $s0
	move	$a1, $s1
	move	$a2, $s2
	jal	render


	#pause, waiting for input
	li	$v0, 5
	syscall

	li	$a0, 0
	li	$a1, 0
	jal	setColor
	jal	clearScreen
	
	
	
	#MUST BE CALLED BEFORE ENDING PROGRAM
	jal	endGLIM
	
	#Stack Restore
	lw	$ra, -4($fp)
	lw	$s0, -8($fp)
	lw	$s1, -12($fp)
	lw	$s2, -16($fp)
	addi	$sp, $sp, 16
	lw	$fp, 0($sp)
	addi	$sp, $sp, 4
	
	jr	$ra
	
.data
max_i:
	.double	1.0
min_r:
	.double	-2.5
step_r:
	.double 1.0
step_i:
	.double 1.0
.text
map_coords:
	########################################################################
	# Given a set of integer screen coordinates (row, column) where:
	#	0 <= row < # of screen rows
	#	0 <= column < # of screen columns
	# maps the coordinates to the complex plane of the mandelbrot set
	# (real, imaginary) as doubles where:
	#	min_r <= real <= max_r
	#	min_i <= imaginary <= max_i
	# row => imaginary and column => real
	# Column is mapped proportionally (low mapped to low)
	# Row is mapped inverse proportionally (low mapped to high)
	#
	# Arguments:
	# $a0 = row
	# $a1 = column
	#
	# Returns (double floating point values):
	# $f0 = real part
	# $f2 = imaginary part
	#
	# Register Usage
	# $f4 = floating point conversion of $a0/$a1
	# $f8 = jump step calculation
	# $f10 = boundary we need (max_i or min_r)
	# $f12 = step_r
	# $f14 = step_i
	########################################################################
	# to convert one range of discrete (integer) numbers, to another range
	# of continuous (real) numbers, we first need a 'step size'.
	# Step_size = (max_discrete - min_discrete)/number_of_discrete_values
	# Then the max continuous number = min continuous number + step_size*# of discrete values
	# and for any discrete value which is the nth discrete value
	# nth real number = min real number + step_size*n
	
	#get the step sizes
	l.d	$f12, step_r
	l.d	$f14, step_i

	#convert inputs to doubles, real part
	mtc1	$a1, $f4
	cvt.d.w	$f4, $f4	#col
	
	# col
	l.d	$f10, min_r
	mul.d	$f8, $f4, $f12	# jump_r = col*step_r
	add.d	$f0, $f10, $f8	# x_0 = min_r + jump

	#convert inputs to doubles, imaginary part
	mtc1	$a0, $f4
	cvt.d.w	$f4, $f4	#row
	
	# row - inversely mapped so we minus from max instead of add from min
	l.d	$f10, max_i
	mul.d	$f8, $f4, $f14	# jump_i = row*step_i
	sub.d	$f2, $f10, $f8	# y_0 = max_i - jump

	
	jr	$ra
##############################################################################
#					START OF GLIM
##############################################################################
# The following copy of GLIM has been reduced to only those functions relevant
# to this assigment.
######################
#Author: Austin Crapo
#Date: June 2017
#Version: 2017.6.30
#
#
# Does not support being run in a tab; Requires a separate window.
#
# Currently printing to negative values does not print. Printing to
# offscreen pixels in the positive directions prints to last pixel
# available on the screen in that direction.
######################
.data
.align 2
clearScreenCmd:
	.byte 0x1b, 0x5b, 0x32, 0x4a, 0x00
.text
clearScreen:
	########################################################################
	# Uses xfce4-terminal escape sequence to clear the screen
	#
	# Register Usage
	# Overwrites $v0 and $a0 during operation
	########################################################################
	li	$v0, 4
	la	$a0, clearScreenCmd
	syscall
	
	jr	$ra

.data
setCstring:
	.byte 0x1b, 0x5b, 0x30, 0x30, 0x30, 0x3b, 0x30, 0x30, 0x30, 0x48, 0x00
.text
setCursor:
	########################################################################
	#Moves the cursor to the specified location on the screen. Max location
	# is 3 digits for row number, and 3 digits for column number. (row, col)
	#
	# $a0 = row number to move to
	# $a1 = col number to move to
	#
	# Register Usage
	# Overwrites $v0 and $a0 during operation
	########################################################################
	# Stack Adjustments
	addi	$sp, $sp, -4		# Adjust the stack to save $fp
	sw	$fp, 0($sp)		# Save $fp
	add	$fp, $zero, $sp		# $fp <= $sp
	addi	$sp, $sp, -12		# Adjust stack to save variables
	sw	$ra, -4($fp)		# Save $ra
	#skip $s0, this could be cleaned up
	sw	$s1, -8($fp)		
	sw	$s2, -12($fp)		
	
	#The control sequence we need is "\x1b[$a1;$a2H" where "\x1b"
	#is xfce4-terminal's method of passing the hex value for the ESC key.
	#This moves the cursor to the position, where we can then print.
	
	#The command is preset in memory, with triple zeros as placeholders
	#for the char coords. We translate the args to decimal chars and edit
	# the command string, then print
	
	move	$s1, $a0
	move	$s2, $a1
	
	li	$t0, 0x30	#'0' in ascii, we add according to the number
	#separate the three digits of the passed in number
	#1's = x%10
	#10's = x%100 - x%10
	#100's = x - x$100
	
	# NOTE: we add 1 to each coordinate because we want (0,0) to be the top
	# left corner of the screen, but most terminals define (1,1) as top left
	#ROW
	addi	$a0, $s1, 1
	la	$t2, setCstring
	jal	intToChar
	lb	$t0, 0($v0)
	sb	$t0, 4($t2)
	lb	$t0, 1($v0)
	sb	$t0, 3($t2)
	lb	$t0, 2($v0)
	sb	$t0, 2($t2)
	
	#COL
	addi	$a0, $s2, 1
	la	$t2, setCstring
	jal	intToChar
	lb	$t0, 0($v0)
	sb	$t0, 8($t2)
	lb	$t0, 1($v0)
	sb	$t0, 7($t2)
	lb	$t0, 2($v0)
	sb	$t0, 6($t2)

	#move the cursor
	li	$v0, 4
	la	$a0, setCstring
	syscall
	
	#Stack Restore
	lw	$ra, -4($fp)
	lw	$s1, -8($fp)
	lw	$s2, -12($fp)
	addi	$sp, $sp, 12
	lw	$fp, 0($sp)
	addi	$sp, $sp, 4
	
	jr	$ra

.text
printString:
	########################################################################
	# Prints the specified null-terminated string started at the
	# specified location to the string and then continuing until
	# the end of the string, according to the printing preferences of your
	# terminal (standard terminals print left to right, top to bottom).
	# Is not screen aware, passing paramaters that would print a character
	# off screen have undefined effects on your terminal window. For most
	# terminals the cursor will wrap around to the next row and continue
	# printing. If you have hit the bottom of the terminal window,
	# the xfce4-terminal window default behavior is to scroll the window 
	# down. This can offset your screen without you knowing and is 
	# dangerous since it is undetectable. The most likely useage of this
	# function is to print characters. The reason that it is a string it
	# prints is to support the printing of escape character sequences
	# around the character so that fancy effects are supported. Some other
	# terminals may treat the boundaries of the terminal window different,
	# for example some may not wrap or scroll. It is up to the user to
	# test their terminal window for its default behaviour.
	# Is built for xfce4-terminal.
	# Position (0, 0) is defined as the top left of the terminal.
	#
	# $a0 = address of string to print
	# $a1 = integer value 0-999, row to print to (y position)
	# $a2 = integer value 0-999, col to print to (x position)
	#
	# Register Usage
	# $t0 - $t3, $t7-$t9 = temp storage of bytes and values
	########################################################################
	# Stack Adjustments
	addi	$sp, $sp, -4		# Adjust the stack to save $fp
	sw	$fp, 0($sp)		# Save $fp
	add	$fp, $zero, $sp		# $fp <= $sp
	addi	$sp, $sp, -8		# Adjust stack to save variables
	sw	$ra, -4($fp)		# Save $ra
	sw	$s0, -8($fp)		# Save $s0
	
	move	$s0, $a0
	
	move	$a0, $a1
	move	$a1, $a2
	jal	setCursor
	
	#print the char
	li	$v0, 4
	move	$a0, $s0
	syscall
	
	#Stack Restore
	lw	$ra, -4($fp)
	lw	$s0, -8($fp)
	addi	$sp, $sp, 8
	lw	$fp, 0($sp)
	addi	$sp, $sp, 4
	
	jr	$ra


.data
.align 2
intToCharSpace:
	.space	4	#storing 4 bytes, only using 3, because of spacing.
.text
intToChar:
	########################################################################
	# Given an int x where 0 <= x <= 999, converts the integer into 3 bytes,
	# which are the character representation of the int. If the integer
	# requires larger than 3 chars to represent, only the 3 least 
	# significant digits will be converted.
	#
	# $a0 = integer to convert
	#
	# Return Values:
	# $v0 = address of the bytes, in the following order, 1's, 10's, 100's
	#
	# Register Usage
	# $t0-$t9 = temporary value storage
	########################################################################
	li	$t0, 0x30	#'0' in ascii, we add according to the number
	#separate the three digits of the passed in number
	#1's = x%10
	#10's = x%100 - x%10
	#100's = x - x$100
	la	$v0, intToCharSpace
	#ones
	li	$t1, 10		
	div	$a0, $t1
	mfhi	$t7			#x%10
	add	$t1, $t0, $t7	#byte = 0x30 + x%10
	sb	$t1, 0($v0)
	#tens
	li	$t1, 100		
	div	$a0, $t1
	mfhi	$t8			#x%100
	sub	$t1, $t8, $t7	#byte = 0x30 + (x%100 - x%10)/10
	li	$t3, 10
	div	$t1, $t3
	mflo	$t1
	add	$t1, $t0, $t1	
	sb	$t1, 1($v0)
	#100s
	li	$t1, 1000		
	div	$a0, $t1
	mfhi	$t9			#x%1000
	sub	$t1, $t9, $t8	#byte = 0x30 + (x%1000 - x%100)/100
	li	$t3, 100
	div	$t1, $t3
	mflo	$t1
	add	$t1, $t0, $t1	
	sb	$t1, 2($v0)
	
	jr	$ra
	
.data
.align 2
setFGorBG:
	.byte 0x1b, 0x5b, 0x34, 0x38, 0x3b, 0x35, 0x3b, 0x30, 0x30, 0x30, 0x6d, 0x00
.text
setColor:
	########################################################################
	# Prints the escape sequence that sets the color of the text to the
	# color specified.
	# 
	# xfce4-terminal supports the 256 color lookup table assignment, 
	# see the index for a list of color codes.
	#
	#
	# $a0 = color code (see index)
	# $a1 = 0 if setting background, 1 if setting foreground
	#
	# Register Usage
	# $s0 = temporary argument storage accross calls
	# $s1 = temporary argument storage accross calls
	########################################################################
	# Stack Adjustments
	addi	$sp, $sp, -4		
	sw	$fp, 0($sp)		
	add	$fp, $zero, $sp		
	addi	$sp, $sp, -12		
	sw	$ra, -4($fp)		
	sw	$s0, -8($fp)		
	sw	$s1, -12($fp)		
	
	move	$s0, $a0
	move	$s1, $a1
	
	jal	intToChar		#get the digits of the color code to print
	
	move	$a0, $s0
	move	$a1, $s1
	
	la	$t0, setFGorBG
	lb	$t1, 0($v0)		#alter the string to print
	sb	$t1, 9($t0)
	lb	$t1, 1($v0)
	sb	$t1, 8($t0)
	lb	$t1, 2($v0)
	sb	$t1, 7($t0)
	
	beq	$a1, $zero, sCsetBG	#set the code to print FG or BG
		#setting FG
		li	$t1, 0x33
		j	sCset
	sCsetBG:
		li	$t1, 0x34
	sCset:
		sb	$t1, 2($t0)
	
	li	$v0, 4
	move	$a0, $t0
	syscall
		
	#Stack Restore
	lw	$ra, -4($fp)
	lw	$s0, -8($fp)
	lw	$s1, -12($fp)
	addi	$sp, $sp, 12
	lw	$fp, 0($sp)
	addi	$sp, $sp, 4
	
	jr	$ra

.data
.align 2
rSstring:
	.byte 0x1b, 0x5b, 0x30, 0x6d, 0x00
.text
restoreSettings:
	########################################################################
	# Prints the escape sequence that restores all default color settings to
	# the terminal
	#
	# Register Usage
	# NA
	########################################################################
	la	$a0, rSstring
	li	$v0, 4
	syscall
	
	jr	$ra

.text
startGLIM:
	########################################################################
	# Sets up the display in order to provide
	# a stable environment. Call endGLIM when program is finished to return
	# to as many defaults and stable settings as possible.
	# Unfortunately screen size changes are not code-reversible, so endGLIM
	# will only return the screen to the hardcoded value of 24x80.
	#
	#
	# $a0 = number of rows to set the screen to
	# $a1 = number of cols to set the screen to
	#
	# Register Usage
	# NA
	########################################################################
	# Stack Adjustments
	addi	$sp, $sp, -4		
	sw	$fp, 0($sp)		
	add	$fp, $zero, $sp		
	addi	$sp, $sp, -4		
	sw	$ra, -4($fp)
	
	jal	setDisplaySize
	jal	restoreSettings
	jal	clearScreen
	
	jal	hideCursor
	
	#Stack Restore
	lw	$ra, -4($fp)
	addi	$sp, $sp, 4
	lw	$fp, 0($sp)
	addi	$sp, $sp, 4
	
	jr	$ra
	

.text
endGLIM:
	########################################################################
	# Reverts to default as many settings as it can, meant to end a program
	# that was started with startGLIM. The default terminal window in
	# xfce4-terminal is 24x80, so this is the assumed default we want to
	# return to.
	#
	# Register Usage
	# NA
	########################################################################
	# Stack Adjustments
	addi	$sp, $sp, -4		
	sw	$fp, 0($sp)		
	add	$fp, $zero, $sp		
	addi	$sp, $sp, -4		
	sw	$ra, -4($fp)
	
	li	$a0, 24
	li	$a1, 80
	jal	setDisplaySize
	jal	restoreSettings
	
	jal	clearScreen
	
	jal	showCursor
	li	$a0, 0
	li	$a1, 0
	jal	setCursor
	
	#Stack Restore
	lw	$ra, -4($fp)
	addi	$sp, $sp, 4
	lw	$fp, 0($sp)
	addi	$sp, $sp, 4
	
	jr	$ra
	
.data
.align 2
hCstring:
	.byte 0x1b, 0x5b, 0x3f, 0x32, 0x35, 0x6c, 0x00
.text
hideCursor:
	########################################################################
	# Prints the escape sequence that hides the cursor
	#
	# Register Usage
	# NA
	########################################################################
	la	$a0, hCstring
	li	$v0, 4
	syscall
	
	jr	$ra

.data
.align 2
sCstring:
	.byte 0x1b, 0x5b, 0x3f, 0x32, 0x35, 0x68, 0x00
.text
showCursor:
	########################################################################
	#Prints the escape sequence that restores the cursor visibility
	#
	# Register Usage
	# NA
	########################################################################
	la	$a0, sCstring
	li	$v0, 4
	syscall
	
	jr	$ra

.data
.align 2
sDSstring:
	.byte 0x1b, 0x5b, 0x38, 0x3b, 0x30, 0x30, 0x30, 0x3b, 0x30, 0x30, 0x30, 0x74 0x00
.text
setDisplaySize:
	########################################################################
	# Prints the escape sequence that changes the size of the display to 
	# match the parameters passed. The number of rows and cols are 
	# ints x and y s.t.:
	# 0<=x,y<=999
	#
	# $a0 = number of rows
	# $a1 = number of columns
	#
	# Register Usage
	# $s0 = temporary $a0 storage
	# $s1 = temporary $a1 storage
	########################################################################
	# Stack Adjustments
	addi	$sp, $sp, -4		
	sw	$fp, 0($sp)		
	add	$fp, $zero, $sp		
	addi	$sp, $sp, -12		
	sw	$ra, -4($fp)		
	sw	$s0, -8($fp)		
	sw	$s1, -12($fp)
	
	move	$s0, $a0
	move	$s1, $a1
	
	#rows
	jal	intToChar		#get the digits of the params to print
	
	la	$t0, sDSstring
	lb	$t1, 0($v0)		#alter the string to print
	sb	$t1, 6($t0)
	lb	$t1, 1($v0)
	sb	$t1, 5($t0)
	lb	$t1, 2($v0)
	sb	$t1, 4($t0)
	
	#cols
	move	$a0, $s1
	jal	intToChar		#get the digits of the params to print
	
	la	$t0, sDSstring
	lb	$t1, 0($v0)		#alter the string to print
	sb	$t1, 10($t0)
	lb	$t1, 1($v0)
	sb	$t1, 9($t0)
	lb	$t1, 2($v0)
	sb	$t1, 8($t0)
	
	li	$v0, 4
	move	$a0, $t0
	syscall
	
	#Stack Restore
	lw	$ra, -4($fp)
	lw	$s0, -8($fp)
	lw	$s1, -12($fp)
	addi	$sp, $sp, 12
	lw	$fp, 0($sp)
	addi	$sp, $sp, 4
	
	jr	$ra
##############################################################################
#					END OF GLIM
##############################################################################
.text


# Arguments:
# $f12
# $f14
# $f16
# $f18
# $a0
# $a1
set_size:
	la $t0 max_i		#get max_i address
	s.d $f12, 0($t0)	#store max_i
	la $t0 min_r		#get min_r address
	s.d $f18, 0($t0)	#store min_r
	sub.d $f4 $f12 $f14	#difference of $f12 and $f14
	mtc1 $a0, $f0		#move $a0 to $f0
	cvt.d.w $f6, $f0	#convert $a0 into floating point
	div.d $f4 $f4 $f6	#divide $f4 by $f5
	sub.d $f8 $f16 $f18	#difference of $f16 and $f18
	mtc1 $a1, $f2		#move $a1 to $f0
	cvt.d.w $f10, $f2	#convert $a1 into floating point
	div.d $f8 $f8 $f10	#divider $f5 by $a1 (Check if this is valid)
	la $t0 step_i		#get step_i address
	s.d $f4, 0($t0)		#stores step_i
	la $t0 step_r		#get step_r address
	s.d $f8, 0($t0)		#store step_r
	jr $ra

# Arguments:
# $a0
# x_0 - double
# y_0 - double
#
# Returns:
# $v0 - Boolean
# $v1 - # of iterations

calculate_escape:
	l.d $f4 x_0		#load x = x_0
	l.d $f6 y_0		#load y = y_0
	l.d $f12 x_0
	l.d $f14 y_0
	move $t0 $0		#iteration = 0
	move $t1 $a0		#maxiteration = $a0
	Loop:
		beq $t1 $t0 Finish	#if iteration=maxiteration gotoFinish
		mul.d $f8 $f4 $f4	#$f8 = $f4*$f4
		mul.d $f10 $f6 $f6	#$f10 = $f6*$f6
		add.d $f16 $f8 $f10	#$f16 = $f10 + $f8
		li.d $f18, 4.0		#$f18 = 4.0
		c.le.d $f16, $f18	#if $f16 < $f18, flag = true
		bc1f Exit		#if false Exit
		sub.d $f16 $f8 $f10	#$f16 = $f8 - $f10
		add.d $f16 $f16 $f12	#$f16 = $f16 + $f12
		mul.d $f6 $f6 $f4	#y = y*x
		add.d $f6 $f6 $f6	#y = 2y
		add.d $f6 $f6 $f14	#y = y+y_0
		add.d $f4 $f16 $f16	#x = 2$f16
		sub.d $f4 $f4 $f16	#x = x-$f16
		addi $t0 $t0 1		#iteration = iteration + 1
		j Loop			#jumpto Loop
	Exit:	
		addi $v0 $0 1		#$v0 = 1
		move $v1, $t0		#$v1 = iterations
		jr $ra
	Finish:
		add $v0 $0 $0		#v0 = 0
		move $v1, $t1		#v1 = maxiterations
		jr $ra

render:
	addi $sp $sp -24	#decrements stack pointer
	sw $s0 0($sp)		#stores $s0 in memory
	sw $s1 4($sp)		#stores $s1 in memory
	move $s0, $a0		#stores $a0 in $s0
	move $s1, $a1		#stores $a1 in $s1
	sw $s2 8($sp)		#stores $s2 in memory
	sw $s3 12($sp)		#stores $s3 in memory
	add $s2 $0 $0		#$s2 = row
	add $s3 $0 $0		#$s3 = column
	sw $s4 16($sp)		#stores $s4 in memory
	add $s4 $0 $a2		#$s4 = iterations
	sw $ra 20($sp)		#stores return address
	Loop1:
		bge $s2 $s0 End
		add $s3 $0 $0
		Loop2:
			bge $s3 $s1 End1
			move $a0, $s2		#$a0 = row
			move $a1, $s3		#$a1 = column
			jal map_coords		#jump to map_coords
			move $a0, $s4
			s.d $f0, x_0
			s.d $f2, y_0
			jal calculate_escape	#jump tp calculate_escape
			beq $v0 $0 inSet	#if has_escaped = 0 goto inSet
			la $t1 paletteSize
			lw $t1 0($t1)
			div $v1 $t1		#$v1/paletteSize
			mfhi $t2		#get remainder
			la $t1 colors		#get address colors
			add $t1 $t1 $t2
			lbu $a0 0($t1)
			#addi $a0 $0 196		#get colors
			add $a1 $0 $0		#set background
			jal setColor		#call function setColor
			la $t1 symbols		#get address symbol
			add $t2 $t2 $t2
			add $a0 $t2 $t1 	#get symbol
			move $a1 $s2		#$a1 = row
			move $a2 $s3		#$a2 = column
			jal printString		#call function printString
		Back:
			addi $s3 $s3 1
			j Loop2
		End1:
			addi $s2 $s2 1
			j Loop1
	End:
		lw $ra 20($sp)
		lw $s4 16($sp)
		lw $s3 12($sp)
		lw $s2 8($sp)
		lw $s1 4($sp)
		lw $s0 0($sp)
		addi $sp $sp 24
		jr $ra

	inSet:
		la $a0 inSetColor	#set inSetColor
		lb $a0 0($a0)
		#add $a0 $0 $0
		add $a1 $0 $0		#set background
		jal setColor		#call function setColor
		la $a0 inSetSymbol	#set inSetSymbol
		move $a1 $s2		#$a1 = row
		move $a2 $s3		#$a2 = column
		jal printString		#call function printString
		j Back			#go Back
