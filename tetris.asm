################ CSC258H1F Winter 2024 Assembly Final Project ##################
# This file contains our implementation of Tetris.
#
# Student 1: Aabha Roy, 1009064637
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       120
# - Unit height in pixels:      220
# - Display width in pixels:    10
# - Display height in pixels:   8
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000
display_height: 
    .word 22
display_width:
    .word 12
grey_color_border:
    .word 0x808080
grid_color_1:
    # .word 0xADD8E6     #brighter
    .word 0xc1d8f0
grid_color_2:
    # .word 0xF0F0F0    #white
    .word 0xEDEADE      #pale white
piece_color_green:
   #.word 0x50C878      #emrald
   .word 0x32CD32       #lime
piece_color_yellow:
    .word 0xFFEF00
piece_color_purple:
    .word 0x7F4FC9
piece_color_red:
    .word 0xD40C00
piece_color_orange:
    .word 0xFF5500
piece_color_indigo:
    .word 0x3E49BB
piece_color_brown:
    .word 0x7C5547
background_black:
    .word 0x000000
##############################################################################
# Mutable Data
##############################################################################
piece_offsets:
    .space 16               # Reserve space for 4 word-sized offsets
previous_offsets:
    .space 16
current_score:
    .word 0
##############################################################################
# Code
##############################################################################
	.text
	.globl main

	# Run the Tetris game.
main:
    # Initialize the game

lw $s7, current_score           # curent score updates everytime full bottom row
# MILESTONE 1
    lw $t0, ADDR_DSPL           # $t0 = base address for display - top left
    lw $t1, grey_color_border   # $t1 = grey border
    lw $a0, display_height      # a0 = height of bitmap - load in register for function arguments
    lw $a1, display_width       # $a1 = width of bitmap - load in register for function arguments
    li $t2, 0                   # $t2 = loop counter for height - initialize to 0

# Draw the left border of the board
draw_border_left:
    bge $t2, $a0, end_border_left   # Branch to end_border_left if loop counter >= display height
    # Shift left multiplying loop counter by 48 to get address offset stored in $t3
    sll $t4, $t2, 5                 # shift left by 5 bits to multiply by 34, store value in $t4
    sll $t5, $t2, 4                 # shift left by 4 bits to multiply 60, store value in $t5
    add $t3, $t4, $t5               # add shifts to get 48 which is the offset stoed in $t3
    add $t4, $t0, $t3               # Add loop counter to offset to get current pixel address stored in $t4
    sw $t1, 0($t4)                  # Paint current pixel grey
    addi $t2, $t2, 1                # Incrememnt loop counter
    j draw_border_left              # jump to start of loop
end_border_left:
    
# Draw the bottom border of the board
    li $t2, 1012                        # $t2 = starting position - bottom left
draw_border_bottom:
    add $t3, $t0, $t2                   # Add the base address and offset to get starting pixel and store in register $t3
    sw $t1, 0($t3)                      # Store the value at the calculated address $t3 - paint the pixel grey at pixel pointed to by $t3
    addi $t2, $t2, 4                    # Increment the offset by 4
    bgt $t2, 1052, end_border_bottom    # If the offset is greater than 1052, exit the loop
    j draw_border_bottom                # jump to start of loop
end_border_bottom:

# Draw the right border of the board
    li $t2, 44                          # $t2 = starting position - top right
draw_border_right:
    add $t3, $t0, $t2                   # Add the base address and offset to get starting pixel and store in register $t3
    sw $t1, 0($t3)                      # Store the value at the calculated address $t3 - paint the pixel grey at pixel pointed to by $t3
    addi $t2, $t2, 48                    # Increment the offset by 4
    bgt $t2, 1052, end_border_right    # If the offset is greater than 1052, exit the loop
    j draw_border_right                # jump to start of loop
end_border_right:

# Draw grid pattern for rest of the board
    lw $s1, grid_color_1        # $t6 = light blue grid
    lw $s2, grid_color_2        # $t7 = white grid
    li $t1, 1000        # ending offset for grid
    li $t5, 0           # $t5 = switch color flag
    li $t2, 4           # $t2 = starting pixel offset - second pixel
    li $t9, 40          # $t9 = ending pixel offset - second last pixel 
start_grid_pattern:
    bgt $t2, $t1, end_grid_pattern      # End loop when ending offset $t1 is reached
    add $t3, $t0, $t2                   # Add the base address and offset to get current pixel and store in register $t3
    # Alternate colors
    beqz $t5, draw_first_color          # If $t5 is 0, draw the first color
    bne $t5, 0, draw_second_color       # If $t5 is not 0 then second color is used
    draw_first_color:
        sw $s1, 0($t3)                  # Store the first color at the calculated address $t3 - paint pixel blue
        j draw_continue
    draw_second_color:
        sw $s2, 0($t3)                  # Store the second color at the calculated address $t3 - paint pixel white
    draw_continue:
        addi $t2, $t2, 4                # Increment the offset by 4
        bgt $t2, $t9, end_line          # If the offset is greater than last pixel offset for the row, end line
        xori $t5, $t5, 1                 # Invert $t5 to alternate colors when not the last pixel in the row
        j start_grid_pattern
    end_line:
        addi $t9, $t9, 48               # Set the new end of row offset to be the previous one plus 48
        addi $t2, $t2, 8                # jump to next row by skipping two pixels for the border
        j start_grid_pattern
end_grid_pattern:


# MILESTONE 2
draw_peice_I:
    li $s4, 1               # Loads the current angle of rotation - 0:0, 1:90, 2:180, 3:270, since w has been pressed, angle is now 90
    # save color original color of each pixel before changing its color to the piece color
    lw $s3, piece_color_green   # change pixel color to peice color
    sw $s3, 56($t0)
    sw $s3, 104($t0)
    sw $s3, 152($t0)
    sw $s3, 200($t0)
    # load offsets into array
    la $s0, piece_offsets
    # Manually set the offsets
    li $t1, 56
    sw $t1, 0($s0)            # Set first offset
    li $t1, 104
    sw $t1, 4($s0)            # Set second offset
    li $t1, 152
    sw $t1, 8($s0)            # Set third offset
    li $t1, 200
    sw $t1, 12($s0)           # Set fourth offset
    
game_loop:
	# 1a. Check if key has been pressed
	lw $t1, ADDR_KBRD          # $t1 = base address for keyboard
	lw $t8, 0($t1)             # Load first word from keyboard
	beq $t8, 1, keyboard_input # If first word 1, key is pressed
	b game_loop
	
    # 1b. Check which key has been pressed
    keyboard_input:             # A key has been pressed
    lw $a0, 4($t1)            # Load second word from keyboard
    beq $a0, 0x71, respond_to_Q     # Check if $t3 stored the ascii code for q
    beq $a0, 0x77, respond_to_W     # Check if $t3 stored the ascii code for w
    beq $a0, 0x97, respond_to_A     # Check if $t3 stored the ascii code for a
    beq $a0, 0x73, respond_to_S     # Check if $t3 stored the ascii code for s
    beq $a0, 0x64, respond_to_D     # Check if $t3 stored the ascii code for d
    beq $a0, 0x72, respond_to_R
 
    # Moves left
    respond_to_A: 
        # Logic to shift current addresses to the left
        # $s3 = piece color
        lw $t0, ADDR_DSPL
        la $s0, piece_offsets
        lw $s2, grid_color_2
        lw $t8, grey_color_border
        li $t4, 0       # Index for piece_offset array iteration
        li $t5, 4       # Total number of offsets in array
        # Initialize move validity flag to 1 (valid)
        li $t1, 1
            check_validity_left:
                bge $t4, $t5, after_validity_left
                lw $t6, 0($s0)                      # Load current offset to t6
                subi $t6, $t6, 4                     # subtract 4 to get the next offset to the left
                add $t7, $t0, $t6                    # calculate the next pixel address
                lw $t9, 0($t7)                     # Load the current color of the next pixel
                
                beq $t9, $s1, validity_next_left           # Check if the next pixel is not blue, if so check if it is white
                beq $t9, $s2, validity_next_left
                beq $t9, $s3, validity_next_left
            mark_invalid_left:
                li $t1, 0
            validity_next_left:
                addiu $s0, $s0, 4                       # Move to the next offset in the array
                addiu $t4, $t4, 1
                j check_validity_left
                
            after_validity_left:
                beqz, $t1, end_move_left_loop
                la $s0, piece_offsets       # reset piece_offsets to point to the the start of the array
                # lw $t8, grey_color_border
                li $t4, 0       # Reset index for piece_offset array iteration
                li $t5, 4       # reset total number of offsets in array     
                
            erase_current_piece_left:
                bge $t4, $t5, call_redraw_grid_left      # Check if we have gone through all offsets
                lw $t6, 0($s0)                 # Load current offset for piece
                add $t7, $t0, $t6              # Calculate current pixel address
                sw $s2, 0($t7)                 # Set the current pixel to white

                addiu $s0, $s0, 4              # Move to the next offset in the array
                addiu $t4, $t4, 1
                j erase_current_piece_left
            call_redraw_grid_left:
                # Erase piece at current position by restoring grid colors 
                jal redraw_grid
                la $s0, piece_offsets       # reset piece_offsets to point to the the start of the array
                # lw $t8, grey_color_border
                li $t4, 0       # Reset index for piece_offset array iteration
                li $t5, 4       # reset total number of offsets in array     
            move_left_loop:
                bge $t4, $t5, end_move_left_loop    # Check if we have gone through all offsets
                lw $t6, 0($s0)                      # Load current offset for piece
                subi $t6, $t6, 4                     # Sub 4 to move left
                add $t7, $t0, $t6                   # Calculate new pixel address
            
                sw $t6, 0($s0)                      # Update piece_offsets array with new offset
                sw $s3, 0($t7)                      # Draw the piece at the new position
                
                addiu $s0, $s0, 4                   # Move to the next offset in the array
                addiu $t4, $t4, 1
                j move_left_loop
            end_move_left_loop:
            # branch back
            b game_loop

    # Drops peice
    respond_to_S:
        # $s3 = piece color
        lw $t0, ADDR_DSPL
        la $s0, piece_offsets
        lw $s1, grid_color_1        # Load the blue color for comparison
        lw $s2, grid_color_2        # Load the white color for comparison
        li $t4, 0                   # Index for piece_offset array iteration
        li $t5, 4                   # Total number of offsets in array
        # If the color is neither blue nor white, we have reached the bottom and genrate new peice
        # Initialize move validity flag to 1 (valid)
        li $t1, 1
            # change current piece white
            erase_current_piece_down:
                bge $t4, $t5, check_validity_down      # Check if we have gone through all offsets
                lw $t6, 0($s0)                 # Load current offset for piece
                add $t7, $t0, $t6              # Calculate current pixel address
                sw $s2, 0($t7)                 # Set the current pixel to white

                addiu $s0, $s0, 4              # Move to the next offset in the array
                addiu $t4, $t4, 1
                j erase_current_piece_down
            check_validity_down:
                li $t4, 0       # Reset index for piece_offset array iteration
                la $s0, piece_offsets            # Reset the pointer to the start of the array to traverse again
            check_valid_loop:
                bge $t4, $t5, after_validity_down
                lw $t6, 0($s0)                      # Load current offset to t6
                addi $t6, $t6, 48                     # subtract 4 to get the next offset to the left
                add $t7, $t0, $t6                    # calculate the next pixel address
                lw $t9, 0($t7)                     # Load the current color of the next pixel
                
                beq $t9, $s1, validity_next_down       # Check if the next pixel is not blue, if so check if it is white
                beq $t9, $s2, validity_next_down
                li $t1, 0                               # mark invalid
            validity_next_down:
                addiu $s0, $s0, 4                       # Move to the next offset in the array
                addiu $t4, $t4, 1
                j check_valid_loop
                
            invalid_down:
                li $t4, 0       # Reset index for piece_offset array iteration
                la $s0, piece_offsets            # Reset the pointer to the start of the array to traverse again
            redraw_piece:
                beq $t4, $t5, generate_new_piece      # Check if we have gone through all offsets
                lw $t6, 0($s0)                 # Load current offset for piece
                add $t7, $t0, $t6              # Calculate current pixel address
                sw $s3, 0($t7)                 # Set the current pixel to original color

                addiu $s0, $s0, 4              # Move to the next offset in the array
                addiu $t4, $t4, 1
                j redraw_piece
                
            after_validity_down:
                beqz $t1, invalid_down
                la $s0, piece_offsets       # reset piece_offsets to point to the the start of the array
                # lw $t8, grey_color_border
                li $t4, 0       # Reset index for piece_offset array iteration
                li $t5, 4       # reset total number of offsets in array    

            call_redraw_grid_down:
                # Erase piece at current position by restoring grid colors 
                jal redraw_grid
                la $s0, piece_offsets       # reset piece_offsets to point to the the start of the array
                # lw $t8, grey_color_border
                li $t4, 0       # Reset index for piece_offset array iteration
                li $t5, 4       # reset total number of offsets in array
                
            move_down_loop:
                bge $t4, $t5, respond_to_S  # Check if we have gone through all offsets
                lw $t7, 0($s0)                    # Load current offset for piece
                add $t7, $t7, 48                  # Add 48 to move down
                sw $t7, 0($s0)                    # Update piece_offsets array with new offset
                add $t7, $t0, $t7                 # Calculate new pixel address
                sw $s3, 0($t7)                    # Draw the piece at the new position
                addiu $s0, $s0, 4                 # Move to the next offset in the array
                addiu $t4, $t4, 1                 # Increment index
                # invoke sleep system call
                # li $t8, 200             # Base delay of 1000ms
                # li $t9, 50                  # Amount to decrease delay per level
                # mul $t6, $s7, $t9           # $t6 = $s7 * $t9 (total decrease)
                # sub $a0, $t8, $t6           # $a0 = $t8 - $t6 (calculate new delay)

                li $v0 , 32
                li $a0 , 20
                syscall
                j move_down_loop                  # Loop back to start
            
            
    # Moves right
    respond_to_D:
        # $s3 = piece color
        lw $t0, ADDR_DSPL
        la $s0, piece_offsets
        lw $t8, grey_color_border
        li $t4, 0       # Index for piece_offset array iteration
        li $t5, 4       # Total number of offsets in array
        # Initialize move validity flag to 1 (valid)
        li $t1, 1
            check_validity_right:
                bge $t4, $t5, after_validity_right
                lw $t6, 0($s0)                      # Load current offset to t6
                addi $t6, $t6, 4                     # subtract 4 to get the next offset to the left
                add $t7, $t0, $t6                    # calculate the next pixel address
                lw $t9, 0($t7)                     # Load the current color of the next pixel
                
                beq $t9, $s1, validity_next_right           # Check if the next pixel is not blue, if so check if it is white
                beq $t9, $s2, validity_next_right
                beq $t9, $s3, validity_next_right
                li $t1, 0                               # mark invalid
            validity_next_right:
                addiu $s0, $s0, 4                       # Move to the next offset in the array
                addiu $t4, $t4, 1
                j check_validity_right
                
            after_validity_right:
                beqz, $t1, end_move_left_loop
                la $s0, piece_offsets       # reset piece_offsets to point to the the start of the array
                # lw $t8, grey_color_border
                li $t4, 0       # Reset index for piece_offset array iteration
                li $t5, 4       # reset total number of offsets in array     
            erase_current_piece_right:
                bge $t4, $t5, call_redraw_grid_right      # Check if we have gone through all offsets
                lw $t6, 0($s0)                 # Load current offset for piece
                add $t7, $t0, $t6              # Calculate current pixel address
                sw $s2, 0($t7)                 # Set the current pixel to white

                addiu $s0, $s0, 4              # Move to the next offset in the array
                addiu $t4, $t4, 1
                j erase_current_piece_right
            call_redraw_grid_right:
                # Erase piece at current position by restoring grid colors 
                jal redraw_grid
                la $s0, piece_offsets       # reset piece_offsets to point to the the start of the array
                # lw $t8, grey_color_border
                li $t4, 0       # Reset index for piece_offset array iteration
                li $t5, 4       # reset total number of offsets in array                  
            move_right_loop:
                bge $t4, $t5, end_move_right_loop    # Check if we have gone through all offsets
                lw $t6, 0($s0)                      # Load current offset for piece
                addi $t6, $t6, 4                     # Add 4 to move right
                add $t7, $t0, $t6                   # Calculate new pixel address
                
                sw $t6, 0($s0)                      # Update piece_offsets array with new offset
                sw $s3, 0($t7)                      # Draw the piece at the new position
                # Move to the next offset in the array
                addiu $s0, $s0, 4
                addiu $t4, $t4, 1
                j move_right_loop
            end_move_right_loop:
            # branch back
            b game_loop
       
            
    # Rotates Piece
    respond_to_W: 
        la $s0, piece_offsets
        la $s6, previous_offsets
        # $s1 = grid color 1
        # $s2 = grid color 2
        # $s3 = current piece color
        # li $s4, 1               # Loads the current angle of rotation - 0:0, 1:90, 2:180, 3:270, since w has been pressed, angle is now 90
        lw $s5, ADDR_DSPL
        li $t7, 1
        li $t8, 2
        li $t9, 3
        # Load all the colors for comparisons
        lw $t0, piece_color_purple
        lw $t1, piece_color_green
        lw $t2, piece_color_yellow
        lw $t3, piece_color_red
        lw $t4, piece_color_orange
        lw $t5, piece_color_indigo
        lw $t6, piece_color_brown
        # check which piece we are handling based on color - s3 stores the color of the current piece
        beq $s3, $t0, handle_purple_piece       
        beq $s3, $t1, handle_green_piece 
        beq $s3, $t2, handle_yellow_piece 
        beq $s3, $t3, handle_red_piece 
        beq $s3, $t4, handle_orange_piece 
        beq $s3, $t5, handle_indigo_piece 
        beq $s3, $t6, handle_brown_piece 
                
        handle_purple_piece:
            beq $s4, $t7, handle_purple_90 
            beq $s4, $t8, handle_purple_180
            beq $s4, $t9, handle_purple_270
            beq $s4, $zero, handle_purple_0
            handle_purple_90:     
                jal sort_offsets
                lw $t2, 0($s0)                          # Load the first (smallest) offset
                sw $t2, 0($s6)                          # load the offset into the previous offsets array
                addi $t3, $t2, 96                       # Change it to calculate new offset for first pixel
                addi $t3, $t3, 8
                add $t4, $s5, $t3                       # Calculate address of the pixel
                lw $t5, 0($t4)                          # Load the color at this pixel address
                beq $t5, $s1, save_first_purple_90      # If the next pixel is blue save its new location
                beq $t5, $s2, save_first_purple_90      # If not check if it is white instead
                beq $t5, $s3, save_first_purple_90      # last case check if it it's own color
                j rotation_complete                     # If neither, don't rotate, invlid
                save_first_purple_90:
                    sw $t3, 0($s0)                  # Save it back

                lw $t2, 4($s0)                      # Load the second smallest offset
                sw $t2, 4($s6)                      # load the offset into the previous offsets array
                addi $t3, $t2, 48                    # Change it to the new offset 
                addi $t3, $t3, 4
                add $t4, $s5, $t3                   # Calculate address of the pixel
                lw $t5, 0($t4)                      # Load the color at this pixel address
                beq $t5, $s1, save_sec_purple_90 
                beq $t5, $s2, save_sec_purple_90 
                beq $t5, $s3, save_sec_purple_90
                # reset first offset to original
                lw $t2, 0($s0)                      # Load the first (smallest) offset
                subi $t3, $t2, 8
                subi $t3, $t3, 96                   # Change it to calculate new offset for first pixel
                sw $t3, 0($s0)                      # Save it back
                j rotation_complete                 # Don't rotate
                save_sec_purple_90:
                    sw $t3, 4($s0)                  # Save it back

                lw $t2, 8($s0)                      # Load the third smallest offset
                sw $t2, 8($s6)                      # load the offset into the previous offsets array
                addi $t3, $t2, 4                    
                subi $t3, $t3, 48
                add $t4, $s5, $t3                   # Calculate address of the pixel
                lw $t5, 0($t4)                      # Load the color at this pixel address
                beq $t5, $s1, save_third_purple_90 
                beq $t5, $s2, save_third_purple_90 
                beq $t5, $s3, save_third_purple_90
                 # reset first and second offset to original
                lw $t2, 0($s0)                      # Load the first (smallest) offset
                subi $t3, $t2, 8
                subi $t3, $t3, 96                  # Change it to calculate new offset for first pixel
                sw $t3, 0($s0)                      # Save it back
                lw $t2, 4($s0)                      # Load the second smallest offset
                subi $t3, $t2, 4
                subi $t3, $t3, 48             
                sw $t3, 4($s0)                      # Save it back
                j rotation_complete                 # Don't rotate
                save_third_purple_90:
                    sw $t3, 8($s0)                  # Save it back
                lw $t2, 12($s0)                     # Load the last offset
                sw $t2, 12($s6)                     # load the offset into the previous offsets array
                # The fourth (largest) offset remains unchanged, no action needed
                j erase_redraw_piece                # everything is loaded into previous and new offset arrays which will be used to handle changes
    
            handle_purple_180:
                jal sort_offsets
                lw $t2, 0($s0)                          # Load the first (smallest) offset
                sw $t2, 0($s6)                          # load the offset into the previous offsets array
                subi $t3, $t2, 48                       # Change it to calculate new offset for first pixel
                addi $t3, $t3, 12
                add $t4, $s5, $t3                       # Calculate address of the pixel
                lw $t5, 0($t4)                          # Load the color at this pixel address
                beq $t5, $s1, save_first_purple_180     # If the next pixel is blue save its new location
                beq $t5, $s2, save_first_purple_180      # If not check if it is white instead
                beq $t5, $s3, save_first_purple_180      # last case check if it it's own color
                j rotation_complete                     # If neither, don't rotate, invlid
                save_first_purple_180:
                    sw $t3, 0($s0)                  # Save it back

                lw $t2, 4($s0)                      # Load the second smallest offset
                sw $t2, 4($s6)                      # load the offset into the previous offsets array
                subi $t3, $t2, 96                    # Change it to the new offset 
                addi $t3, $t3, 8
                add $t4, $s5, $t3                   # Calculate address of the pixel
                lw $t5, 0($t4)                      # Load the color at this pixel address
                beq $t5, $s1, save_sec_purple_180 
                beq $t5, $s2, save_sec_purple_180
                beq $t5, $s3, save_sec_purple_180
                # reset first offset to original
                lw $t2, 0($s0)                      # Load the first (smallest) offset
                subi $t3, $t2, 12
                addi $t3, $t3, 48                   # Change it to calculate new offset for first pixel
                sw $t3, 0($s0)                      # Save it back
                j rotation_complete                 # Don't rotate
                save_sec_purple_180:
                    sw $t3, 4($s0)                  # Save it back

                lw $t2, 8($s0)                      # Load the third smallest offset
                sw $t2, 8($s6)                      # load the offset into the previous offsets array
                subi $t3, $t2, 48                    
                addi $t3, $t3, 4
                add $t4, $s5, $t3                   # Calculate address of the pixel
                lw $t5, 0($t4)                      # Load the color at this pixel address
                beq $t5, $s1, save_third_purple_180 
                beq $t5, $s2, save_third_purple_180
                beq $t5, $s3, save_third_purple_180
                 # reset first and second offset to original
                lw $t2, 0($s0)                      # Load the first (smallest) offset
                subi $t3, $t2, 12
                addi $t3, $t3, 48                  # Change it to calculate new offset for first pixel
                sw $t3, 0($s0)                      # Save it back
                lw $t2, 4($s0)                      # Load the second smallest offset
                subi $t3, $t2, 8
                addi $t3, $t3, 96             
                sw $t3, 4($s0)                      # Save it back
                j rotation_complete                 # Don't rotate
                save_third_purple_180:
                    sw $t3, 8($s0)                  # Save it back
                lw $t2, 12($s0)                     # Load the last offset
                sw $t2, 12($s6)                     # load the offset into the previous offsets array
                # The fourth (largest) offset remains unchanged, no action needed
                j erase_redraw_piece                # everything is loaded into previous and new offset arrays which will be used to handle changes
                
            handle_purple_270:
                jal sort_offsets
                lw $t2, 0($s0)                          # Load the first (smallest) offset
                sw $t2, 0($s6)                          # load the offset into the previous offsets array
                addi $t3, $t2, 96                       # Change it to calculate new offset for first pixel
                addi $t3, $t3, 8
                add $t4, $s5, $t3                       # Calculate address of the pixel
                lw $t5, 0($t4)                          # Load the color at this pixel address
                beq $t5, $s1, save_first_purple_270     # If the next pixel is blue save its new location
                beq $t5, $s2, save_first_purple_270      # If not check if it is white instead
                beq $t5, $s3, save_first_purple_270      # last case check if it it's own color
                j rotation_complete                     # If neither, don't rotate, invlid
                save_first_purple_270:
                    sw $t3, 0($s0)                  # Save it back

                lw $t2, 4($s0)                      # Load the second smallest offset
                sw $t2, 4($s6)                      # load the offset into the previous offsets array
                addi $t3, $t2, 4                    # Change it to the new offset 
                addi $t3, $t3, 144
                add $t4, $s5, $t3                   # Calculate address of the pixel
                lw $t5, 0($t4)                      # Load the color at this pixel address
                beq $t5, $s1, save_sec_purple_270 
                beq $t5, $s2, save_sec_purple_270
                beq $t5, $s3, save_sec_purple_270
                # reset first offset to original
                lw $t2, 0($s0)                      # Load the first (smallest) offset
                subi $t3, $t2, 96
                subi $t3, $t3, 8                   # Change it to calculate new offset for first pixel
                sw $t3, 0($s0)                      # Save it back
                j rotation_complete                 # Don't rotate
                save_sec_purple_270:
                    sw $t3, 4($s0)                  # Save it back

                lw $t2, 8($s0)                      # Load the third smallest offset
                sw $t2, 8($s6)                      # load the offset into the previous offsets array
                addi $t3, $t2, 4                    
                addi $t3, $t3, 48
                add $t4, $s5, $t3                   # Calculate address of the pixel
                lw $t5, 0($t4)                      # Load the color at this pixel address
                beq $t5, $s1, save_third_purple_270 
                beq $t5, $s2, save_third_purple_270
                beq $t5, $s3, save_third_purple_270
                 # reset first and second offset to original
                lw $t2, 0($s0)                      # Load the first (smallest) offset
                subi $t3, $t2, 12
                addi $t3, $t3, 48                  # Change it to calculate new offset for first pixel
                sw $t3, 0($s0)                      # Save it back
                lw $t2, 4($s0)                      # Load the second smallest offset
                subi $t3, $t2, 8
                addi $t3, $t3, 96             
                sw $t3, 4($s0)                      # Save it back
                j rotation_complete                 # Don't rotate
                save_third_purple_270:
                    sw $t3, 8($s0)                  # Save it back
                lw $t2, 12($s0)                     # Load the last offset
                sw $t2, 12($s6)                     # load the offset into the previous offsets array
                # The fourth (largest) offset remains unchanged, no action needed
                j erase_redraw_piece                # everything is loaded into previous and new offset arrays which will be used to handle changes
                
            handle_purple_0:
                jal sort_offsets
                lw $t2, 0($s0)                          # Load the first (smallest) offset
                sw $t2, 0($s6)                          # load the offset into the previous offsets array
                subi $t3, $t2, 48                       # Change it to calculate new offset for first pixel
                addi $t3, $t3, 12
                add $t4, $s5, $t3                       # Calculate address of the pixel
                lw $t5, 0($t4)                          # Load the color at this pixel address
                beq $t5, $s1, save_first_purple_0     # If the next pixel is blue save its new location
                beq $t5, $s2, save_first_purple_0      # If not check if it is white instead
                beq $t5, $s3, save_first_purple_0      # last case check if it it's own color
                j rotation_complete                     # If neither, don't rotate, invlid
                save_first_purple_0:
                    sw $t3, 0($s0)                  # Save it back

                lw $t2, 4($s0)                      # Load the second smallest offset
                sw $t2, 4($s6)                      # load the offset into the previous offsets array
                addi $t3, $t2, 8                    # Change it to the new offset 
                add $t4, $s5, $t3                   # Calculate address of the pixel
                lw $t5, 0($t4)                      # Load the color at this pixel address
                beq $t5, $s1, save_sec_purple_0 
                beq $t5, $s2, save_sec_purple_0
                beq $t5, $s3, save_sec_purple_0
                # reset first offset to original
                lw $t2, 0($s0)                      # Load the first (smallest) offset
                subi $t3, $t2, 12
                addi $t3, $t3, 48                   # Change it to calculate new offset for first pixel
                sw $t3, 0($s0)                      # Save it back
                j rotation_complete                 # Don't rotate
                save_sec_purple_0:
                    sw $t3, 4($s0)                  # Save it back

                lw $t2, 8($s0)                      # Load the third smallest offset
                sw $t2, 8($s6)                      # load the offset into the previous offsets array
                addi $t3, $t2, 48                    
                addi $t3, $t3, 4
                add $t4, $s5, $t3                   # Calculate address of the pixel
                lw $t5, 0($t4)                      # Load the color at this pixel address
                beq $t5, $s1, save_third_purple_0 
                beq $t5, $s2, save_third_purple_0
                beq $t5, $s3, save_third_purple_0
                 # reset first and second offset to original
                lw $t2, 0($s0)                      # Load the first (smallest) offset
                subi $t3, $t2, 12
                addi $t3, $t3, 48                  # Change it to calculate new offset for first pixel
                sw $t3, 0($s0)                      # Save it back
                lw $t2, 4($s0)                      # Load the second smallest offset
                subi $t3, $t2, 8          
                sw $t3, 4($s0)                      # Save it back
                j rotation_complete                 # Don't rotate
                save_third_purple_0:
                    sw $t3, 8($s0)                  # Save it back
                lw $t2, 12($s0)                     # Load the last offset
                sw $t2, 12($s6)                     # load the offset into the previous offsets array
                # The fourth (largest) offset remains unchanged, no action needed
                j erase_redraw_piece                # everything is loaded into previous and new offset arrays which will be used to handle changes
            
        handle_green_piece:
            beq $s4, $t7, handle_green_90 
            beq $s4, $t8, handle_green_180
            beq $s4, $t9, handle_green_270
            beq $s4, $zero, handle_green_0
            handle_green_90: 
                jal sort_offsets
                lw $t2, 0($s0)                      # Load the first (smallest) offset
                sw $t2, 0($s6)                      # load the offset into the previous offsets array
                addi $t3, $t2, 144                  # Change it to calculate new offset for first pixel
                addi $t3, $t3, 12
                add $t4, $s5, $t3                   # Calculate address of the pixel
                lw $t5, 0($t4)                      # Load the color at this pixel address
                beq $t5, $s1, save_first_green_90     # If the next pixel is blue save its new location
                beq $t5, $s2, save_first_green_90     # If not check if it is white instead
                beq $t5, $s3, save_first_green_90     # last case check if it it's own color
                j rotation_complete                  # If neither, don't rotate, invlid
                save_first_green_90:
                    sw $t3, 0($s0)                  # Save it back

                lw $t2, 4($s0)                      # Load the second smallest offset
                sw $t2, 4($s6)                      # load the offset into the previous offsets array
                addi $t3, $t2, 96                  # Change it to the new offset -(3*48) + (3*4)
                addi $t3, $t3, 8
                add $t4, $s5, $t3                   # Calculate address of the pixel
                lw $t5, 0($t4)                      # Load the color at this pixel address
                beq $t5, $s1, save_sec_green_90 
                beq $t5, $s2, save_sec_green_90 
                beq $t5, $s3, save_sec_green_90
                # reset first offset to original
                lw $t2, 0($s0)                      # Load the first (smallest) offset
                subi $t3, $t2, 12
                addi $t3, $t3, 144                  # Change it to calculate new offset for first pixel
                sw $t3, 0($s0)                      # Save it back
                j rotation_complete                 # Don't rotate
                save_sec_green_90:
                    sw $t3, 4($s0)                  # Save it back

                lw $t2, 8($s0)                      # Load the third smallest offset
                sw $t2, 8($s6)                      # load the offset into the previous offsets array
                addi $t3, $t2, 48                   # add 52 to it
                addi $t3, $t3, 4
                add $t4, $s5, $t3                   # Calculate address of the pixel
                lw $t5, 0($t4)                      # Load the color at this pixel address
                beq $t5, $s1, save_third_green_90 
                beq $t5, $s2, save_third_green_90 
                beq $t5, $s3, save_third_green_90
                 # reset first and second offset to original
                lw $t2, 0($s0)                      # Load the first (smallest) offset
                subi $t3, $t2, 12
                addi $t3, $t3, 144                  # Change it to calculate new offset for first pixel
                sw $t3, 0($s0)                      # Save it back
                lw $t2, 4($s0)                      # Load the second smallest offset
                subi $t3, $t2, 8
                addi $t3, $t3, 96                   # add 52 to it
                sw $t3, 4($s0)                      # Save it back
                j rotation_complete                 # Don't rotate
                save_third_green_90:
                    sw $t3, 8($s0)                      # Save it back
                lw $t2, 12($s0)                         # Load the last offset
                sw $t2, 12($s6)                         # load the offset into the previous offsets array
                # The fourth (largest) offset remains unchanged, no action needed
                j erase_redraw_piece                    # everything is loaded into previous and new offset arrays which will be used to handle changes
                
            handle_green_180:
                jal sort_offsets
                lw $t2, 0($s0)                          # Load the first (smallest) offset
                sw $t2, 0($s6)                          # load the offset into the previous offsets array
                addi $t3, $t2, 12                       # Change it to calculate new offset for first pixel
                subi $t3, $t3, 144
                add $t4, $s5, $t3                       # Calculate address of the pixel
                lw $t5, 0($t4)                          # Load the color at this pixel address
                beq $t5, $s1, save_first_green_180      # If the next pixel is blue save its new location
                beq $t5, $s2, save_first_green_180      # If not check if it is white instead
                beq $t5, $s3, save_first_green_180      # last case check if it it's own color
                j rotation_complete                     # If neither, don't rotate, invlid
                save_first_green_180:
                    sw $t3, 0($s0)                  # Save it back

                lw $t2, 4($s0)                      # Load the second smallest offset
                sw $t2, 4($s6)                      # load the offset into the previous offsets array
                addi $t3, $t2, 8                    # Change it to the new offset 
                subi $t3, $t3, 96
                add $t4, $s5, $t3                   # Calculate address of the pixel
                lw $t5, 0($t4)                      # Load the color at this pixel address
                beq $t5, $s1, save_sec_green_180 
                beq $t5, $s2, save_sec_green_180 
                beq $t5, $s3, save_sec_green_180
                # reset first offset to original
                lw $t2, 0($s0)                      # Load the first (smallest) offset
                addi $t3, $t2, 144
                subi $t3, $t3, 12                   # Change it to calculate new offset for first pixel
                sw $t3, 0($s0)                      # Save it back
                j rotation_complete                 # Don't rotate
                save_sec_green_180:
                    sw $t3, 4($s0)                  # Save it back

                lw $t2, 8($s0)                      # Load the third smallest offset
                sw $t2, 8($s6)                      # load the offset into the previous offsets array
                addi $t3, $t2, 4                    
                subi $t3, $t3, 48
                add $t4, $s5, $t3                   # Calculate address of the pixel
                lw $t5, 0($t4)                      # Load the color at this pixel address
                beq $t5, $s1, save_third_green_180 
                beq $t5, $s2, save_third_green_180 
                beq $t5, $s3, save_third_green_180
                 # reset first and second offset to original
                lw $t2, 0($s0)                      # Load the first (smallest) offset
                subi $t3, $t2, 144
                subi $t3, $t3, 12                  # Change it to calculate new offset for first pixel
                sw $t3, 0($s0)                      # Save it back
                lw $t2, 4($s0)                      # Load the second smallest offset
                addi $t3, $t2, 96
                subi $t3, $t3, 8             
                sw $t3, 4($s0)                      # Save it back
                j rotation_complete                 # Don't rotate
                save_third_green_180:
                    sw $t3, 8($s0)                  # Save it back
                lw $t2, 12($s0)                     # Load the last offset
                sw $t2, 12($s6)                     # load the offset into the previous offsets array
                # The fourth (largest) offset remains unchanged, no action needed
                j erase_redraw_piece                # everything is loaded into previous and new offset arrays which will be used to handle changes
                
            handle_green_270:
                 j handle_green_90
            handle_green_0:
                j handle_green_180
                
        handle_yellow_piece:
            b game_loop
            
        handle_red_piece:
            beq $s4, $t7, handle_red_90 
            beq $s4, $t8, handle_red_180
            beq $s4, $t9, handle_red_270
            beq $s4, $zero, handle_red_0
            handle_red_90:
                jal sort_offsets
                lw $t2, 0($s0)                          # Load the first (smallest) offset
                sw $t2, 0($s6)                          # load the offset into the previous offsets array
                addi $t3, $t2, 48                       # Change it to calculate new offset for first pixel
                addi $t3, $t3, 4
                add $t4, $s5, $t3                       # Calculate address of the pixel
                lw $t5, 0($t4)                          # Load the color at this pixel address
                beq $t5, $s1, save_first_red_90         # If the next pixel is blue save its new location
                beq $t5, $s2, save_first_red_90         # If not check if it is white instead
                beq $t5, $s3, save_first_red_90         # last case check if it it's own color
                j rotation_complete                     # If neither, don't rotate, invlid
                save_first_red_90:
                    sw $t3, 0($s0)                  # Save it back

                lw $t2, 4($s0)                      # Load the second smallest offset
                sw $t2, 4($s6)                      # load the offset into the previous offsets array
                addi $t3, $t2, 96                    # Change it to the new offset 
                add $t4, $s5, $t3                   # Calculate address of the pixel
                lw $t5, 0($t4)                      # Load the color at this pixel address
                beq $t5, $s1, save_sec_red_90 
                beq $t5, $s2, save_sec_red_90
                beq $t5, $s3, save_sec_red_90
                # reset first offset to original
                lw $t2, 0($s0)                      # Load the first (smallest) offset
                subi $t3, $t2, 4
                subi $t3, $t3, 48                   # Change it to calculate new offset for first pixel
                sw $t3, 0($s0)                      # Save it back
                j rotation_complete                 # Don't rotate
                save_sec_red_90:
                    sw $t3, 4($s0)                  # Save it back

                lw $t2, 8($s0)                      # Load the third smallest offset
                sw $t2, 8($s6)                      # load the offset into the previous offsets array
                subi $t3, $t2, 48                    
                addi $t3, $t3, 4
                add $t4, $s5, $t3                   # Calculate address of the pixel
                lw $t5, 0($t4)                      # Load the color at this pixel address
                beq $t5, $s1, save_third_red_90 
                beq $t5, $s2, save_third_red_90
                beq $t5, $s3, save_third_red_90
                 # reset first and second offset to original
                lw $t2, 0($s0)                      # Load the first (smallest) offset
                subi $t3, $t2, 4
                subi $t3, $t3, 48                  # Change it to calculate new offset for first pixel
                sw $t3, 0($s0)                      # Save it back
                lw $t2, 4($s0)                      # Load the second smallest offset
                subi $t3, $t2, 96          
                sw $t3, 4($s0)                      # Save it back
                j rotation_complete                 # Don't rotate
                save_third_red_90:
                    sw $t3, 8($s0)                  # Save it back
                lw $t2, 12($s0)                     # Load the last offset
                sw $t2, 12($s6)                     # load the offset into the previous offsets array
                # The fourth (largest) offset remains unchanged, no action needed
                j erase_redraw_piece                # everything is loaded into previous and new offset arrays which will be used to handle changes
            
            handle_red_180:
                jal sort_offsets
                lw $t2, 0($s0)                          # Load the first (smallest) offset
                sw $t2, 0($s6)                          # load the offset into the previous offsets array
                addi $t3, $t2, 12                       # Change it to calculate new offset for first pixel
                addi $t3, $t3, 48
                add $t4, $s5, $t3                       # Calculate address of the pixel
                lw $t5, 0($t4)                          # Load the color at this pixel address
                beq $t5, $s1, save_first_red_180         # If the next pixel is blue save its new location
                beq $t5, $s2, save_first_red_180         # If not check if it is white instead
                beq $t5, $s3, save_first_red_180         # last case check if it it's own color
                j rotation_complete                     # If neither, don't rotate, invlid
                save_first_red_180:
                    sw $t3, 0($s0)                  # Save it back

                lw $t2, 4($s0)                      # Load the second smallest offset
                sw $t2, 4($s6)                      # load the offset into the previous offsets array
                addi $t3, $t2, 8                    # Change it to the new offset 
                add $t4, $s5, $t3                   # Calculate address of the pixel
                lw $t5, 0($t4)                      # Load the color at this pixel address
                beq $t5, $s1, save_sec_red_180 
                beq $t5, $s2, save_sec_red_180
                beq $t5, $s3, save_sec_red_180
                # reset first offset to original
                lw $t2, 0($s0)                      # Load the first (smallest) offset
                subi $t3, $t2, 12
                subi $t3, $t3, 48                   # Change it to calculate new offset for first pixel
                sw $t3, 0($s0)                      # Save it back
                j rotation_complete                 # Don't rotate
                save_sec_red_180:
                    sw $t3, 4($s0)                  # Save it back

                lw $t2, 8($s0)                      # Load the third smallest offset
                sw $t2, 8($s6)                      # load the offset into the previous offsets array
                addi $t3, $t2, 48                    
                addi $t3, $t3, 4
                add $t4, $s5, $t3                   # Calculate address of the pixel
                lw $t5, 0($t4)                      # Load the color at this pixel address
                beq $t5, $s1, save_third_red_180 
                beq $t5, $s2, save_third_red_180
                beq $t5, $s3, save_third_red_180
                 # reset first and second offset to original
                lw $t2, 0($s0)                      # Load the first (smallest) offset
                subi $t3, $t2, 12
                subi $t3, $t3, 48                  # Change it to calculate new offset for first pixel
                sw $t3, 0($s0)                      # Save it back
                lw $t2, 4($s0)                      # Load the second smallest offset
                subi $t3, $t2, 8          
                sw $t3, 4($s0)                      # Save it back
                j rotation_complete                 # Don't rotate
                save_third_red_180:
                    sw $t3, 8($s0)                  # Save it back
                lw $t2, 12($s0)                     # Load the last offset
                sw $t2, 12($s6)                     # load the offset into the previous offsets array
                # The fourth (largest) offset remains unchanged, no action needed
                j erase_redraw_piece                # everything is loaded into previous and new offset arrays which will be used to handle changes
             
            handle_red_270:
                j handle_red_90
            handle_red_0:
                j handle_red_180
                
        handle_orange_piece:
            beq $s4, $t7, handle_orange_90 
            beq $s4, $t8, handle_orange_180
            beq $s4, $t9, handle_orange_270
            beq $s4, $zero, handle_orange_0
            
            handle_orange_90:
                jal sort_offsets
                lw $t2, 0($s0)                          # Load the first (smallest) offset
                sw $t2, 0($s6)                          # load the offset into the previous offsets array
                addi $t3, $t2, 12                       # Change it to calculate new offset for first pixel
                addi $t3, $t3, 48
                add $t4, $s5, $t3                       # Calculate address of the pixel
                lw $t5, 0($t4)                          # Load the color at this pixel address
                beq $t5, $s1, save_first_orange_90         # If the next pixel is blue save its new location
                beq $t5, $s2, save_first_orange_90         # If not check if it is white instead
                beq $t5, $s3, save_first_orange_90         # last case check if it it's own color
                j rotation_complete                     # If neither, don't rotate, invlid
                save_first_orange_90:
                    sw $t3, 0($s0)                  # Save it back

                lw $t2, 4($s0)                      # Load the second smallest offset
                sw $t2, 4($s6)                      # load the offset into the previous offsets array
                addi $t3, $t2, 8                    # Change it to the new offset 
                add $t4, $s5, $t3                   # Calculate address of the pixel
                lw $t5, 0($t4)                      # Load the color at this pixel address
                beq $t5, $s1, save_sec_orange_90 
                beq $t5, $s2, save_sec_orange_90
                beq $t5, $s3, save_sec_orange_90
                # reset first offset to original
                lw $t2, 0($s0)                      # Load the first (smallest) offset
                subi $t3, $t2, 12
                subi $t3, $t3, 48                   # Change it to calculate new offset for first pixel
                sw $t3, 0($s0)                      # Save it back
                j rotation_complete                 # Don't rotate
                save_sec_orange_90:
                    sw $t3, 4($s0)                  # Save it back

                lw $t2, 8($s0)                      # Load the third smallest offset
                sw $t2, 8($s6)                      # load the offset into the previous offsets array
                subi $t3, $t2, 48                    
                addi $t3, $t3, 4
                add $t4, $s5, $t3                   # Calculate address of the pixel
                lw $t5, 0($t4)                      # Load the color at this pixel address
                beq $t5, $s1, save_third_orange_90 
                beq $t5, $s2, save_third_orange_90
                beq $t5, $s3, save_third_orange_90
                 # reset first and second offset to original
                lw $t2, 0($s0)                      # Load the first (smallest) offset
                subi $t3, $t2, 12
                subi $t3, $t3, 48                  # Change it to calculate new offset for first pixel
                sw $t3, 0($s0)                      # Save it back
                lw $t2, 4($s0)                      # Load the second smallest offset
                subi $t3, $t2, 8          
                sw $t3, 4($s0)                      # Save it back
                j rotation_complete                 # Don't rotate
                save_third_orange_90:
                    sw $t3, 8($s0)                  # Save it back
                lw $t2, 12($s0)                     # Load the last offset
                sw $t2, 12($s6)                     # load the offset into the previous offsets array
                # The fourth (largest) offset remains unchanged, no action needed
                j erase_redraw_piece                # everything is loaded into previous and new offset arrays which will be used to handle changes
             
            handle_orange_180:
                jal sort_offsets
                lw $t2, 0($s0)                          # Load the first (smallest) offset
                sw $t2, 0($s6)                          # load the offset into the previous offsets array
                addi $t3, $t2, 4                       # Change it to calculate new offset for first pixel
                addi $t3, $t3, 48
                add $t4, $s5, $t3                       # Calculate address of the pixel
                lw $t5, 0($t4)                          # Load the color at this pixel address
                beq $t5, $s1, save_first_orange_180         # If the next pixel is blue save its new location
                beq $t5, $s2, save_first_orange_180         # If not check if it is white instead
                beq $t5, $s3, save_first_orange_180         # last case check if it it's own color
                j rotation_complete                     # If neither, don't rotate, invlid
                save_first_orange_180:
                    sw $t3, 0($s0)                  # Save it back

                lw $t2, 4($s0)                      # Load the second smallest offset
                sw $t2, 4($s6)                      # load the offset into the previous offsets array
                addi $t3, $t2, 96                    # Change it to the new offset 
                add $t4, $s5, $t3                   # Calculate address of the pixel
                lw $t5, 0($t4)                      # Load the color at this pixel address
                beq $t5, $s1, save_sec_orange_180 
                beq $t5, $s2, save_sec_orange_180
                beq $t5, $s3, save_sec_orange_180
                # reset first offset to original
                lw $t2, 0($s0)                      # Load the first (smallest) offset
                subi $t3, $t2, 48
                subi $t3, $t3, 4                   # Change it to calculate new offset for first pixel
                sw $t3, 0($s0)                      # Save it back
                j rotation_complete                 # Don't rotate
                save_sec_orange_180:
                    sw $t3, 4($s0)                  # Save it back

                lw $t2, 8($s0)                      # Load the third smallest offset
                sw $t2, 8($s6)                      # load the offset into the previous offsets array
                addi $t3, $t2, 144                    
                subi $t3, $t3, 4
                add $t4, $s5, $t3                   # Calculate address of the pixel
                lw $t5, 0($t4)                      # Load the color at this pixel address
                beq $t5, $s1, save_third_orange_180 
                beq $t5, $s2, save_third_orange_180
                beq $t5, $s3, save_third_orange_180
                 # reset first and second offset to original
                lw $t2, 0($s0)                      # Load the first (smallest) offset
                subi $t3, $t2, 48
                subi $t3, $t3, 4                  # Change it to calculate new offset for first pixel
                sw $t3, 0($s0)                      # Save it back
                lw $t2, 4($s0)                      # Load the second smallest offset
                subi $t3, $t2, 96          
                sw $t3, 4($s0)                      # Save it back
                j rotation_complete                 # Don't rotate
                save_third_orange_180:
                    sw $t3, 8($s0)                  # Save it back
                lw $t2, 12($s0)                     # Load the last offset
                sw $t2, 12($s6)                     # load the offset into the previous offsets array
                # The fourth (largest) offset remains unchanged, no action needed
                j erase_redraw_piece                # everything is loaded into previous and new offset arrays which will be used to handle changes
             
            handle_orange_270:
                jal sort_offsets
                lw $t2, 0($s0)                          # Load the first (smallest) offset
                sw $t2, 0($s6)                          # load the offset into the previous offsets array
                addi $t3, $t2, 12                       # Change it to calculate new offset for first pixel
                addi $t3, $t3, 48
                add $t4, $s5, $t3                       # Calculate address of the pixel
                lw $t5, 0($t4)                          # Load the color at this pixel address
                beq $t5, $s1, save_first_orange_270         # If the next pixel is blue save its new location
                beq $t5, $s2, save_first_orange_270         # If not check if it is white instead
                beq $t5, $s3, save_first_orange_270         # last case check if it it's own color
                j rotation_complete                     # If neither, don't rotate, invlid
                save_first_orange_270:
                    sw $t3, 0($s0)                  # Save it back

                lw $t2, 4($s0)                      # Load the second smallest offset
                sw $t2, 4($s6)                      # load the offset into the previous offsets array
                addi $t3, $t2, 8                    # Change it to the new offset 
                addi $t3, $t3, 96
                add $t4, $s5, $t3                   # Calculate address of the pixel
                lw $t5, 0($t4)                      # Load the color at this pixel address
                beq $t5, $s1, save_sec_orange_270 
                beq $t5, $s2, save_sec_orange_270
                beq $t5, $s3, save_sec_orange_270
                # reset first offset to original
                lw $t2, 0($s0)                      # Load the first (smallest) offset
                subi $t3, $t2, 12
                subi $t3, $t3, 48                   # Change it to calculate new offset for first pixel
                sw $t3, 0($s0)                      # Save it back
                j rotation_complete                 # Don't rotate
                save_sec_orange_270:
                    sw $t3, 4($s0)                  # Save it back

                lw $t2, 8($s0)                      # Load the third smallest offset
                sw $t2, 8($s6)                      # load the offset into the previous offsets array
                addi $t3, $t2, 48                    
                addi $t3, $t3, 4
                add $t4, $s5, $t3                   # Calculate address of the pixel
                lw $t5, 0($t4)                      # Load the color at this pixel address
                beq $t5, $s1, save_third_orange_270 
                beq $t5, $s2, save_third_orange_270
                beq $t5, $s3, save_third_orange_270
                 # reset first and second offset to original
                lw $t2, 0($s0)                      # Load the first (smallest) offset
                subi $t3, $t2, 12
                subi $t3, $t3, 48                  # Change it to calculate new offset for first pixel
                sw $t3, 0($s0)                      # Save it back
                lw $t2, 4($s0)                      # Load the second smallest offset
                subi $t3, $t2, 8          
                subi $t3, $t3, 96
                sw $t3, 4($s0)                      # Save it back
                j rotation_complete                 # Don't rotate
                save_third_orange_270:
                    sw $t3, 8($s0)                  # Save it back
                lw $t2, 12($s0)                     # Load the last offset
                sw $t2, 12($s6)                     # load the offset into the previous offsets array
                # The fourth (largest) offset remains unchanged, no action needed
                j erase_redraw_piece                # everything is loaded into previous and new offset arrays which will be used to handle changes
             
            handle_orange_0:
                jal sort_offsets
                lw $t2, 0($s0)                          # Load the first (smallest) offset
                sw $t2, 0($s6)                          # load the offset into the previous offsets array
                addi $t3, $t2, 4                       # Change it to calculate new offset for first pixel
                addi $t3, $t3, 48
                add $t4, $s5, $t3                       # Calculate address of the pixel
                lw $t5, 0($t4)                          # Load the color at this pixel address
                beq $t5, $s1, save_first_orange_0         # If the next pixel is blue save its new location
                beq $t5, $s2, save_first_orange_0         # If not check if it is white instead
                beq $t5, $s3, save_first_orange_0         # last case check if it it's own color
                j rotation_complete                     # If neither, don't rotate, invlid
                save_first_orange_0:
                    sw $t3, 0($s0)                  # Save it back

                lw $t2, 4($s0)                      # Load the second smallest offset
                sw $t2, 4($s6)                      # load the offset into the previous offsets array
                addi $t3, $t2, 8                    # Change it to the new offset 
                subi $t3, $t3, 96
                add $t4, $s5, $t3                   # Calculate address of the pixel
                lw $t5, 0($t4)                      # Load the color at this pixel address
                beq $t5, $s1, save_sec_orange_0 
                beq $t5, $s2, save_sec_orange_0
                beq $t5, $s3, save_sec_orange_0
                # reset first offset to original
                lw $t2, 0($s0)                      # Load the first (smallest) offset
                subi $t3, $t2, 4
                subi $t3, $t3, 48                   # Change it to calculate new offset for first pixel
                sw $t3, 0($s0)                      # Save it back
                j rotation_complete                 # Don't rotate
                save_sec_orange_0:
                    sw $t3, 4($s0)                  # Save it back

                lw $t2, 8($s0)                      # Load the third smallest offset
                sw $t2, 8($s6)                      # load the offset into the previous offsets array
                subi $t3, $t2, 48                    
                addi $t3, $t3, 4
                add $t4, $s5, $t3                   # Calculate address of the pixel
                lw $t5, 0($t4)                      # Load the color at this pixel address
                beq $t5, $s1, save_third_orange_0 
                beq $t5, $s2, save_third_orange_0
                beq $t5, $s3, save_third_orange_0
                 # reset first and second offset to original
                lw $t2, 0($s0)                      # Load the first (smallest) offset
                subi $t3, $t2, 4
                subi $t3, $t3, 48                  # Change it to calculate new offset for first pixel
                sw $t3, 0($s0)                      # Save it back
                lw $t2, 4($s0)                      # Load the second smallest offset
                subi $t3, $t2, 8     
                add $t3, $t3, 48
                sw $t3, 4($s0)                      # Save it back
                j rotation_complete                 # Don't rotate
                save_third_orange_0:
                    sw $t3, 8($s0)                  # Save it back
                lw $t2, 12($s0)                     # Load the last offset
                sw $t2, 12($s6)                     # load the offset into the previous offsets array
                # The fourth (largest) offset remains unchanged, no action needed
                j erase_redraw_piece                # everything is loaded into previous and new offset arrays which will be used to handle changes
             
        handle_indigo_piece:
            beq $s4, $t7, handle_indigo_90 
            beq $s4, $t8, handle_indigo_180
            beq $s4, $t9, handle_indigo_270
            beq $s4, $zero, handle_indigo_0
            handle_indigo_90:
                jal sort_offsets
                lw $t2, 0($s0)                          # Load the first (smallest) offset
                sw $t2, 0($s6)                          # load the offset into the previous offsets array
                addi $t3, $t2, 4                       # Change it to calculate new offset for first pixel
                subi $t3, $t3, 48
                add $t4, $s5, $t3                       # Calculate address of the pixel
                lw $t5, 0($t4)                          # Load the color at this pixel address
                beq $t5, $s1, save_first_indigo_90      # If the next pixel is blue save its new location
                beq $t5, $s2, save_first_indigo_90        # If not check if it is white instead
                beq $t5, $s3, save_first_indigo_90         # last case check if it it's own color
                j rotation_complete                     # If neither, don't rotate, invlid
                save_first_indigo_90:
                    sw $t3, 0($s0)                  # Save it back

                lw $t2, 4($s0)                      # Load the second smallest offset
                sw $t2, 4($s6)                      # load the offset into the previous offsets array
                addi $t3, $t2, 4                    # Change it to the new offset 
                add $t4, $s5, $t2                   # Calculate address of the pixel
                lw $t5, 0($t4)                      # Load the color at this pixel address
                beq $t5, $s1, save_sec_indigo_90 
                beq $t5, $s2, save_sec_indigo_90
                beq $t5, $s3, save_sec_indigo_90
                # reset first offset to original
                lw $t2, 0($s0)                      # Load the first (smallest) offset
                subi $t3, $t2, 4
                addi $t3, $t3, 48                   # Change it to calculate new offset for first pixel
                sw $t3, 0($s0)                      # Save it back
                j rotation_complete                 # Don't rotate
                save_sec_indigo_90:
                    sw $t3, 4($s0)                  # Save it back

                lw $t2, 8($s0)                      # Load the third smallest offset
                sw $t2, 8($s6)                      # load the offset into the previous offsets array
                subi $t3, $t2, 48                    
                add $t4, $s5, $t3                   # Calculate address of the pixel
                lw $t5, 0($t4)                      # Load the color at this pixel address
                beq $t5, $s1, save_third_indigo_90 
                beq $t5, $s2, save_third_indigo_90
                beq $t5, $s3, save_third_indigo_90
                 # reset first and second offset to original
                lw $t2, 0($s0)                      # Load the first (smallest) offset
                subi $t3, $t2, 4
                addi $t3, $t3, 48                  # Change it to calculate new offset for first pixel
                sw $t3, 0($s0)                      # Save it back
                lw $t2, 4($s0)                      # Load the second smallest offset
                subi $t3, $t2, 4     
                sw $t3, 4($s0)                      # Save it back
                j rotation_complete                 # Don't rotate
                save_third_indigo_90:
                    sw $t3, 8($s0)                  # Save it back
                    
                lw $t2, 12($s0)                     # Load the last offset
                sw $t2, 12($s6)                     # load the offset into the previous offsets array
                # The fourth (largest) offset remains unchanged, no action needed
                j erase_redraw_piece                # everything is loaded into previous and new offset arrays which will be used to handle changes
             
            handle_indigo_180:
                jal sort_offsets
                lw $t2, 0($s0)                          # Load the first (smallest) offset
                sw $t2, 0($s6)                          # load the offset into the previous offsets array
                addi $t3, $t2, 12                       # Change it to calculate new offset for first pixel
                addi $t3, $t3, 144
                add $t4, $s5, $t3                       # Calculate address of the pixel
                lw $t5, 0($t4)                          # Load the color at this pixel address
                beq $t5, $s1, save_first_indigo_180      # If the next pixel is blue save its new location
                beq $t5, $s2, save_first_indigo_180     # If not check if it is white instead
                beq $t5, $s3, save_first_indigo_180     # last case check if it it's own color
                j rotation_complete                     # If neither, don't rotate, invlid
                save_first_indigo_180:
                    sw $t3, 0($s0)                  # Save it back

                lw $t2, 4($s0)                      # Load the second smallest offset
                sw $t2, 4($s6)                      # load the offset into the previous offsets array
                addi $t3, $t2, 8                    # Change it to the new offset 
                addi $t3, $t3, 48
                add $t4, $s5, $t2                   # Calculate address of the pixel
                lw $t5, 0($t4)                      # Load the color at this pixel address
                beq $t5, $s1, save_sec_indigo_180 
                beq $t5, $s2, save_sec_indigo_180
                beq $t5, $s3, save_sec_indigo_180
                # reset first offset to original
                lw $t2, 0($s0)                      # Load the first (smallest) offset
                subi $t3, $t2, 144
                subi $t3, $t3, 12                   # Change it to calculate new offset for first pixel
                sw $t3, 0($s0)                      # Save it back
                j rotation_complete                 # Don't rotate
                save_sec_indigo_180:
                    sw $t3, 4($s0)                  # Save it back

                lw $t2, 8($s0)                      # Load the third smallest offset
                sw $t2, 8($s6)                      # load the offset into the previous offsets array
                addi $t3, $t2, 96                    
                addi $t3, $t3, 4
                add $t4, $s5, $t3                   # Calculate address of the pixel
                lw $t5, 0($t4)                      # Load the color at this pixel address
                beq $t5, $s1, save_third_indigo_180 
                beq $t5, $s2, save_third_indigo_180
                beq $t5, $s3, save_third_indigo_180
                 # reset first and second offset to original
                lw $t2, 0($s0)                      # Load the first (smallest) offset
                subi $t3, $t2, 12
                subi $t3, $t3, 144                  # Change it to calculate new offset for first pixel
                sw $t3, 0($s0)                      # Save it back
                lw $t2, 4($s0)                      # Load the second smallest offset
                subi $t3, $t2, 8     
                subi $t3, $t3, 48
                sw $t3, 4($s0)                      # Save it back
                j rotation_complete                 # Don't rotate
                save_third_indigo_180:
                    sw $t3, 8($s0)                  # Save it back
                lw $t2, 12($s0)                     # Load the last offset
                sw $t2, 12($s6)                     # load the offset into the previous offsets array
                # The fourth (largest) offset remains unchanged, no action needed
                j erase_redraw_piece                # everything is loaded into previous and new offset arrays which will be used to handle changes
             
            handle_indigo_270:
                j handle_indigo_90
            
            handle_indigo_0:
                j handle_indigo_180
                
        handle_brown_piece:
            beq $s4, $t7, handle_brown_90 
            beq $s4, $t8, handle_brown_180
            beq $s4, $t9, handle_brown_270
            beq $s4, $zero, handle_brown_0
            handle_brown_90:
                jal sort_offsets
                lw $t2, 0($s0)                          # Load the first (smallest) offset
                sw $t2, 0($s6)                          # load the offset into the previous offsets array
                addi $t3, $t2, 8                       # Change it to calculate new offset for first pixel
                add $t4, $s5, $t3                       # Calculate address of the pixel
                lw $t5, 0($t4)                          # Load the color at this pixel address
                beq $t5, $s1, save_first_brown_90      # If the next pixel is blue save its new location
                beq $t5, $s2, save_first_brown_90     # If not check if it is white instead
                beq $t5, $s3, save_first_brown_90     # last case check if it it's own color
                j rotation_complete                     # If neither, don't rotate, invlid
                save_first_brown_90:
                    sw $t3, 0($s0)                  # Save it back

                lw $t2, 4($s0)                      # Load the second smallest offset
                sw $t2, 4($s6)                      # load the offset into the previous offsets array
                addi $t3, $t2, 4                    # Change it to the new offset 
                addi $t3, $t3, 48
                add $t4, $s5, $t2                   # Calculate address of the pixel
                lw $t5, 0($t4)                      # Load the color at this pixel address
                beq $t5, $s1, save_sec_brown_90 
                beq $t5, $s2, save_sec_brown_90
                beq $t5, $s3, save_sec_brown_90
                # reset first offset to original
                lw $t2, 0($s0)                      # Load the first (smallest) offset
                subi $t3, $t2, 8
                sw $t3, 0($s0)                      # Save it back
                j rotation_complete                 # Don't rotate
                save_sec_brown_90:
                    sw $t3, 4($s0)                  # Save it back

                lw $t2, 8($s0)                      # Load the third smallest offset
                sw $t2, 8($s6)                      # load the offset into the previous offsets array
                addi $t3, $t2, 96                    
                add $t4, $s5, $t3                   # Calculate address of the pixel
                lw $t5, 0($t4)                      # Load the color at this pixel address
                beq $t5, $s1, save_third_brown_90 
                beq $t5, $s2, save_third_brown_90
                beq $t5, $s3, save_third_brown_90
                 # reset first and second offset to original
                lw $t2, 0($s0)                      # Load the first (smallest) offset
                subi $t3, $t2, 96
                sw $t3, 0($s0)                      # Save it back
                lw $t2, 4($s0)                      # Load the second smallest offset
                subi $t3, $t2, 4     
                subi $t3, $t3, 48
                sw $t3, 4($s0)                      # Save it back
                j rotation_complete                 # Don't rotate
                save_third_brown_90:
                    sw $t3, 8($s0)                  # Save it back
                lw $t2, 12($s0)                     # Load the last offset
                sw $t2, 12($s6)                     # load the offset into the previous offsets array
                # The fourth (largest) offset remains unchanged, no action needed
                j erase_redraw_piece                # everything is loaded into previous and new offset arrays which will be used to handle changes
                
            handle_brown_180:
                jal sort_offsets
                lw $t2, 0($s0)                          # Load the first (smallest) offset
                sw $t2, 0($s6)                          # load the offset into the previous offsets array
                addi $t3, $t2, 8                       # Change it to calculate new offset for first pixel
                addi $t3, $t3, 96
                add $t4, $s5, $t3                       # Calculate address of the pixel
                lw $t5, 0($t4)                          # Load the color at this pixel address
                beq $t5, $s1, save_first_brown_180      # If the next pixel is blue save its new location
                beq $t5, $s2, save_first_brown_180      # If not check if it is white instead
                beq $t5, $s3, save_first_brown_180      # last case check if it it's own color
                j rotation_complete                     # If neither, don't rotate, invlid
                save_first_brown_180:
                    sw $t3, 0($s0)                  # Save it back

                lw $t2, 4($s0)                      # Load the second smallest offset
                sw $t2, 4($s6)                      # load the offset into the previous offsets array
                addi $t3, $t2, 8                    # Change it to the new offset 
                add $t4, $s5, $t2                   # Calculate address of the pixel
                lw $t5, 0($t4)                      # Load the color at this pixel address
                beq $t5, $s1, save_sec_brown_180 
                beq $t5, $s2, save_sec_brown_180
                beq $t5, $s3, save_sec_brown_180
                # reset first offset to original
                lw $t2, 0($s0)                      # Load the first (smallest) offset
                subi $t3, $t2, 96
                subi $t3, $t3, 8
                sw $t3, 0($s0)                      # Save it back
                j rotation_complete                 # Don't rotate
                save_sec_brown_180:
                    sw $t3, 4($s0)                  # Save it back

                lw $t2, 8($s0)                      # Load the third smallest offset
                sw $t2, 8($s6)                      # load the offset into the previous offsets array
                addi $t3, $t2, 4
                addi $t3, $t3, 48
                add $t4, $s5, $t3                   # Calculate address of the pixel
                lw $t5, 0($t4)                      # Load the color at this pixel address
                beq $t5, $s1, save_third_brown_180 
                beq $t5, $s2, save_third_brown_180
                beq $t5, $s3, save_third_brown_180
                 # reset first and second offset to original
                lw $t2, 0($s0)                      # Load the first (smallest) offset
                subi $t3, $t2, 96
                subi $t3, $t3, 8
                sw $t3, 0($s0)                      # Save it back
                lw $t2, 4($s0)                      # Load the second smallest offset
                subi $t3, $t2, 8     
                sw $t3, 4($s0)                      # Save it back
                j rotation_complete                 # Don't rotate
                save_third_brown_180:
                    sw $t3, 8($s0)                  # Save it back
                lw $t2, 12($s0)                     # Load the last offset
                sw $t2, 12($s6)                     # load the offset into the previous offsets array
                # The fourth (largest) offset remains unchanged, no action needed
                j erase_redraw_piece                # everything is loaded into previous and new offset arrays which will be used to handle changes
                
            handle_brown_270:
                jal sort_offsets
                lw $t2, 0($s0)                          # Load the first (smallest) offset
                sw $t2, 0($s6)                          # load the offset into the previous offsets array
                addi $t3, $t2, 8                       # Change it to calculate new offset for first pixel
                add $t4, $s5, $t3                       # Calculate address of the pixel
                lw $t5, 0($t4)                          # Load the color at this pixel address
                beq $t5, $s1, save_first_brown_270      # If the next pixel is blue save its new location
                beq $t5, $s2, save_first_brown_270     # If not check if it is white instead
                beq $t5, $s3, save_first_brown_270     # last case check if it it's own color
                j rotation_complete                     # If neither, don't rotate, invlid
                save_first_brown_270:
                    sw $t3, 0($s0)                  # Save it back

                lw $t2, 4($s0)                      # Load the second smallest offset
                sw $t2, 4($s6)                      # load the offset into the previous offsets array
                addi $t3, $t2, 8                    # Change it to the new offset 
                subi $t3, $t3, 96
                add $t4, $s5, $t2                   # Calculate address of the pixel
                lw $t5, 0($t4)                      # Load the color at this pixel address
                beq $t5, $s1, save_sec_brown_270 
                beq $t5, $s2, save_sec_brown_270
                beq $t5, $s3, save_sec_brown_270
                # reset first offset to original
                lw $t2, 0($s0)                      # Load the first (smallest) offset
                subi $t3, $t2, 8
                sw $t3, 0($s0)                      # Save it back
                j rotation_complete                 # Don't rotate
                save_sec_brown_270:
                    sw $t3, 4($s0)                  # Save it back

                lw $t2, 8($s0)                      # Load the third smallest offset
                sw $t2, 8($s6)                      # load the offset into the previous offsets array
                addi $t3, $t2, 4
                subi $t3, $t3, 48
                add $t4, $s5, $t3                   # Calculate address of the pixel
                lw $t5, 0($t4)                      # Load the color at this pixel address
                beq $t5, $s1, save_third_brown_270 
                beq $t5, $s2, save_third_brown_270
                beq $t5, $s3, save_third_brown_270
                 # reset first and second offset to original
                lw $t2, 0($s0)                      # Load the first (smallest) offset
                subi $t3, $t2, 8
                sw $t3, 0($s0)                      # Save it back
                lw $t2, 4($s0)                      # Load the second smallest offset
                subi $t3, $t2, 8     
                addi $t3, $t3, 96
                sw $t3, 4($s0)                      # Save it back
                j rotation_complete                 # Don't rotate
                save_third_brown_270:
                    sw $t3, 8($s0)                  # Save it back
                lw $t2, 12($s0)                     # Load the last offset
                sw $t2, 12($s6)                     # load the offset into the previous offsets array
                # The fourth (largest) offset remains unchanged, no action needed
                j erase_redraw_piece                # everything is loaded into previous and new offset arrays which will be used to handle changes
                
            handle_brown_0:
                jal sort_offsets
                lw $t2, 0($s0)                          # Load the first (smallest) offset
                sw $t2, 0($s6)                          # load the offset into the previous offsets array
                addi $t3, $t2, 8                        # Change it to calculate new offset for first pixel
                addi $t3, $t3, 96
                add $t4, $s5, $t3                       # Calculate address of the pixel
                lw $t5, 0($t4)                          # Load the color at this pixel address
                beq $t5, $s1, save_first_brown_0      # If the next pixel is blue save its new location
                beq $t5, $s2, save_first_brown_0     # If not check if it is white instead
                beq $t5, $s3, save_first_brown_0     # last case check if it it's own color
                j rotation_complete                     # If neither, don't rotate, invlid
                save_first_brown_0:
                    sw $t3, 0($s0)                  # Save it back

                lw $t2, 4($s0)                      # Load the second smallest offset
                sw $t2, 4($s6)                      # load the offset into the previous offsets array
                addi $t3, $t2, 4                    # Change it to the new offset 
                addi $t3, $t3, 48
                add $t4, $s5, $t2                   # Calculate address of the pixel
                lw $t5, 0($t4)                      # Load the color at this pixel address
                beq $t5, $s1, save_sec_brown_0 
                beq $t5, $s2, save_sec_brown_0
                beq $t5, $s3, save_sec_brown_0
                # reset first offset to original
                lw $t2, 0($s0)                      # Load the first (smallest) offset
                subi $t3, $t2, 8
                subi $t3, $t3, 96
                sw $t3, 0($s0)                      # Save it back
                j rotation_complete                 # Don't rotate
                save_sec_brown_0:
                    sw $t3, 4($s0)                  # Save it back

                lw $t2, 8($s0)                      # Load the third smallest offset
                sw $t2, 8($s6)                      # load the offset into the previous offsets array
                addi $t3, $t2, 96                    
                add $t4, $s5, $t3                   # Calculate address of the pixel
                lw $t5, 0($t4)                      # Load the color at this pixel address
                beq $t5, $s1, save_third_brown_0 
                beq $t5, $s2, save_third_brown_0
                beq $t5, $s3, save_third_brown_0
                 # reset first and second offset to original
                lw $t2, 0($s0)                      # Load the first (smallest) offset
                subi $t3, $t2, 96
                subi $t3, $t3, 8
                sw $t3, 0($s0)                      # Save it back
                lw $t2, 4($s0)                      # Load the second smallest offset
                subi $t3, $t2, 4     
                subi $t3, $t3, 48
                sw $t3, 4($s0)                      # Save it back
                j rotation_complete                 # Don't rotate
                save_third_brown_0:
                    sw $t3, 8($s0)                  # Save it back
                lw $t2, 12($s0)                     # Load the last offset
                sw $t2, 12($s6)                     # load the offset into the previous offsets array
                # The fourth (largest) offset remains unchanged, no action needed
                j erase_redraw_piece                # everything is loaded into previous and new offset arrays which will be used to handle changes
                
        erase_redraw_piece:
                lw $t0, ADDR_DSPL
                # first change the previous offset to white so it can be erased by access the previous offsets array
                li $t4, 0                           # Reset index for piece_offset array iteration
                li $t5, 4                           # reset total number of offsets in array     
            erase_current_piece_rotate:
                bge $t4, $t5, call_redraw_grid_rotate      # Check if we have gone through all offsets
                lw $t6, 0($s6)                      # Load current offset for piece
                add $t7, $t0, $t6                   # Calculate current pixel address
                sw $s2, 0($t7)                      # Set the current pixel to white

                addiu $s6, $s6, 4                   # Move to the next offset in the array
                addiu $t4, $t4, 1
                j erase_current_piece_rotate
            call_redraw_grid_rotate:
                jal redraw_grid                     # reset grid to erase old piece
                
                li $t4, 0                           # Reset index for piece_offset array iteration
                li $t5, 4                           # reset total number of offsets in array                  
            rotate_loop:
                bge $t4, $t5, end_rotate_loop       # Check if we have gone through all offsets
                lw $t6, 0($s0)                      # Load current offset for piece
                add $t7, $s5, $t6                   # Calculate new pixel address
                sw $s3, 0($t7)                      # Draw the piece at the new position
                # Move to the next offset in the array
                addiu $s0, $s0, 4
                addiu $t4, $t4, 1
                j rotate_loop
            end_rotate_loop: 
                # increment $s4 to save the piece current orientation
                addi $s4, $s4, 1                    # Increment the value in $s4 by 1
                andi $s4, $s4, 0x0003               # Use bitwise AND to ensure $s4 wraps back to 0 after reaching 4
                j rotation_complete
                
        rotation_complete:
            # increment current angle of rotation to match the new position
            b game_loop
                
    # Quit gracefully
    respond_to_Q:
    	li $v0, 10                      
    	syscall
            
generate_new_piece:
    # check if entire bottom row is full before generating, if it is move entire grid down
    # lw $s7, current_score           # curent score updates everytime full bottom row
    lw $t0, ADDR_DSPL
    li $t1, 964                    # bottom row start
    li $t2, 1004                    # bottom row end
    li $s6, 0                     # Initialize a counter for filled pixels
    check_full_row:
        bge $t1, $t2, row_check_complete
        add $t4, $t0, $t1                    # calculate the next pixel address
        lw $t9, 0($t4)                      # Load the current color of the next pixel
        
        beq $t9, $s1, continue_generating           # Check if the next pixel is not blue, if so check if it is white
        beq $t9, $s2, continue_generating           # Check if white
        addi $s6, $s6, 1
        addi $t1, $t1, 4
        j check_full_row                        # continue checking next pixel
        
    row_check_complete:
        # Calculate the number of pixels in the row to compare with $s6
        li $t5, 10                                # Number of pixels in the bottom row minus 1 (for zero-based counting)
        bne $s6, $t5, continue_generating         # If not all pixels are filled, continue generating without shifting
        addi $s7, $s7, 1                        # increment score
        sw $s7, current_score
        j update_score_remove_row                 # If all pixels are filled, proceed to update score and shift grid

    continue_generating:
    # randomly generate number between 0 and 6 to choose which piece to draw
    # each piece will have its unique coloaar stored in $s3
    # based on number chosen branch to draw_piece_ function
    li $v0, 42         # syscall service number for random number
    li $a0, 0          # Lower bound of the random number range
    li $a1, 7          # Upper bound - Lower bound + 1 (exclusive upper bound)
    syscall            # Generates a random number between 0 and (a1 - 1)
    
    beq $a0, 0, draw_piece_O
    beq $a0, 1, draw_piece_I
    beq $a0, 2, draw_piece_S
    beq $a0, 3, draw_piece_Z
    beq $a0, 4, draw_piece_L
    beq $a0, 5, draw_piece_J
    beq $a0, 6, draw_piece_T
    

update_score_remove_row:
    # remove bottom row and shift everything down by 1
    li $t1, 956                    # counter/pixel offset start
    shift_grid_down:
        beq $t1, 0, end_shift_grid_down
        add $t4, $t0, $t1                    # calculate the next pixel address
        lw $t9, 0($t4)                      # Load the current color of the next pixel
        
        addi $t4, $t4, 48                   # Calculate the address of the pixel directly below the current one
        sw $t9, 0($t4)                      # Store the color in the pixel below
        
        subi $t1, $t1, 4                   # Move to the previous pixel
        j shift_grid_down
    end_shift_grid_down:
    jal redraw_grid
    beq $s7, 1, draw_1
    beq $s7, 2, draw_2
    beq $s7, 3, draw_3
    beq $s7, 4, draw_4
    beq $s7, 5, draw_5

draw_1:
    lw $t0, ADDR_DSPL
    sw $t3, 1132($t0)
    sw $t3, 1180($t0)
    sw $t3, 1228($t0)
    sw $t3, 1276($t0)
    j continue_generating
draw_2:
    lw $t2, background_black
    sw $t2, 1132($t0)
    sw $t2, 1180($t0)
    sw $t2, 1228($t0)
    sw $t2, 1276($t0)
    
    lw $t0, ADDR_DSPL
    sw $t3, 1124($t0)
    sw $t3, 1128($t0)
    sw $t3, 1132($t0)
    sw $t3, 1180($t0)
    sw $t3, 1228($t0)
    sw $t3, 1224($t0)
    sw $t3, 1220($t0)
    sw $t3, 1268($t0)
    sw $t3, 1316($t0)
    sw $t3, 1320($t0)
    sw $t3, 1324($t0)
    j continue_generating
draw_3:
    lw $t2, background_black
    sw $t2, 1124($t0)
    sw $t2, 1128($t0)
    sw $t2, 1132($t0)
    sw $t2, 1180($t0)
    sw $t2, 1228($t0)
    sw $t2, 1224($t0)
    sw $t2, 1220($t0)
    sw $t2, 1268($t0)
    sw $t2, 1316($t0)
    sw $t2, 1320($t0)
    sw $t2, 1324($t0)
    
    lw $t0, ADDR_DSPL    
    sw $t3, 1124($t0)
    sw $t3, 1128($t0)
    sw $t3, 1132($t0)
    sw $t3, 1180($t0)
    sw $t3, 1228($t0)
    sw $t3, 1224($t0)
    sw $t3, 1220($t0)
    sw $t3, 1276($t0)
    sw $t3, 1316($t0)
    sw $t3, 1320($t0)
    sw $t3, 1324($t0)
    j continue_generating
draw_4:
    lw $t2, background_black
    sw $t2, 1124($t0)
    sw $t2, 1128($t0)
    sw $t2, 1132($t0)
    sw $t2, 1180($t0)
    sw $t2, 1228($t0)
    sw $t2, 1224($t0)
    sw $t2, 1220($t0)
    sw $t2, 1276($t0)
    sw $t2, 1316($t0)
    sw $t2, 1320($t0)
    sw $t2, 1324($t0)
    
    lw $t0, ADDR_DSPL 
    sw $t3, 1124($t0)
    sw $t3, 1132($t0)
    sw $t3, 1180($t0)
    sw $t3, 1228($t0)
    sw $t3, 1224($t0)
    sw $t3, 1220($t0)
    sw $t3, 1172($t0)
    sw $t3, 1276($t0)
    sw $t3, 1324($t0)
    j continue_generating
draw_5:
    lw $t2, background_black
    sw $t2, 1124($t0)
    sw $t2, 1132($t0)
    sw $t2, 1180($t0)
    sw $t2, 1228($t0)
    sw $t2, 1224($t0)
    sw $t2, 1220($t0)
    sw $t2, 1172($t0)
    sw $t2, 1276($t0)
    sw $t2, 1324($t0)
# draw GO - game over screen - G O
    sw $t3, 1120($t0)
    sw $t3, 1116($t0)
    sw $t3, 1112($t0)
    sw $t3, 1108($t0)
    sw $t3, 1156($t0)
    sw $t3, 1204($t0)
    sw $t3, 1252($t0)
    sw $t3, 1300($t0)
    sw $t3, 1304($t0)
    sw $t3, 1308($t0)
    sw $t3, 1312($t0)
    sw $t3, 1264($t0)
    sw $t3, 1216($t0)
    sw $t3, 1212($t0)
    
    sw $t3, 1132($t0)
    sw $t3, 1136($t0)
    sw $t3, 1140($t0)
    sw $t3, 1180($t0)
    sw $t3, 1188($t0)
    sw $t3, 1236($t0)
    sw $t3, 1228($t0)
    sw $t3, 1276($t0)
    sw $t3, 1284($t0)
    sw $t3, 1324($t0)
    sw $t3, 1328($t0)
    sw $t3, 1332($t0)
    b game_loop

respond_to_R:
    li $s7, 0
    sw $s7, current_score
    lw $t0, ADDR_DSPL
    li $t2, 1060
    li $t3, 1336
    lw $t9, background_black
    erase_score:
        beq $t2, $t3, end_erase_score
        add $t4, $t0, $t2                    # calculate the next pixel address
        sw $t9, 0($t4)
        addi $t2, $t2, 4
        j erase_score
    end_erase_score:
    j main

draw_piece_O:
    li $s4, 1               # Loads the current angle of rotation - 0:0, 1:90, 2:180, 3:270, since w has been pressed, angle is now 90
    lw $t0, ADDR_DSPL
    lw $s3, piece_color_yellow   # change pixel color to peice color
    sw $s3, 20($t0)
    sw $s3, 24($t0)
    sw $s3, 68($t0)
    sw $s3, 72($t0)
    # load offsets into array
    la $s0, piece_offsets
    # Manually set the offsets so we know how to adject them for movement
    li $t1, 20
    sw $t1, 0($s0)            # Set first offset
    li $t1, 24
    sw $t1, 4($s0)            # Set second offset
    li $t1, 68
    sw $t1, 8($s0)            # Set third offset
    li $t1, 72
    sw $t1, 12($s0)           # Set fourth offset
    b game_loop
    
draw_piece_I:
    li $s4, 1               # Loads the current angle of rotation - 0:0, 1:90, 2:180, 3:270, since w has been pressed, angle is now 90
    lw $t0, ADDR_DSPL
    lw $s3, piece_color_green   # change pixel color to peice color
    sw $s3, 24($t0)
    sw $s3, 72($t0)
    sw $s3, 120($t0)
    sw $s3, 168($t0)
    # load offsets into array
    la $s0, piece_offsets
    li $t1, 24
    sw $t1, 0($s0)            # Set first offset
    li $t1, 72
    sw $t1, 4($s0)            # Set second offset
    li $t1, 120
    sw $t1, 8($s0)            # Set third offset
    li $t1, 168
    sw $t1, 12($s0)           # Set fourth offset
    b game_loop
    
draw_piece_S:
    li $s4, 1               # Loads the current angle of rotation - 0:0, 1:90, 2:180, 3:270, since w has been pressed, angle is now 90
    lw $t0, ADDR_DSPL
    lw $s3, piece_color_red   # change pixel color to peice color
    sw $s3, 24($t0)
    sw $s3, 20($t0)
    sw $s3, 68($t0)
    sw $s3, 64($t0)
    # load offsets into array
    la $s0, piece_offsets
    li $t1, 24
    sw $t1, 0($s0)            # Set first offset
    li $t1, 20
    sw $t1, 4($s0)            # Set second offset
    li $t1, 68
    sw $t1, 8($s0)            # Set third offset
    li $t1, 64
    sw $t1, 12($s0)           # Set fourth offset
    b game_loop
    
draw_piece_Z:
    li $s4, 1               # Loads the current angle of rotation - 0:0, 1:90, 2:180, 3:270, since w has been pressed, angle is now 90
    lw $t0, ADDR_DSPL
    lw $s3, piece_color_indigo   # change pixel color to peice color
    sw $s3, 68($t0)
    sw $s3, 72($t0)
    sw $s3, 120($t0)
    sw $s3, 124($t0)
    # load offsets into array
    la $s0, piece_offsets
    li $t1, 68
    sw $t1, 0($s0)            # Set first offset
    li $t1, 72
    sw $t1, 4($s0)            # Set second offset
    li $t1, 120
    sw $t1, 8($s0)            # Set third offset
    li $t1, 124
    sw $t1, 12($s0)           # Set fourth offset
    b game_loop
    
draw_piece_L:
    li $s4, 1               # Loads the current angle of rotation - 0:0, 1:90, 2:180, 3:270, since w has been pressed, angle is now 90
    lw $s3, piece_color_orange   # change pixel color to peice color
    sw $s3, 20($t0)
    sw $s3, 68($t0)
    sw $s3, 116($t0)
    sw $s3, 120($t0)
    # load offsets into array
    la $s0, piece_offsets
    li $t1, 20
    sw $t1, 0($s0)            # Set first offset
    li $t1, 68
    sw $t1, 4($s0)            # Set second offset
    li $t1, 116
    sw $t1, 8($s0)            # Set third offset
    li $t1, 120
    sw $t1, 12($s0)           # Set fourth offset
    b game_loop
    
draw_piece_J:
    li $s4, 1               # Loads the current angle of rotation - 0:0, 1:90, 2:180, 3:270, since w has been pressed, angle is now 90
    lw $t0, ADDR_DSPL
    lw $s3, piece_color_purple   # change pixel color to peice color
    sw $s3, 24($t0)
    sw $s3, 72($t0)
    sw $s3, 120($t0)
    sw $s3, 116($t0)
    # load offsets into array
    la $s0, piece_offsets
    li $t1, 24
    sw $t1, 0($s0)            # Set first offset
    li $t1, 72
    sw $t1, 4($s0)            # Set second offset
    li $t1, 120
    sw $t1, 8($s0)            # Set third offset
    li $t1, 116
    sw $t1, 12($s0)           # Set fourth offset
    b game_loop

draw_piece_T:
    li $s4, 1               # Loads the current angle of rotation - 0:0, 1:90, 2:180, 3:270, since w has been pressed, angle is now 90
    lw $t0, ADDR_DSPL
    lw $s3, piece_color_brown   # change pixel color to peice color
    sw $s3, 16($t0)
    sw $s3, 20($t0)
    sw $s3, 24($t0)
    sw $s3, 68($t0)
    # load offsets into array
    la $s0, piece_offsets
    li $t1, 16
    sw $t1, 0($s0)            # Set first offset
    li $t1, 20
    sw $t1, 4($s0)            # Set second offset
    li $t1, 24
    sw $t1, 8($s0)            # Set third offset
    li $t1, 68
    sw $t1, 12($s0)           # Set fourth offset
    b game_loop

# This function handles redrawing the board between movements, pieces at the bottom should remain untouched 
# while the current piece and grid should be redrawn
redraw_grid:
    lw $t0, ADDR_DSPL
    # Draw grid pattern for rest of the board
        # $s1 = grid color 1 - light blue
        # $s2 = grid color 2 - white
        li $t1, 1000        # ending offset for grid
        li $t5, 0           # $t5 = switch color flag
        li $t2, 4           # $t2 = starting pixel offset - second pixel
        li $t9, 40          # $t9 = ending pixel offset - second last pixel 
    restart_grid_pattern:
        bgt $t2, $t1, reend_grid_pattern      # End loop when ending offset $t1 is reached
        add $t3, $t0, $t2                   # Add the base address and offset to get current pixel and store in register $t3
        lw $t4, 0($t3)                      # Load the current color at the pixel address to $t4               
        bne $t4, $s1, check_white           # Check if the current pixel is not blue, if so check if it is white
        check_white:
        bne $t4, $s2, redraw_continue        # Check if the current pixel is not white then jump to continue to offset is incresed and next pos checked
        # Alternate colors
        beqz $t5, redraw_first_color          # If $t5 is 0, draw the first color
        bne $t5, 0, redraw_second_color       # If $t5 is not 0 then second color is used
        
        redraw_first_color:
            sw $s1, 0($t3)                  # Store the first color at the calculated address $t3 - paint pixel blue
            j redraw_continue
        redraw_second_color:
            sw $s2, 0($t3)                  # Store the second color at the calculated address $t3 - paint pixel white
            
        redraw_continue:
            addi $t2, $t2, 4                # Increment the offset by 4
            bgt $t2, $t9, reend_line          # If the offset is greater than last pixel offset for the row, end line
            xor $t5, $t5, 1                 # Invert $t5 to alternate colors when not the last pixel in the row
            j restart_grid_pattern
        reend_line:
            addi $t9, $t9, 48               # Set the new end of row offset to be the previous one plus 48
            addi $t2, $t2, 8                # jump to next row by skipping two pixels for the border
            j restart_grid_pattern
    reend_grid_pattern:
    jr $ra
    
sort_offsets:
    li $t4, 3  # Number of elements in the array - 1, because we have 4 offsets (0 to 3)
        sort_loop_start:
            li $t5, 0  # Index for the inner loop
            li $t6, 0  # Flag to check if a swap happened
        inner_loop_start:
            sll $t0, $t5, 2        # Calculate memory offset for the current index
            add $t1, $s0, $t0      # $t1 now points to the current element in the array
            
            lw $t2, 0($t1)         # Load the current element
            lw $t3, 4($t1)         # Load the next element
        
            # Compare and possibly swap
            ble $t2, $t3, no_swap  # If current element <= next element, no swap needed
            
            # Swap elements
            sw $t2, 4($t1)         # Store the current element in the next element's place
            sw $t3, 0($t1)         # Store the next element in the current element's place
            li $t6, 1              # Set flag to indicate a swap happened
        no_swap:
            addi $t5, $t5, 1       # Increment inner loop index
            blt $t5, $t4, inner_loop_start # If not yet at the end, repeat inner loop
        
            # Check if we went through the entire array without swapping
            beq $t6, 0, sort_done  # If no swaps happened, array is sorted
            subi $t4, $t4, 1       # Decrease the range for the next iteration
            j sort_loop_start      # Repeat the sort process for the next outer loop iteration
        sort_done:
            jr $ra
