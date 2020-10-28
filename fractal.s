# The following format is required for all submissions in CMPUT 229
#
# The following copyright notice does not apply to this file
# It is included here because it should be included in all
# solutions submitted by students.
#
#----------------------------------------------------------------
#
# CMPUT 229 Student Submission License
# Version 1.0
# Copyright 2017 <student name>
#
# Redistribution is forbidden in all circumstances. Use of this software
# without explicit authorization from the author is prohibited.
#
# This software was produced as a solution for an assignment in the course
# CMPUT 229 - Computer Organization and Architecture I at the University of
# Alberta, Canada. This solution is confidential and remains confidential
# after it is submitted for grading.
#
# Copying any part of this solution without including this copyright notice
# is illegal.
#
# If any portion of this software is included in a solution submitted for
# grading at an educational institution, the submitter will be subject to
# the sanctions for plagiarism at that institution.
#
# If this software is found in any public website or public repository, the
# person finding it is kindly requested to immediately report, including
# the URL or other repository locating information, to the following email
# address:
#
#          cmput229@ualberta.ca
#
#---------------------------------------------------------------
# Assignment:           2
# Due Date:             October 10, 2017
# Name:                 William Wong
# Unix ID:              wwong1
# Lecture Section:      A1
# Instructor:           Jose Amaral
# Lab Section:          D09 (Friday 1400 - 1650)
# Teaching Assistant:   Unknown
#---------------------------------------------------------------

.text
#---------------------------------------------------------------
# The function calculates the step sizes for the tiles in both
# imaginary and real numbers, and stores them into memory along
# with the maximum imaginary and minimum real number. These
# numbers already have addresses.
#
# Inputs:
#
#	a0: number of rows in the screen
#	a1: number of columns in the screen
# f12: maximum imaginary value being rendered
# f14: minimum imaginary value being rendered
# f16: maximum real value being rendered
# f18: minimum real value being rendered
# max_i: memory address storing maximum imaginary value
# min_r: memory address storing minimum real value
# step_i: memory address storing step of imaginary values
# step_r: memory address storing step of real values
#
# Register Usage:
# t0: Holds the addresses of memory address
# f4: Holds the calculations of various floating point math
# f6: Holds the amount of rows in floating point
# f8: Holds the calculations of various floating point math
# f10: Holds the amount of columns in floating point
#
# Returns:
#	None - stores max_i,min_r,step_i and step_r into the memory.
#
#---------------------------------------------------------------

set_size:
	la $t0 max_i		#get max_i address
	s.d $f12, 0($t0)	#store max_i
	la $t0 min_r		#get min_r address
	s.d $f18, 0($t0)	#store min_r
	sub.d $f4 $f12 $f14	#difference of $f12 and $f14
	mtc1 $a0, $f6		#move $a0 to $f0
	cvt.d.w $f6, $f6	#convert $a0 into floating point
	div.d $f4 $f4 $f6	#divide $f4 by $f5
	sub.d $f8 $f16 $f18	#difference of $f16 and $f18
	mtc1 $a1, $f10		#move $a1 to $f0
	cvt.d.w $f10, $f10	#convert $a1 into floating point
	div.d $f8 $f8 $f10	#divider $f5 by $a1 (Check if this is valid)
	la $t0 step_i		#get step_i address
	s.d $f4, 0($t0)		#stores step_i
	la $t0 step_r		#get step_r address
	s.d $f8, 0($t0)		#store step_r
	jr $ra
#---------------------------------------------------------------
	# The function calculates whether a pair of imaginary and real
	# values are part of the mandelbrot set. It uses a recursion to
	# see how many iterations it takes for the pair to "escape" the
	# following condition:
	#	i*i + r*r < 4
	# If it is in the set, then the function returns that it does
	# not escape and takes the maximum number of iterations.
	# However, if it does escape the condition, the function
	# then returns that it did escape, and how many iterations it
	# took to escape.
	#
	# Inputs:
	#
	#	a0: The maximum number of iterations before it is
	#     considered in the Mandelbrot set.
	# x_0: Memory address of the imaginary number in the
	#     complex number.
	# y_0: Memory address of the real number in the complex
	#     number.
	#
	# Register Usage:
	# t0: Holds the addresses of memory address
	# f4: Holds the calculations of various floating point math
	# f6: Holds the amount of rows in floating point
	# f8: Holds the calculations of various floating point math
	# f10: Holds the amount of columns in floating point
	#
	# Returns:
	#	v0: Returns 0 if it did not escape, 1 if it did escape the
	# condition.
	# v1: If it did escape, returns the amount of iterations it
	# took to escape; if it did not escape, then it returns the
	#
	#---------------------------------------------------------------
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
	c.lt.d $f16, $f18	#if $f16 < $f18, flag = true
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
	addi $sp $sp -20	#decrements stack pointer
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
Loop1:
	beq $s2 $s0 End
	add $s3 $0 $0
Loop2:
	beq $s3 $s1 End1
	move $a0, $s2		#$a0 = row
	move $a1, $s3		#$a1 = column
	jal map_coords		#jump to map_coords
	move $a0, $s4
	s.d $f0, x_0
	s.d $f2, y_0
	jal calculate_escape	#jump tp calculate_escape
	beq $v0 $0 inSet	#if has_escaped = 0 goto inSet
	la $t1 paletteSize
	div $v1 $t1		#$v1/paletteSize
	mfhi $t2		#get remainder
	la $t1 colors		#get address colors
	add $t1 $t1 $t2
	lbu $a0 0($t1)
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
	lw $s4 16($sp)
	lw $s3 12($sp)
	lw $s2 8($sp)
	lw $s1 4($sp)
	lw $s0 0($sp)
	addi $sp $sp 20

inSet:
	la $a0 inSetColor	#set inSetColor
	lb $a0 0($a0)
	add $a1 $0 $0		#set background
	jal setColor		#call function setColor
	la $a0 inSetSymbol	#set inSetSymbol
	move $a1 $s2		#$a1 = row
	move $a2 $s3		#$a2 = column
	jal printString		#call function printString
	j Back			#go Back
