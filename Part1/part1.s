// Authors: Marc-Antoine Nadeau - 261114549
//          Rehean Thillainathalingam - 261116121

.global _start

// contains the color value of every pixel on the screen 
// // 16-bit integers => 15...11 -> Red || 10...5 -> Green || 4...0 -> Blue
// Individual pixel colors can be accessed at 0xc8000000 | (y << 10) | (x << 1)
// where x and y are valid x and y coordinates on the screen (i.e., 0 ≤ x < 320, and 0 ≤ y < 240).
PIXEL_BUFFER_ADDR = 0xc8000000          



// The character buffer itself is a buffer of byte-sized ASCII characters at 0xc9000000. 
// The buffer has a width of 80 characters and a height of 60 characters. 
// An individual character can be accessed at 0xc9000000 | (y << 7) | x.
CHARACTER_BUFFER_ADDR = 0xc9000000


_start:
        bl      draw_test_screen
end:
        b       end
@ TODO: Insert VGA driver functions here.

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
            BL VGA_write_char_ASM   // Calling subroutine to clear

            ADD V4, V4, #1          // j++
            CMP V4, V2              // Compare j with 239
            BLE inner_loop_charbuff // if j <= 239, loop back to inner loop

		MOV V4, #0                  // reset counter for outer loop (Y coor or j)
        ADD V3, V3, #1              // i++
        CMP V3, V1                  // Compare i with 319 
        BLE outer_loop_charbuff     // if i <= 239, loop back to outer loop
    
    POP {V1-V7, LR}
    BX LR


draw_test_screen:
        push    {r4, r5, r6, r7, r8, r9, r10, lr}
        bl      VGA_clear_pixelbuff_ASM
        bl      VGA_clear_charbuff_ASM
        mov     r6, #0
        ldr     r10, .draw_test_screen_L8
        ldr     r9, .draw_test_screen_L8+4
        ldr     r8, .draw_test_screen_L8+8
        b       .draw_test_screen_L2
.draw_test_screen_L7:
        add     r6, r6, #1
        cmp     r6, #320
        beq     .draw_test_screen_L4
.draw_test_screen_L2:
        smull   r3, r7, r10, r6
        asr     r3, r6, #31
        rsb     r7, r3, r7, asr #2
        lsl     r7, r7, #5
        lsl     r5, r6, #5
        mov     r4, #0
.draw_test_screen_L3:
        smull   r3, r2, r9, r5
        add     r3, r2, r5
        asr     r2, r5, #31
        rsb     r2, r2, r3, asr #9
        orr     r2, r7, r2, lsl #11
        lsl     r3, r4, #5
        smull   r0, r1, r8, r3
        add     r1, r1, r3
        asr     r3, r3, #31
        rsb     r3, r3, r1, asr #7
        orr     r2, r2, r3
        mov     r1, r4
        mov     r0, r6
        bl      VGA_draw_point_ASM
        add     r4, r4, #1
        add     r5, r5, #32
        cmp     r4, #240
        bne     .draw_test_screen_L3
        b       .draw_test_screen_L7
.draw_test_screen_L4:
        mov     r2, #72
        mov     r1, #5
        mov     r0, #20
        bl      VGA_write_char_ASM
        mov     r2, #101
        mov     r1, #5
        mov     r0, #21
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #22
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #23
        bl      VGA_write_char_ASM
        mov     r2, #111
        mov     r1, #5
        mov     r0, #24
        bl      VGA_write_char_ASM
        mov     r2, #32
        mov     r1, #5
        mov     r0, #25
        bl      VGA_write_char_ASM
        mov     r2, #87
        mov     r1, #5
        mov     r0, #26
        bl      VGA_write_char_ASM
        mov     r2, #111
        mov     r1, #5
        mov     r0, #27
        bl      VGA_write_char_ASM
        mov     r2, #114
        mov     r1, #5
        mov     r0, #28
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #29
        bl      VGA_write_char_ASM
        mov     r2, #100
        mov     r1, #5
        mov     r0, #30
        bl      VGA_write_char_ASM
        mov     r2, #33
        mov     r1, #5
        mov     r0, #31
        bl      VGA_write_char_ASM
        pop     {r4, r5, r6, r7, r8, r9, r10, pc}
.draw_test_screen_L8:
        .word   1717986919
        .word   -368140053
        .word   -2004318071