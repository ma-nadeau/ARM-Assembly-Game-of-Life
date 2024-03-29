// Authors: Marc-Antoine Nadeau - 261114549
//          Rehean Thillainathalingam - 261116121


// contains the color value of every pixel on the screen 
// // 16-bit integers => 15...11 -> Red || 10...5 -> Green || 4...0 -> Blue
// Individual pixel colors can be accessed at 0xc8000000 | (y << 10) | (x << 1)
// where x and y are valid x and y coordinates on the screen (i.e., 0 ≤ x < 320, and 0 ≤ y < 240).
PIXEL_BUFFER_ADDR = 0xc8000000          



// The character buffer itself is a buffer of byte-sized ASCII characters at 0xc9000000. 
// The buffer has a width of 80 characters and a height of 60 characters. 
// An individual character can be accessed at 0xc9000000 | (y << 7) | x.
CHARACTER_BUFFER_ADDR = 0xc9000000

.global _start
.equ PS2_Data_Address, 0xff200100


_start:
        bl      input_loop
end:
        b       end
//
//VGA DRIVER
//
@ TODO: copy VGA driver here.
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

// Writes the ASCII code c to the screen at (x, y). 
// The subroutine should check that the coordinates supplied are valid, i.e., x in [0, 79] and y in [0, 59].
// A1 <- x  A2 <- y  A3 <- c
VGA_write_char_ASM: 

    PUSH {V1-V2, LR}

    // INPUT VALIDATION
    MOV V1, #0                      // To compare 

    CMP A1, V1                      // Check if X >= 0
    BLT out_of_range_charbuff       // if X < 0, (i.e not in range) stop
    CMP A2, V1                      // Check if y >=0 
    BLT out_of_range_charbuff       // if Y < 0, (i.e not in range) stop

    LDR V1, =79                     // V1 <- 79, overides the 0 in V1

    CMP A1, V1                      // Check if X > 79
    BGT out_of_range_charbuff       // if X > 79, (i.e not in range) stop

    MOV V1, #59                     // V1 <- 59, overides the 79 in V1

    CMP A2, V1                      // Check if Y > 59
    BGT out_of_range_charbuff       // if X > 59, (i.e not in range) stop
    
    LDR V2, =CHARACTER_BUFFER_ADDR  // V1 <- address of pixel buffer

    LSL A2, A2, #7                  // Compute Coordinate of Y (y << 7)

    ADD V2, V2, A1                  // Addr + X 
    ADD V2, V2, A2                  // (Addr + X) + Y  (i.e. coordinate to write to)

    STRB A3, [V2]                   // Writes ASCII code c to screen at (X,Y)

    out_of_range_charbuff:  
        POP {V1-V2, LR}
        BX LR

// clears (sets to 0) all the valid memory locations in the character buffer.
// void VGA_clear_charbuff_ASM();
VGA_clear_charbuff_ASM: 

    PUSH {V1-V7, LR}

    LDR V1, =79                     // Outer Loop Max
    LDR V2, =59                     // Inner Loop Max
    MOV V3, #0                      // counter for outer loop (X coor or i)
    MOV V4, #0                      // counter for outer loop (Y coor or j)
    
    outer_loop_charbuff: 
        inner_loop_charbuff:

            MOV A1, V3              // X Index to be cleared
            MOV A2, V4              // Y Index to be cleared
            MOV A3, #0              // Colour with value 0
            BL VGA_draw_point_ASM   // Calling subroutine to clear

            ADD V4, V4, #1          // j++
            CMP V4, V2              // Compare j with 239
            BLE inner_loop_charbuff // if j <= 239, loop back to inner loop

		MOV V4, #0                  // reset counter for outer loop (Y coor or j)
        ADD V3, V3, #1              // i++
        CMP V3, V1                  // Compare i with 319 
        BLE outer_loop_charbuff     // if i <= 239, loop back to outer loop
    
    POP {V1-V7, LR}
    BX LR

//
// VGA DRIVER END
//


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
	B exit_read_ps2_data
dont_read:
	MOV A2, #0 //if we dont read, return 0
exit_read_ps2_data:
	POP {V1-V5, LR}
	BX LR
	

//
// PS2 DRIVER END
//
	
	
write_hex_digit:
        push    {r4, lr}
        cmp     r2, #9
        addhi   r2, r2, #55
        addls   r2, r2, #48
        and     r2, r2, #255
        bl      VGA_write_char_ASM
        pop     {r4, pc}
write_byte:
        push    {r4, r5, r6, lr}
        mov     r5, r0
        mov     r6, r1
        mov     r4, r2
        lsr     r2, r2, #4
        bl      write_hex_digit
        and     r2, r4, #15
        mov     r1, r6
        add     r0, r5, #1
        bl      write_hex_digit
        pop     {r4, r5, r6, pc}
input_loop:
        push    {r4, r5, lr}
        sub     sp, sp, #12
        bl      VGA_clear_pixelbuff_ASM
        bl      VGA_clear_charbuff_ASM
        mov     r4, #0
        mov     r5, r4
        b       .input_loop_L9
.input_loop_L13:
        ldrb    r2, [sp, #7]
        mov     r1, r4
        mov     r0, r5
        bl      write_byte
        add     r5, r5, #3
        cmp     r5, #79
        addgt   r4, r4, #1
        movgt   r5, #0
.input_loop_L8:
        cmp     r4, #59
        bgt     .input_loop_L12
.input_loop_L9:
        add     r0, sp, #7
        bl      read_PS2_data_ASM
        cmp     r0, #0
        beq     .input_loop_L8
        b       .input_loop_L13
.input_loop_L12:
        add     sp, sp, #12
        pop     {r4, r5, pc}