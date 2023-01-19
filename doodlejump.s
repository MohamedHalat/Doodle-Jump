#####################################################################
#
# CSCB58 Fall 2020 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Mohamed Halat
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 512
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestone is reached in this submission?
# - Milestone 5
#
# Which approved additional features have been implemented?
# 1. 5: Two doodlers (second one moves with a,d and does not move the screen)
# 2. 5; Fancier graphics (Better start, pause screen, death screen and higher pixel density)
# 4. 5: More platform types (A moving platform)
# 3. 4: Dynamic increase in Difficulty (Done by decreasing the clockSpeed, platform movement)
# 5. 4: Printing Score
#
# Link to video demonstration for final submission:(Started uploading at 3:50pm)
# - https://youtu.be/Z83_FUEKpJk
#
# Any additional information that the TA needs to know:
# - Click s to start/restart, p to pause/resume and q to quit on start/pause screen
# - I run on mac and apparently it runs slower, if you have to, change clockSpeed const
# - I wrote all of the code in VSCode and the formating is fine there, for some reason mars reformats
#####################################################################
.data
	# Display Addresss
	displayAddress:	.word	0x10008000
	# Colours
    backgroundColor: .word 0xf6efea
    doodleColor: .word 0xbfb60b
    doodleColor2: .word 0x800000
    doodleFeetColor: .word 0x8B4513
    blockColor: .word 0x7eaf39
    grey: .word 0x808080
    White: .word 0xffffff
	# Icons/Printed text (RIP must be defined in this order, one after the other)
	BigR: .word 19, 45, 19, 46, 19, 47, 18, 47
	BigI: .word 16, 45, 16, 46, 16, 48
	BigP: .word 14, 44, 14, 43,14, 45, 14, 46, 14, 47, 13, 47, 12, 47, 12, 45, 12, 46, 13, 45, 0, 0
	pauseLogo: .word 17, 30, 17, 29, 17, 31, 17, 32,  15, 30, 15, 29, 15, 31, 15, 32, 0, 0
	playIcon: .word 17, 33, 17, 30, 17, 29, 17, 31, 17, 32,  16, 32, 16, 30, 16, 31,15, 31, 0, 0
	# Blocks
	blocks: .space 56
	blocksSize: .word 56
	verticalScroll: .word 0
	blockDisplacement: .word 0
	maxBlockDisplacement: .word 8
	# Doodler 1
	doodle: .word 17, 4
	isDead: .word 0
	moveLeft: .word 0
	moveRight: .word 0
	jumpTime: .word 0
	fallSpeed: .word -1
	noseDirection: .word -8
	#Doodler 2
	doodle2: .word 17, 8
	fallSpeed2: .word -1
	moveLeft2: .word 0
	moveRight2: .word 0
	jumpTime2: .word 0
	noseDirection2: .word -8
	# Screen resolution for calculating offset
	resolution: .word 8192
	rowHeight: .word 128
	colWidth: .word 4
	# Constants
	blockSpawnHeight: .word 65
	maxJumpTime: .word 18
	maxJumpHeight: .word 40
	# Score
	newLine: .ascii "\n"
	scoreText: .ascii "\nYour score will print here on pause:\n"
	currentHeight: .word 4
	score: .word 0
	# Difficulty
	clockSpeed: .word 60
	maxDifficultyTick: .word 300
	difficultyTick: .word 0
.text

# Start Game
j initalStartGame

# Main Game loop
main:
	# Start Game
	jal resetGame
	jal drawBackground
	jal drawDoodler
	jal generateStartingBlocks
	jal drawPlatforms

	# Continue Game loop
	MAINLOOP:
		# Reset player movement
		sw $zero, moveLeft
		sw $zero, moveRight
		sw $zero, moveLeft2
		sw $zero, moveRight2
		# Get Keyboard input
		lw $t0, 0xffff0000
		bne $t0, 1, MainDraw
		jal getKeyBoardInput
		# Calculate movement and draw screen
		MainDraw:
			jal calculateJump
			jal calculateJump2
			jal makeJump
			jal makeJump2
			jal drawPlatforms
			jal drawDoodler2
			jal drawDoodler
		# Sleep for clockSpeed
		li $v0, 32
		lw $a0, clockSpeed
		syscall
		# Calculate Difficulty
		lw $t1, difficultyTick
		lw $t0, maxDifficultyTick
		beq $t1, $t0, increaseDifficulty #if difficultyTick is max, decrease sleep
		la $t2, difficultyTick
		addi $t1, $t1, 1
		sw $t1, 0($t2)
		j MAINLOOP
	# Exit Game
	Exit:
		li $v0, 10 # terminate the program gracefully
		syscall

# Increase difficulty by shortening clockSpeed
increaseDifficulty:
	lw $t3, clockSpeed
	beq $t3, $zero, MAINLOOP #Limit min clockSpeed to 0
	la $t4, clockSpeed
	addi $t3, $t3, -1
	sw $t3, 0($t4)
	la $t2, difficultyTick
	sw $zero, 0($t2)
	j MAINLOOP

# Draw player Score
drawPoints:
	move $s0, $ra
	lw $t3, grey
	# Calculate Score based off of player height
	li $v0, 1
	lw $a0, currentHeight
	syscall
	# New Line
	li $v0, 4
	la $a0, newLine
	syscall
	# Print score on screen
	# li $a0, 8
	# li $a1, 62
	# jal calculateDisplayOffset
	# # jal drawOne
	# addi $v0, $v0, -8
	# jal drawTwo
	jr $s0

# Draw 1 on screen
# v0 = screen print position
drawOne:
	lw $t3, grey
	sw $t3, 0($v0)
	sw $t3, 128($v0)
	sw $t3, 256($v0)
	jr $ra
# Draw 2 on screen
# v0 = screen print position
drawTwo:
	lw $t3, grey
	sw $t3, 0($v0)
	sw $t3, -124($v0)
	sw $t3, 8($v0)
	sw $t3, 136($v0)
	sw $t3, 260($v0)
	sw $t3, 384($v0)
	jr $ra

# Draw text rip on screen when dead
drawRIP:
	move $s0, $ra
	la $t2, BigR
	lw $t3, grey
	# Loop through the registers for BigR - BigP and print it to screen
	RipLoop:
		lw $a0, 0($t2) #Load x
		lw $a1, 4($t2) #Load y
		beq $zero, $a0, doneRip #If the position is 0,0, it means were done printing
		jal calculateDisplayOffset
		sw $t3, 0($v0)	#draw pixel
		addi $t2, $t2, 8 #Next pixel
		j RipLoop
	doneRip:
		jr $s0

# Draw pause icon
drawPauseIcon:
	move $s0, $ra
	la $t2, pauseLogo
	lw $t3, grey
	# Loop through the register for pauseLogo and print it to screen
	pauseIconLoop:
		lw $a0, 0($t2) #load x
		lw $a1, 4($t2) #load y
		beq $zero, $a0, donePauseIconLoop #If the position is 0,0, it means were done printing
		jal calculateDisplayOffset
		sw $t3, 0($v0) #draw pixel
		addi $t2, $t2, 8 #Next pixel
		j pauseIconLoop
	donePauseIconLoop:
		jr $s0

# Draw pause icon
drawStartIcon:
	move $s0, $ra
	la $t2, playIcon
	lw $t3, grey
	# Loop through the register for playIcon and print it to screen
	startIconLoop:
		lw $a0, 0($t2) #load x
		lw $a1, 4($t2) #load y
		beq $zero, $a0, donestartIconLoop #If the position is 0,0, it means were done printing
		jal calculateDisplayOffset
		sw $t3, 0($v0) #draw pixel
		addi $t2, $t2, 8 #Next pixel
		j startIconLoop
	donestartIconLoop:
		jr $s0

# Set player to dead and draw the dead screen (pause game)
gameOver:
	jal drawRIP
	li $t0, 1
	sw $t0, isDead
	jal drawPoints
	j pause

# Reset all positions and constants
resetGame:
	move $s1, $ra
	# Print score in Mars io
	li $v0, 4
	la $a0, scoreText
	syscall
	# Reset Doodler 1
	la $t0, doodle
	li $t1, 17
	sw $t1, 0($t0)
	li $t1, 4
	sw $t1, 4($t0)
	# Reset Doodler 2
	la $t0, doodle2
	li $t1, 17
	sw $t1, 0($t0)
	li $t1, 8
	sw $t1, 4($t0)
	# Reset both fallSpeed
	la $t0, fallSpeed
	li $t1, -1
	sw $t1, 0($t0)
	la $t0, fallSpeed2
	li $t1, -1
	sw $t1, 0($t0)
	# Reset both jumpTime
	la $t0, jumpTime
	sw $zero, 0($t0)
	la $t0, jumpTime2
	sw $zero, 0($t0)
	# Reset verticalScroll
	la $t0, verticalScroll
	sw $zero, 0($t0)
	# Make doodler 1 alive
	sw $zero, isDead
	jr $s1


# Checks to see if jump time has reached max jump time and makes the player fall
# by setting fall speed to -1
calculateJump:
	move $t9, $ra
	li $t1, -1
	lw $t2, fallSpeed
	lw $t3, verticalScroll
	beq $t3,1, makeThePlatformsFall #if verticalScroll is true, make platform fall
	beq $t1, $t2, doneCalculateJump #Make player fall
	# Make platform fall
	makeThePlatformsFall:
		lw $t3, jumpTime
		lw $t4, maxJumpTime
		beq $t4, $t3 startFall #Stop platform fall if at max jump
		addi $t3, $t3, 1
		sw $t3, jumpTime
		j doneCalculateJump
	#Make player fall
	startFall:
		sw $t1, fallSpeed
		sw $zero, jumpTime
		sw $zero, verticalScroll
	# Done
	doneCalculateJump:
		jr $t9

# Checks to see if jump time 2 has reached max jump time and makes the player 2 fall
# by setting fall speed 2 to -1
calculateJump2:
	move $t9, $ra
	li $t1, -1
	lw $t2, fallSpeed2
	beq $t1, $t2, doneCalculateJump2

	lw $t3, jumpTime2
	lw $t4, maxJumpTime

	beq $t4, $t3 startFall2

	addi $t3, $t3, 1
	sw $t3, jumpTime2
	j doneCalculateJump2

	#Make player2 fall
	startFall2:
		sw $t1, fallSpeed2
		sw $zero, jumpTime2
	# Done
	doneCalculateJump2:
		jr $t9

# Apply gravity to doodler 1
gravityIsABitch:
	move $t3, $ra

	lw $t2, jumpTime
	lw $t7, fallSpeed
	la $t8, doodle
	lw $t9, 4($t8) # y
	lw $t6, maxJumpHeight
	ble $t6, $t9, moveBlockVertical #If y = max height, move the blocks
	# Move doodler vertically
	moveDoodlerVertical:
		add $t9, $t9, $t7 # Add fallSpeed to y
		sw $t9, 4($t8) #save new y
		#Save currentHeight with fall speed
		bgt $zero, $t7, moveDoodlerVerticalReturn
		lw $t9, currentHeight
		add $t9, $t9, $t7
		sw $t9, currentHeight
		moveDoodlerVerticalReturn:
		jr $t3
	# Move blocks vertically
	moveBlockVertical:
		beq $zero, $t2, moveDoodlerVertical #if jumpTime is zero, move doodler
		sw $zero, fallSpeed #reset fallSpeed
		li $t1, -1
		sw $t1, verticalScroll #Setup verticalScroll
		jr $t3

# Apply gravity to doodler 2
gravityIsABitch2:
	lw $t2, jumpTime2
	lw $t7, fallSpeed2
	la $t8, doodle2
	lw $t9, 4($t8) # y
	# New Y
	add $t9, $t9, $t7 # Add fallSpeed to y
	sw $t9, 4($t8) #save new y
	# return
	jr $ra


# If the doodler makes contact with any of the blocks, make him jump
# by setting fall speed to 1
makeJump:
	move $t0, $ra
	# Get Doodler pos
	la $t9, doodle
	lw $a0, 0($t9) # x
	lw $a1, 4($t9) # y
	jal calculateDisplayOffset
	move $t6, $v0 #Doodler Display offset
	# Get Block pos
	la $t1, blocks
	lw $t2, blocksSize
	add $t3, $t1, $t2
	j jumpBlockLoop
	resetVerticalScroll:
		sw $zero, verticalScroll
	#  Loop through all blocks to check collisions
	jumpBlockLoop:
		lw $a0, 0($t1) # x
		lw $a1, 4($t1) # y
		jal calculateDisplayOffset
		move $t5, $v0 #Block Display offset
		# Check if pos it less than block edge 2
		addi, $t5, $t5, -16
		ble $t5, $t6, checkBlockEdge
		j nextBlockLoop
		# Check if pos is greater than edge
		checkBlockEdge:
			addi, $t5, $t5, 32
			bge $t5, $t6, doneJump
		# Next Block Loop
		nextBlockLoop:
			beq $t1, $t3, doneDontJump
			addi $t1, $t1, 8
		j jumpBlockLoop
	# Setup jump by setting fallSpeed to positive
	doneJump:
		li $t1, 1
		sw $t1, fallSpeed
	# Return
	doneDontJump:
		jr $t0

# If the doodler2 makes contact with any of the blocks, make him jump
# by setting fall speed to 1
makeJump2:
	move $t0, $ra
	# Get Doodler2 pos
	la $t9, doodle2
	lw $a0, 0($t9) # x
	lw $a1, 4($t9) # y
	jal calculateDisplayOffset
	move $t6, $v0 #Doodler Display offset
	# Get Block pos
	la $t1, blocks
	lw $t2, blocksSize
	add $t3, $t1, $t2
	j jumpBlockLoop2
	#  Loop through all blocks to check collisions
	jumpBlockLoop2:
		lw $a0, 0($t1) # x
		lw $a1, 4($t1) # y
		jal calculateDisplayOffset
		move $t5, $v0 #Block Display offset
		# Check if pos it less than block edge 2
		addi, $t5, $t5, -16
		ble $t5, $t6, checkBlockEdge2
		j nextBlockLoop2
		# Check if pos is greater than edge
		checkBlockEdge2:
			addi, $t5, $t5, 32
			bge $t5, $t6, doneJump2
		# Next Block Loop
		nextBlockLoop2:
			beq $t1, $t3, doneDontJump2
			addi $t1, $t1, 8
		j jumpBlockLoop2
	# Setup jump by setting fallSpeed to positive
	doneJump2:
		li $t1, 1
		sw $t1, fallSpeed2
	# Return
	doneDontJump2:
		jr $t0

# Start/restart the game
initalStartGame:
	jal drawBackground
	jal generateStartingBlocks
	jal drawPlatforms
	# Add start screen drawing loop
	startGameLoop:
		li $t0, -1
		la $t1, verticalScroll
		sw $t0, 0($t1)
		# Draw icon a nd platforms
		jal drawPlatforms
		jal drawStartIcon
		# Check if key is pressed
		lw $t0, 0xffff0000
		beq $t0, 1, startGame
		# Sleep
		li $v0, 32
		li $a0, 60
		syscall
		# reloop
		j startGameLoop
	# If s or q are not pressed loop through start
	startGame:
		lw $t2, 0xffff0004
		beq $t2, 0x73, main
		beq $t2, 0x71, Exit
		j startGameLoop

pauseGame:
	jal drawPoints
	j pause

# Pause the game loop
pause:
	jal drawPauseIcon #Draw icon
	lw $t0, 0xffff0000
	beq $t0, 1, checkResume #Check to see if game resumes on button click
	# Sleep
	li $v0, 32
	li $a0, 50
	syscall
	# Loop
	j pause
#Check to see if game resumes on button click
checkResume:
	lw $t2, 0xffff0004
	beq $t2, 0x73, initalStartGame
	beq $t2, 0x71, Exit
	lw $t1, isDead
	bne $zero, $t1, pause
	beq $t2, 0x70, resume
	j pause
# Resume game
resume:
	jal drawBackground
	jal drawDoodler
	jal drawPlatforms
	j MAINLOOP

# All key input states
getKeyBoardInput:
	move $t4, $ra
	lw $t2, 0xffff0004
	beq $t2, 0x73, main
	beq $t2, 0x70, pauseGame
	beq $t2, 0x71, Exit
	beq $t2, 0x6A, goLeft
	beq $t2, 0x6B, goRight
	beq $t2, 0x61, goLeft2
	beq $t2, 0x64, goRight2
	jr $t4

# Move doodler1 left
goLeft:
	lw $t9, moveLeft
	li $t8 1
	sw $t8, moveLeft
	jr $ra

# Move doodler1 right
goRight:
	lw $t9, moveRight
	li $t8 1
	sw $t8, moveRight
	jr $ra

# Move doodler2 left
goLeft2:
	lw $t9, moveLeft2
	li $t8 1
	sw $t8, moveLeft2
	jr $ra

# Move doodler2 left
goRight2:
	lw $t9, moveRight2
	li $t8 1
	sw $t8, moveRight2
	jr $ra

# Draw background with backgroundColor
drawBackground:
	lw $t0, displayAddress
	lw $t1, backgroundColor
	lw $t4, resolution
	# Loop through entire screen
    LOOPINIT:
	    addi    $t2, $t0, 0
        add    $t3, $t0, $t4

	WHILE:
	    sw $t1, 0($t2)
	    addi $t2, $t2, 4
        bne	$t2, $t3, WHILE
		jr $ra

# Draw doodler
drawDoodler:
	move $s0, $ra
	la $t2, doodle

	lw $a0, 0($t2) # x
	lw $a1, 4($t2) # y
	jal calculateDisplayOffset
	# Clear old doodler with background colour
	lw $t1, backgroundColor
	sw $t1, -388($v0)
	sw $t1, -384($v0)
	sw $t1, -380($v0)
	sw $t1, -260($v0)
	sw $t1, -256($v0)
	sw $t1, -252($v0)
	sw $t1, -132($v0)
	sw $t1, -128($v0)
	sw $t1, -124($v0)
	sw $t1, -4($v0)
	sw $t1, 4($v0)
	lw $t3, noseDirection
	addi $t3, $t3, -256
	add $v0, $v0, $t3
	sw $t1, 0($v0)

	# Move doodler to new position
	lw $t1, moveLeft
	bne $t1, $zero, doodlerGoLeft
	lw $t1, moveRight
	bne $t1, $zero, doodlerGoRight
	j drawNextPost
	doodlerGoLeft:
		jal moveDoodlerLeft
		j drawNextPost
	doodlerGoRight:
		jal moveDoodlerRight
		j drawNextPost

	# Draw new doodler position
	drawNextPost:
	jal gravityIsABitch

	# check to see if doodler fell off the screen
	la $t2, doodle
	lw $a0, 0($t2) # x
	lw $a1, 4($t2) # y
	li $t2, -5
	bge $t2, $a1, gameOver # game over if y < -5
	jal calculateDisplayOffset

	# Draw new doodler
	lw $t1, doodleColor
	lw $t6, doodleFeetColor

	sw $t1, -388($v0)
	sw $t1, -384($v0)
	sw $t1, -380($v0)

	sw $t1, -260($v0)
	sw $t1, -256($v0)
	sw $t1, -252($v0)

	sw $t1, -132($v0)
	sw $t1, -128($v0)
	sw $t1, -124($v0)

	sw $t6, -4($v0)
	sw $t6, 4($v0)

	lw $t3, noseDirection

	addi $t3, $t3, -256
	add $v0, $v0, $t3

	sw $t1, 0($v0)

	jr $s0


#Calculate display offset given x and y as a0, a1
calculateDisplayOffset:
	lw $t8, rowHeight
	lw $t9, resolution
	lw $v0, displayAddress

	mult $a1, $t8
	mflo $a1

	lw $t8, colWidth
	mult $a0, $t8
	mflo $a0

	sub $v0, $v0, $a0
	sub $v0, $v0, $a1

	add $v0, $v0, $t9
	jr $ra

#Generate the random blocks at the start of the game
# At the start blocks have defined y positions
generateStartingBlocks:
	move $s0, $ra
	la $t0, blocks

	li $t1, 18
	li $t2, 0
	sw $t1, 0($t0)
	sw $t2, 4($t0)
	addi $t0, $t0, 8

	jal randomX
	sw $v0, 0($t0)
	li $t2, 14
	sw $t2, 4($t0)
	addi $t0, $t0, 8

	jal randomX
	sw $v0, 0($t0)
	li $t2, 21
	sw $t2, 4($t0)
	addi $t0, $t0, 8

	jal randomX
	sw $v0, 0($t0)
	li $t2, 28
	sw $t2, 4($t0)
	addi $t0, $t0, 8

	jal randomX
	sw $v0, 0($t0)
	li $t2, 35
	sw $t2, 4($t0)
	addi $t0, $t0, 8

	jal randomX
	sw $v0, 0($t0)
	li $t2, 40
	sw $t2, 4($t0)
	addi $t0, $t0, 8

	jal randomX
	sw $v0, 0($t0)
	li $t2, 57
	sw $t2, 4($t0)
	addi $t0, $t0, 8

	jr $s0

# Draw all blocks
drawPlatforms:
	move $k0, $ra
	lw $t3, blockColor

	la $t0, blocks
	lw $t1, blocksSize
	add $t2, $t0, $t1
	li $t4, -8
	add $t5, $t2, $t4
	lw $t1, verticalScroll

	blocksLoop:
		beq $t0, $t2, donePrinting
		lw $t4, backgroundColor

		lw $t6, 0($t0) #X
        lw $t7, 4($t0) #Y

		beq $t7, -1, redrawPlatform

		continueBlockLoop:
		lw $a0, 0($t0) #X
        lw $a1, 4($t0) #Y
		jal calculateDisplayOffset

	    sw $t4, -12($v0)
	    sw $t4, -8($v0)
	    sw $t4, -4($v0)
	    sw $t4, 0($v0)
	    sw $t4, 4($v0)
	    sw $t4, 8($v0)
	    sw $t4, 12($v0)

		lw $t4, 4($t0)
		add $t4, $t1, $t4
		sw $t4, 4($t0)

        lw $a0, 0($t0) #X
        lw $a1, 4($t0) #Y
		beq $t0,$t5, moveBlock
		drawNewBlock:
		jal calculateDisplayOffset

	    sw $t3, -12($v0)
	    sw $t3, -8($v0)
	    sw $t3, -4($v0)
	    sw $t3, 0($v0)
	    sw $t3, 4($v0)
	    sw $t3, 8($v0)
	    sw $t3, 12($v0)

            addi $t0, $t0, 8
            j blocksLoop
        donePrinting:
            jr $k0


moveBlock:
	addi $a0, $a0, -1
	sw $a0, 0($t0)
	j drawNewBlock

# Move the doodler left and set nose position
moveDoodlerLeft:
	la $t8, doodle
	li $t2, 1

	lw $t9, 0($t8) # x
	addi $t9, $t9, 1
	sw $t9, 0($t8) #

	li $t2, -8
	sw $t2 noseDirection
	jr $ra

# Move doodler right and set nose position
moveDoodlerRight:
	la $t8, doodle

	lw $t9, 0($t8) # x
	addi $t9, $t9, -1
	sw $t9, 0($t8) #

	li $t2, 8
	sw $t2 noseDirection
	jr $ra

# Move the doodler left and set nose position
moveDoodlerLeft2:
	la $t8, doodle2
	li $t2, 1

	lw $t9, 0($t8) # x
	addi $t9, $t9, 1
	sw $t9, 0($t8) #

	li $t2, -8
	sw $t2 noseDirection2
	jr $ra

# Move doodler right and set nose position
moveDoodlerRight2:
	la $t8, doodle2

	lw $t9, 0($t8) # x
	addi $t9, $t9, -1
	sw $t9, 0($t8) #

	li $t2, 8
	sw $t2 noseDirection2
	jr $ra

# Generate a random x position on screen
randomX:
	li $v0, 42
	li $a0, 0
	li $a1, 32
	syscall
	move $v0, $a0
	jr $ra

# Redraw platforms that fall off screen
redrawPlatform:
	jal randomX
	sw $v0, 0($t0)
	lw $a0, blockSpawnHeight
	sw $a0, 4($t0)
	j continueBlockLoop

# Draw doodler w
drawDoodler2:
	move $s0, $ra
	la $t2, doodle2

	lw $a0, 0($t2) # x
	lw $a1, 4($t2) # y

	li $t2, -5
	bgt $t2, $a1, stopDrawingDoodler2 #dont draw doodler 2 if he falls off screen

	# Clear old doodler with background colour
	jal calculateDisplayOffset
	lw $t1, backgroundColor
	sw $t1, -388($v0)
	sw $t1, -384($v0)
	sw $t1, -380($v0)
	sw $t1, -260($v0)
	sw $t1, -256($v0)
	sw $t1, -252($v0)
	sw $t1, -132($v0)
	sw $t1, -128($v0)
	sw $t1, -124($v0)
	sw $t1, -4($v0)
	sw $t1, 4($v0)
	lw $t3, noseDirection2
	addi $t3, $t3, -256
	add $v0, $v0, $t3
	sw $t1, 0($v0)

	# Move doodler to new position
	lw $t1, moveLeft2
	bne $t1, $zero, doodlerGoLeft2
	lw $t1, moveRight2
	bne $t1, $zero, doodlerGoRight2
	j drawNextPost2
	doodlerGoLeft2:
		jal moveDoodlerLeft2
		j drawNextPost2
	doodlerGoRight2:
		jal moveDoodlerRight2
		j drawNextPost2

	# Draw new doodler position
	drawNextPost2:
	jal gravityIsABitch2

	la $t2, doodle2

	lw $a0, 0($t2) # x
	lw $a1, 4($t2) # y
	li $t2, -5

	jal calculateDisplayOffset

	# Draw new doodler
	lw $t1, doodleColor2
	lw $t6, doodleFeetColor

	sw $t1, -388($v0)
	sw $t1, -384($v0)
	sw $t1, -380($v0)

	sw $t1, -260($v0)
	sw $t1, -256($v0)
	sw $t1, -252($v0)

	sw $t1, -132($v0)
	sw $t1, -128($v0)
	sw $t1, -124($v0)

	sw $t6, -4($v0)
	sw $t6, 4($v0)
	# Draw nose
	lw $t3, noseDirection2

	addi $t3, $t3, -256
	add $v0, $v0, $t3

	sw $t1, 0($v0)

	jr $s0

	# Just return if doodler fell off screen
	stopDrawingDoodler2:
		jr $ra