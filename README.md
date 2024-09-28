# Tetris
Classic Tetris game build using MIPS Assembly

Game Summary:
My game works by drawing the borders and background grid to start. Then it draws the starting piece and
saves it’s offset values in an array which can then be accessed and modified every time any movement occurs.
Within the game loop, keyboard input it checked and the appropriate function is called to handle the move.
Respond to A and Respond to D are fairly simple, checking if any of the next pixel positions are a color other
than the grid colors and if not then the current pixels are changed to white and redraw grid is called. Every
time a piece needs to be moved to a new position, it must be turned white before redraw grid is called because
this function will only redraw the grid with offset values that are already grid colors and skips over any pixels
of a different color, leaving previously placed pieces untouched. Once the current piece is erased the new one
is drawn using the updated offsets.
Respond to S is a bit more complicated as it must generate a new piece once it detects a collision. This is done
by branching to generate new piece once it finds that a pixel in the next position is not a grid color. Gravity
is implemented within this function as it calls itself over and over until the collision is detected. The speed
at which the piece moves down also progresses based on the current score. generate new piece works by first
checking for a full row, if one is found then the current score is erased, incremented, and redrawn in the space
below the grid. This current score value is saved throughout the program as it influences the gravity speed and
it only reset if the user presses R. Then a new piece is randomly generated at the top of the grid, each type
with it’s unique color.
Respond to W took me the most amount of time to implement and it also takes up most of the code base.
Since my implementation of the game is all based on saving the offsets of pieces and modifying them instead of
using a coordinate system it was definitely a challenge getting the rotations and its collision detection working
but I managed to implement it in a way that always works every possible case with the expense that there is
code for every possible case. It works by first checking what the current color saved in the color register s3 is
to identify which piece we are working with. Then it checks what the current rotation state is by checking s4
and using this information branches to the appropriate function that handles changing each offset of the piece
to the new one based on the piece and current rotation angle. Before each offset gets manipulated it is saved
to a previous offsets array in case there is a collision. If it is found that the the pixel at the new position is
already a different color other than grid colors, the current offsets will be reverted to previous offsets and the
function branches back to game loop.

Hard Features:
1) Implemented the full set of tetrominoes.
2) Tracks and displays the player’s score, which is based on how many lines have been completed so far. This
score is be displayed in pixels.
Easy Features:
1) Each tetromino type is a different colour.
2) When the player has reached the ”game over” condition, display a Game Over screen in pixels on the screen.
Restart the game if a “retry” option is chosen by the player. Retry should start a brand new game (no state
is retained from previous attempts).
3) Implement gravity, so that each second that passes will automatically move the tetromino down one row.
4) Have the speed of gravity increase gradually over time, or after the player completes a certain number of
rows

How to view the game:
(a) Set the display width to 120 and the height to 220.
(b) Set the units for width is 10 and for height it is 8.
(c) Run the code. Press Q to end the game at any point and press R to reset the game.
