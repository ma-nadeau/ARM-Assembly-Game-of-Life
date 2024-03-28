
.global _start

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


MAXIMUM_X_INDEX_PIXEL_REGISTER = 319
MAXIMUM_Y_INDEX_PIXEL_REGISTER = 239


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


_start:
    setup:
        BL GoL_draw_grid_ASM
    
    game:
    	B game
