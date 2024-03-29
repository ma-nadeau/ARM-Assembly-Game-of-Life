
.global _start
.equ PS2_Data_Address, 0xff200100

// contains the color value of every pixel on the screen 
// 16-bit integers => 15...11 -> Red || 10...5 -> Green || 4...0 -> Blue
// Individual pixel colors can be accessed at 0xc8000000 | (y << 10) | (x << 1)
// where x and y are valid x and y coordinates on the screen (i.e., 0 ≤ x < 320, and 0 ≤ y < 240).
PIXEL_BUFFER_ADDR = 0xc8000000          



// The character buffer itself is a buffer of byte-sized ASCII characters at 0xc9000000. 
// The buffer has a width of 80 characters and a height of 60 characters. 
// An individual character can be accessed at 0xc9000000 | (y << 7) | x.
CHARACTER_BUFFER_ADDR = 0xc9000000



currentLineColour = 0x0             // Used to colour the lines
currentBackGroundColour = -368140053
currentRectangleColour = 1717986919 //green
white_cursor = -1
grey_cursor = -2139062144


MAXIMUM_X_INDEX_PIXEL_REGISTER = 319
MAXIMUM_Y_INDEX_PIXEL_REGISTER = 239

//starting game board (from lab doc)
GoLBoard:
	//  x 0 1 2 3 4 5 6 7 8 9 a b c d e f    y
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 0
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 1
	.word 0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0 // 2
	.word 0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0 // 3
	.word 0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0 // 4
	.word 0,0,0,0,0,0,0,1,1,1,1,1,0,0,0,0 // 5
	.word 0,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0 // 6
	.word 0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0 // 7
	.word 0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0 // 8
	.word 0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0 // 9
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // a
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // b

COLOR_SELECTOR: .word 1
KEYBOARD_VALUE: .word 0
CURRENT_CURSOR_X: .word 0
CURRENT_CURSOR_Y: .word 0

//
// PS2 DRIVER
//
@ TODO: insert PS/2 driver here.
//assuming A1 is the address where we ant to store the keyboard value (input)
//assuming A2 is the return (1 or 0)
read_PS2_data_ASM:
	PUSH {V1-V5, LR}
	LDR V1, =PS2_Data_Address //V1 has the value of the PS2 Data Address
	LDR V2, [V1] //V2 has the content from PS2_Data register
	MOV V3, V2 //copy The content so we can shift V3 by 15 to get the value of RVALID
	LSR V3, V3, #15 //logical shift right 15 to get RVALID
	AND V3, V3, #0x1 //And operation to get RVALID bit value (1 or 0)
	CMP V3, #1 //compare and see if its 1
	BNE dont_read //if its 0, we dont read and set return to 0
	AND V2, V2, #0xFF //if its 1, we get only the low eight bits
	STRB V2, [A1] //store this byte in the memory location put as input
    MOV A2, #1
	B exit_read_ps2_data
dont_read:
	MOV A2, #0 //if we dont read, return 0
exit_read_ps2_data:
	POP {V1-V5, LR}
	BX LR
	


// void VGA_draw_point_ASM(int x, int y, short c);
// draws a point on the screen at the specified (x, y) coordinates in the indicated color c
// A1 <- x  A2 <- y  A3 <- c
VGA_draw_point_ASM: 
    PUSH {V1-V2, LR}

    // INPUT VALIDATION
    MOV V1, #0                      // To compare 

    CMP A1, V1                      // Check if X >= 0
    BLT out_of_range_pixelbuff      // if X < 0, (i.e not in range) stop
    CMP A2, V1                      // Check if y >=0 
    BLT out_of_range_pixelbuff      // if Y < 0, (i.e not in range) stop

    LDR V1, =319                    // V1 <- 319, overides the 0 in V1

    CMP A1, V1                      // Check if X > 319
    BGT out_of_range_pixelbuff      // if X > 319, (i.e not in range) stop

    MOV V1, #239                    // V1 <- 239, overides the 0 in V1

    CMP A2, V1                      // Check if Y > 319
    BGT out_of_range_pixelbuff      // if X > 239, (i.e not in range) stop
    
    LDR V2, =PIXEL_BUFFER_ADDR      // V1 <- address of pixel buffer

    LSL A1, A1, #1                  // Compute Coordinate of X ( x << 1 )
    LSL A2, A2, #10                 // Compute Coordinate of Y ( y << 10 )

    ADD V2, V2, A1                  // Addr + X 
    ADD V2, V2, A2                  // (Addr + X) + Y (i.e. coordinate to write to)

    STRH A3, [V2]                   // Store Colour at computed addres

    out_of_range_pixelbuff:  
        POP {V1-V2, LR}
        BX LR

// void VGA_clear_pixelbuff_ASM();
// clears (sets to 0) all the valid memory locations in the pixel buffer. It takes no arguments and returns nothing.
VGA_clear_pixelbuff_ASM:
    PUSH {V1-V7, LR}

    LDR V1, =319                    // Outer Loop Max
    LDR V2, =239                    // Inner Loop Max
    MOV V3, #0                      // counter for outer loop (X coor or i)
    MOV V4, #0                      // counter for outer loop (Y coor or j)
    

    outer_loop_pixelbuff: 
        inner_loop_pixelbuff:

            MOV A1, V3              // X Index to be cleared
            MOV A2, V4              // Y Index to be cleared
            MOV A3, #0              // Colour with value 0
            BL VGA_draw_point_ASM   // Calling subroutine to clear

            ADD V4, V4, #1          // j++
            CMP V4, V2              // Compare j with 239
            BLE inner_loop_pixelbuff// if j <= 239, loop back to inner loop

		MOV V4, #0                  // reset counter for outer loop (Y coor or j)
        ADD V3, V3, #1              // i++
        CMP V3, V1                  // Compare i with 319 
        BLE outer_loop_pixelbuff    // if i <= 239, loop back to outer loop
    
    POP {V1-V7, LR}
    BX LR

// void Set_VGA_BackGroundColour_pixelbuff_ASM(Colour C);
// clears (sets to c_ all the valid memory locations in the pixel buffer. It takes no arguments and returns nothing.
// TODO: Do we want a constant for colour of an input?
Set_VGA_BackGroundColour_pixelbuff_ASM:

    PUSH {V1-V7, LR}

    LDR V1, =319                        // Outer Loop Max
    LDR V2, =239                        // Inner Loop Max
    MOV V3, #0                          // counter for outer loop (X coor or i)
    MOV V4, #0                          // counter for outer loop (Y coor or j)
    LDR A3, =currentBackGroundColour    // Colour to set the background to    

    outer_loop_pixel_BackGroundColou: 
        inner_loop_pixel_BackGroundColou:

            MOV A1, V3              // X Index to be cleared
            MOV A2, V4              // Y Index to be cleared
            BL VGA_draw_point_ASM   // Calling subroutine to clear

            ADD V4, V4, #1          // j++
            CMP V4, V2              // Compare j with 239
            BLE inner_loop_pixel_BackGroundColou// if j <= 239, loop back to inner loop

		MOV V4, #0                  // reset counter for outer loop (Y coor or j)
        ADD V3, V3, #1              // i++
        CMP V3, V1                  // Compare i with 319 
        BLE outer_loop_pixel_BackGroundColou   // if i <= 239, loop back to outer loop
    
    POP {V1-V7, LR}
    BX LR

// This subroutine draws the horizontal lines - From A1 to A4 at height A2 in colour A3
// A1 <- X1 (lower bound), A2 <- y (heigth), A3 <- Colour, A4 <- X2 (upperbound)
VGA_draw_line_ASM_horizontal:
    PUSH {LR}
    loop_line_horizontal:

		PUSH {A1-A4, LR}
        BL VGA_draw_point_ASM   // Calling subroutine to clear            
        POP {A1-A4, LR}
		ADD A1, A1, #1          // j++
        CMP A1, A4              // Compare j with 239
        BLE loop_line_horizontal  // if j <= 239, loop back to inner loop

     POP {LR}
     BX LR

// This subroutine draws the vertical lines - From A2 to A4 at distance A1 in colour A3
// A1 <- X (constant), A2 <- y (starting height), A3 <- Colour, A4 <- y2 (starting height)
VGA_draw_line_ASM_vertical:
    PUSH {LR}
    loop_line_vertical:

		PUSH {A1-A4, LR}
        BL VGA_draw_point_ASM   // Calling subroutine to clear            
        POP {A1-A4, LR}
		ADD A2, A2, #1          // j++
        CMP A2, A4              // Compare j with 239
        BLE loop_line_vertical  // if j <= 239, loop back to inner loop
   
     POP {LR}
     BX LR

// This subroutine takes in 4 coordiates and draws a line according to these coordinates in constant colour set in memory at =currentLineColour
// A1 <- X1 A2 <- X2 A3 <- Y1  A4 <- Y2
VGA_draw_line_ASM:
    PUSH {LR}

    // INPUT Validation                     //TODO: might want to implement this differently
    CMP A1, A2                              // Check for X1 > X2
    BGT end_draw_line

    CMP A3, A4                              // Check if  Y1 > Y2
    BGT end_draw_line

    // Vertical Drawing
    CMP A1, A2                              // Compare X1 and X2
    BNE check_vertical                      // Compare Y1 and Y2, when X1 != X2
     
    MOVEQ A2, A3                            // A2 <- A3 (Y1)  -> Essentially overrinding the value of A2 (X2) with the starting height (y1)
    LDREQ A3, =currentLineColour            // Get line colour and place it to A3
    BLEQ VGA_draw_line_ASM_vertical         // write line | A1 <- X (constant), A2 <- y1 (starting height), A3 <- Colour, A4 <- y2 (starting height)
    BEQ end_draw_line                       // branch to end when done

    // Horizontal Drawing
    check_vertical:
        CMP A3, A4                          
        BNE end_draw_line 
		
		MOVEQ A4, A2                            // A4 <- A2 (Y1) -> Essentially overiding y2 in A4 and setting the upper bound of the line 
        MOVEQ A2, A3                            // A2 <- A3  -> Essentially Setting the value of A2 with a constant height
        LDREQ A3, =currentLineColour            // Get line colour and place it to A3
        BLEQ VGA_draw_line_ASM_horizontal       // write line || A1 <- X1 (lower bound), A2 <- y (heigth), A3 <- Colour, A4 <- X2 (upperbound)
        
    end_draw_line:
        POP {LR}
        BX LR

    // TODO: THERE'S a BUG WITH THIS ONE it won't draw past the second line
    VGA_draw_ASM_Horizontal_Grid:
    
        PUSH {V1-V4, LR}
        LDR A1, =0                                          // A1 <- 0 : min index of X 
		LDR A2, =MAXIMUM_X_INDEX_PIXEL_REGISTER             // A2 <- MAX X
        LDR A3, =0                                          // Starts at 0
		MOV A4, A3                                          // Constants
        LDR V1, =MAXIMUM_Y_INDEX_PIXEL_REGISTER
        MOV V2, A3
        loop_Horizontal_Grid:
            MOV A1, #0 
            LDR A2, =MAXIMUM_X_INDEX_PIXEL_REGISTER
            BL VGA_draw_line_ASM
            ADD V2, V2, #20                  // Increase by 20 to draw next line
            MOV A3, V2
		    MOV A4, A3                      // Make A3 and A4 equal (only for subroutine call to work properly)
            CMP A3, V1 
            BLE loop_Horizontal_Grid

        // TODO: Find out why i need to do in order to write the last line 
        MOV A1, #0 
        LDR A2, =MAXIMUM_X_INDEX_PIXEL_REGISTER
        MOV A3, V1                  // A1 <- =MAXIMUM_X_INDEX_PIXEL_REGISTER
		MOV A4, A3                  // A2 <- A1
        BL VGA_draw_line_ASM
        POP {V1-V4, LR}
        BX LR
    
    
    VGA_draw_ASM_Vertical_Grid:
    
        PUSH {V1, LR}
        LDR A1, =0                  // 
		MOV A2, A1                  // 
        LDR A3, =0                  // Constants
		LDR A4, =239                // Constants
        LDR V1, =MAXIMUM_X_INDEX_PIXEL_REGISTER
        loop_Vertical_Grid:
            BL VGA_draw_line_ASM
            ADD A1,A1, #20                  // Increase by 20 to draw next line
		    MOV A2, A1                      // Make A1 and A2 equal (only for subroutine call to work properly)
            CMP A1, V1 
            BLE loop_Vertical_Grid

        // TODO: Find out why i need to do in order to write the last line 
        MOV A1, V1                  // A1 <- =MAXIMUM_X_INDEX_PIXEL_REGISTER
		MOV A2, A1                  // A2 <- A1
        BL VGA_draw_line_ASM
        POP {V1, LR}
        BX LR


// Draws a 16x12 grid
GoL_draw_grid_ASM:
    PUSH {LR}

    BL Set_VGA_BackGroundColour_pixelbuff_ASM
    BL VGA_draw_ASM_Vertical_Grid
    BL VGA_draw_ASM_Horizontal_Grid

    POP {LR}
    BX LR


// Calls VGA_draw_point_ASM and fills in the rectangle in (x1,y1) to (x2, y2)
// A1 <- X1, A2 <- X2, A3 <- Y1, A4 <- Y2
VGA_draw_rect_ASM:

    PUSH {V1-V7, LR}

    // INPUT Validation                     //TODO: might want to implement this differently
    CMP A1, A2                              // Check for X1 > X2
    BGT end_draw_rec

    CMP A3, A4                              // Check if  Y1 > Y2
    BGT end_draw_rec


    MOV V1, A2                          // Outer Loop Max
    MOV V2, A4                          // Inner Loop Max
    MOV V3, A1                          // counter for outer loop (X coor or i)
    MOV V4, A3                          // counter for outer loop (Y coor or j)
    MOV V6, A3

    LDR V7, COLOR_SELECTOR
    CMP V7, #0
    BLEQ set_green
    CMP V7, #1
    BLEQ set_white
    CMP V7, #2
    BLEQ set_grey
    CMP V7, #3
    BLEQ set_background


    //LDR A3, =currentRectangleColour     // Colour to set the background to    

    outer_loop_pixel_draw_rec: 
        inner_loop_pixel_draw_rec:

            MOV A1, V3                    // X Index to be cleared
            MOV A2, V4                    // Y Index to be cleared
            BL VGA_draw_point_ASM         // Calling subroutine to clear

            ADD V4, V4, #1                // j++
            CMP V4, V2                    // Compare j with 239
            BLE inner_loop_pixel_draw_rec // if j <= 239, loop back to inner loop

		MOV V4, V6                        // reset counter for outer loop (Y coor or j)
        ADD V3, V3, #1                    // i++
        CMP V3, V1                        // Compare i with 319 
        BLE outer_loop_pixel_draw_rec     // if i <= 239, loop back to outer loop
    end_draw_rec:
        POP {V1-V7, LR}
        BX LR
    
// fills the area of grid location (x, y) with color c.
set_green:
    LDR A3, =currentRectangleColour // Colour to set the background to    
    BX LR
set_white:
    LDR A3, =white_cursor // Colour to set the background to    
    BX LR
set_grey:
    LDR A3, =grey_cursor // Colour to set the background to    
    BX LR
set_background:
    LDR A3, =currentBackGroundColour // Colour to set the background to    
    BX LR

// A1 <- X,  A2 <- Y
GoL_fill_gridxy_ASM:
    PUSH {V1-V7,LR}

    // INPUT VALIDATION
    MOV V1, #0                          // To compare 

    CMP A1, V1                          // Check if X >= 0
    BLT out_of_range_fill_gridxy        // if X < 0, (i.e not in range) stop
    CMP A2, V1                          // Check if y >=0 
    BLT out_of_range_fill_gridxy        // if Y < 0, (i.e not in range) stop

    LDR V1, =16                         // V1 <- 16, overides the 0 in V1

    CMP A1, V1                          // Check if X >= 12
    BGE out_of_range_fill_gridxy        // if X >= 16, (i.e not in range) stop

    MOV V1, #12                         // V1 <- 12, overides the 0 in V1

    CMP A2, V1                          // Check if Y > 12
    BGE out_of_range_fill_gridxy        // if Y >= 12, (i.e not in range) stop

    MOV V2, #20
    MUL A1, A1, V2                     // A1 <- Updated/Pixel-wise X index of rect 
    ADD A1, A1, #1
    MUL A3, A2, V2                     // A3 <- Updated/Pixel-wise X index of rect 
    ADD A3, A3, #1                     
    
    MOV V2, #18
    ADD A2, A1, V2                      // Index of X + 20 
    ADD A4, A3, V2                      // Index of Y + 20

    BL VGA_draw_rect_ASM
    
    out_of_range_fill_gridxy:
        POP {V1-V7, LR}
        BX LR


GoL_draw_board_ASM:
	PUSH {V1-V8, LR}
	LDR V1, =GoLBoard //V1 has the base address of the base display values
	MOV V5, V1 //V5 serves to keep track of address vertically 
	MOV V2, #0 //V2 is the x value (increases by 1 each time)
	MOV V3, #0 //V3 is the y value (invreases by 1 when x goes past 15)
	B handle_initial_drawing
	

handle_initial_drawing:
	
    //checking if valid 
    PUSH {LR}
	LDR V4, [V1] //load golboard[x][y] into V4
	CMP V4, #1 //check if its equal to 1
	MOV A1, V2
	MOV A2, V3 //move x and y values into A1 and A2 (inputs for the function if we call it)
    LDR V8, =COLOR_SELECTOR
    MOV V7, #0 //set color to 0 which is green
    STR V7, [V8]
	BLEQ GoL_fill_gridxy_ASM //branch and link if equal to 1, draw the block
	POP {LR}
    

	ADD V2, V2, #1 //x+1
	ADD V1, V1, #4 //increment address to go to the next x value
	CMP V2, #16
	BGE reset_x //if x is 16 then we need to reset it to 0 (reached the last column), and increase y
	
	B handle_initial_drawing
	
	
reset_x:
	MOV V2, #0 //reset x to 0
	ADD V3, #1 //increase y by 1 because we are on a new row
	ADD V5, V5, #64 //set V5 to the beginning of the next row
	MOV V1, V5 //set V1 to base address of the current row (so we can go through the x addresses)
	CMP V3, #12 //if y is 12 we are done
	BGE final_exit

    B handle_initial_drawing
	
final_exit:
	POP {V1-V8, LR}
	BX LR
	
set_initial_cursor:
    PUSH {V1-V8, LR}
    LDR A1, CURRENT_CURSOR_X
    LDR A2, CURRENT_CURSOR_Y
    LDR V8, =COLOR_SELECTOR
    MOV V7, #1 //set color to 1 which is white
    STR V7, [V8]
	BL GoL_fill_gridxy_ASM
    POP {V1-V8, LR}
    BX LR
	
curser_polling:
    PUSH {V1-V8, LR}
    LDR A1, =KEYBOARD_VALUE //A1 is the keyboard value address 
    BL read_PS2_data_ASM //sets a2
    CMP A2, #1 //if A2 is 1, we need to analyse the new input
    BEQ analyse_curser
    B end_curser_polling

analyse_curser:
    LDR V2, CURRENT_CURSOR_X
    LDR V3, CURRENT_CURSOR_Y //current y and x location

    LDR V1, KEYBOARD_VALUE //v1 has the make value
    CMP V1, #0x1C //a
    BEQ handle_A
    CMP V1, #0x23 //d
    BEQ handle_D
    CMP V1, #0x1B
    BEQ handle_S
    CMP V1, #0x1D  //W
    BEQ handle_W
    B end_curser_polling

handle_A:
    CMP V2, #0
    BEQ end_curser_polling //if X is 0, dont do anything (cant go outside border)

    BL handle_prev_cursor_removal

    SUB V2, V2, #1
    LDR V3, =CURRENT_CURSOR_X
    STR V2, [V3]
    B end_curser_polling
handle_D:
    CMP V2, #15
    BEQ end_curser_polling //if X is 15, dont do anything (cant go outside border)

    BL handle_prev_cursor_removal

    ADD V2, V2, #1
    LDR V3, =CURRENT_CURSOR_X
    STR V2, [V3]
    B end_curser_polling
handle_S:
    CMP V3, #11
    BEQ end_curser_polling //if Y is 11, dont do anything (cant go outside border)
    BL handle_prev_cursor_removal

    ADD V3, V3, #1
    LDR V2, =CURRENT_CURSOR_Y
    STR V3, [V2]
    B end_curser_polling

handle_W:
    CMP V3, #0
    BEQ end_curser_polling //if Y is 0, dont do anything (cant go outside border)
    BL handle_prev_cursor_removal

    SUB V3, V3, #1
    LDR V2, =CURRENT_CURSOR_Y
    STR V3, [V2]
    B end_curser_polling

handle_prev_cursor_removal:
    PUSH {V1-V8, LR}
    MOV A1, V2
	MOV A2, V3 //move x and y values into A1 and A2 (inputs for the function)
    LDR V8, =COLOR_SELECTOR
    MOV V7, #3 //set color to 0 which is pink backround
    STR V7, [V8]
    
	BL GoL_fill_gridxy_ASM //branch and link if equal to 1, draw the block
    POP {V1-V8, LR}
    BX LR

end_curser_polling:
    POP {V1-V8, LR}
    BX LR
	
_start:
    setup:
        BL GoL_draw_grid_ASM
        BL GoL_draw_board_ASM

        //BL set_initial_cursor
    
    game:
        //MOV A1, #15
        //MOV A2, #6    
        BL set_initial_cursor
        BL curser_polling
    	B game