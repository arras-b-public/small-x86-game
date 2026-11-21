.286
.model small
.stack 100h
.data
	ID db "123456789$"						; Default value: "123456789" -- ID for game version
	ball_x dw 160	 						; Default value: 160
	ball_y dw 144	 						; Default value: 144
	ball_x_vel dw 0	 						; Default value: 0
	ball_y_vel dw -1 						; Default value: -1 
	paddle_x dw 144  						; Default value: 144
	paddle_length dw 32 					; Default value: 32
	black dw 00h 							; Default value: 0x00 (black)
	ball_color dw 0Fh 						; Default value: 0x0F (white)
	left_paddle_color dw 2Ch  				; Default value: 0x2C (yellow)
	middle_paddle_color dw 2Dh  			; Default value: 0x2D (bright lime)
	right_paddle_color dw 2Eh 				; Default value: 0x2E (bright green)
	available_score dw 0 					; Default value: 0 -> current score that can be used towards a power up  
	previous_iteration_score dw 0  			; Default value: 0 -> score of the last iteration
	score_for_power_ups dw 50				; Default value: 50
	counter_power_up_one dw 600 			; Default value: 600 
	draw_laser dw 0 						; Default value: 0 -> boolean for if we should draw pixel laser
	laser_x dw 0   							; Default value: 0
	laser_y dw 183   						; Default value: 183



.code

; get the functions from the util_br.obj file (needs to be linked)
EXTRN setupGame:PROC, drawBricks:PROC, checkBrickCollision:PROC, sleep:PROC, decreaseLives:PROC, getScore:PROC, clearPaddleZone:PROC


drawPixel:									; void drawPixel(color, x, y)
											; draws a pixel to the screen. 
											; !HARD CODED TO MODE 13H!
											; inputs:
											; color	: hex code of the pixel's color (8 bits)
											; x  	: x position of the pixel
											; y  	: y position of the pixel
											; returns:
											; none, prints to the screen
	color EQU ss:[bp+4]
	x EQU ss:[bp+6]
	y EQU ss:[bp+8]

	push bp
	mov bp, sp

	push ax
	push bx
	push cx
	push dx 
	push es

	; set ES to be the base address
	mov ax, 0A000h			
	mov es, ax

	; EX = (y * 320) + x
	mov bx, x
	mov cx, 320
	mov ax, y
	mul cx									; ax = 320 * y
	add bx, ax								; bx = ax + x


	mov dx, color							; color is only byte, relevant data is in dl

	mov BYTE PTR es:[bx], dl 				; move color into correct location in buffer


	; restore the stack
	pop es
	pop dx 
	pop cx
	pop bx
	pop ax
	pop bp

	ret 6  									; exit the function


drawLine:									; void drawLine(color, x1, x2, y1, y2)
											; draws a line to the screen. 
											; ! HARD CODED TO MODE 13H!
											; inputs:
											; color	: hex code of the pixel's color (8 bits)
											; x1  	: start x position of the pixel
											; x2  	: end x position of the pixel
											; y1  	: start y position of the pixel
											; y2  	: end y position of the pixel
											; returns:
											; none, prints to the screen	

											; assumes no x nor y coordinate exceed the 320x200 window available

	color EQU ss:[bp+4]
	x1 EQU ss:[bp+6]
	x2 EQU ss:[bp+8]
	y1 EQU ss:[bp+10]
	y2 EQU ss:[bp+12]


	push bp
	mov bp, sp

 	push ax
 	push bx
 	push cx
 	push dx
 	push si

 	; initilized parameters
 	mov ax, x1   							; ax = current x position
 	mov dx, y1								; dx = current y position


 	; draw first pixel
 	push dx
	push ax
	push color
	call drawPixel

 	; step size 
 	mov cx, 1  								; ch = y step size, default = 1
 	mov bx, y2
 	cmp dx, bx							
 	jle compare_x
 	mov cx, -1 								; if y2 < y1, step size = -1 
 											; (only needed for diagonal with slope = -1)


 	compare_x:

 	xor si, si  							; si = boolean flag. If we are not are at (x2,y2), 
 											; then continue itterating (true = 0, else = false)

 	mov bx, x2
 	cmp ax, bx
 	jz compare_y
 	inc ax     								; ax++ = current_x + 1
 	inc si									; we updated x, so not done. Update boolean to false

 	compare_y:

 	mov bx, y2
 	cmp dx, bx
 	jz draw_at
 	add dx, cx   							; dx = dx + cx = current_y + step_size
 	inc si									; we updated x, so not done. Update boolean to false


 	draw_at:

 	cmp si, 0  								; if (end)
 	jz end_drawLine

 	push dx 								; push y coordinate
 	push ax									; push x coordinate
 	push color								; push color
 	call drawPixel

 	jmp compare_x


 	end_drawLine:

 	pop si
 	pop dx
 	pop cx
 	pop bx
 	pop ax

 	pop bp

 	ret 10	


drawLine_h: 								; void drawLine_h(color, x1, y, x2)
											; draws an horizontal line to the screen. 
											; ! HARD CODED TO MODE 13H!
											; inputs:
											; color	: hex code of the pixel's color (8 bits)
											; x1  	: start x position of the pixel
											; y  	: y position of the pixel
											; x2  	: end x position of the pixel
											; returns:
											; none, prints to the screen

											; assumptions: x2 >= x1


	push bp
	mov bp, sp

 	push ax
 	push bx
 	push cx
 	push dx

 	; get values
 	mov ax, ss:[bp+4]  						; ax = color
 	mov bx, ss:[bp+6]						; bx = x1
 	mov cx, ss:[bp+8]						; cx = y
 	mov dx, ss:[bp+10]						; dx = x2

 	; push arugments to stack for function call
 	push cx  								; y2 = y (cx)
 	push cx 								; y1 = y (cx)
 	push dx 								; x2 = x (dx)
 	push bx									; x1 = x (bx)
 	push ax 								; color = color (ax)
 	call drawLine

 	pop dx
 	pop cx
 	pop bx
 	pop ax
 	pop bp

 	ret 8


drawLine_v: 								; void drawLine_v(color, x, y1, y2)
											; draws a vertical line to the screen. 
											; ! HARD CODED TO MODE 13H!
											; inputs:
											; color	: hex code of the pixel's color (8 bits)
											; x 	: x position of the pixel
											; y1  	: start y position of the pixel
											; y2  	: end y position of the pixel
											; returns:
											; none, prints to the screen

											; assumptions: y2 >= y1


	push bp
	mov bp, sp

 	push ax
 	push bx
 	push cx
 	push dx

 	; get values
 	mov ax, ss:[bp+4]  						; ax = color
 	mov bx, ss:[bp+6]						; bx = x
 	mov cx, ss:[bp+8]						; cx = y1
 	mov dx, ss:[bp+10]						; dx = y2

 	; push arugments to stack for function call
 	push dx  								; y2 = y (cx)
 	push cx 								; y1 = y (cx)
 	push bx 								; x2 = x (bx)
 	push bx									; x1 = x (bx)
 	push ax 								; color = color (ax)
 	call drawLine

 	pop dx
 	pop cx
 	pop bx
 	pop ax
 	pop bp

 	ret 8		


drawRectangle: 								; void drawRectangle(color, x_left, x_right,)
 											; draws a rectangle from top left corner to bottom right corner
 											; so from (x_left, 184) to (x_right, 187)
 											; (only outline, the rectangel will not be fillder)
	color EQU ss:[bp+4]
	x_l EQU ss:[bp+6]
	x_r EQU ss:[bp+8]


	push bp
	mov bp, sp

	; left line
	; drawLine_v(color, x_l, 184, 187)
	push 187
	push 184
	push x_l
	push color
	call drawLine_v

	; upper line
	;drawLine_h(color, x_l, 184, x_r)
	push x_r
	push 184
	push x_l
	push color
	call drawLine_h

	; lower line
	; drawLine_h(color, x_l, 187, x_r)
	push x_r
	push 187
	push x_l
	push color
	call drawLine_h

	; right line
	; drawLine_v(color, x_r, 184, 187)
	push 187
	push 184
	push x_r
	push color
	call drawLine_v

	pop bp
	ret 6


getPixelColor:								; int getPixelColor(int x, int y)
											; returns the pixel's hex color code at coordinate (x,y)	
											; inputs:
											; x     : pixel's x position
											; y     : pixel's y position
											; returns:
											; int   : hex color code inside al

	x EQU ss:[bp+4]
	y EQU ss:[bp+6]


	push bp
	mov bp, sp										

	push bx
	push cx
	push dx 
	push es


	; set ES to be the base address
	mov ax, 0A000h			
	mov es, ax

	; bx = (y * 320) + x
	mov bx, x
	mov cx, 320
	mov ax, y
	mul cx									; ax = 320 * y
	add bx, ax								; bx = (320 * y) + x

	xor ax, ax   							; clear ax
	mov al, BYTE PTR es:[bx] 				; get color from correct location in buffer

	; color is in al

	; restore the stack
	pop es
	pop dx 
	pop cx
	pop bx
	pop bp

	ret 4  									; exit the function







drawBall:									; void drawBall(void)
											; draws a pixel (ball) to the screen. 
											; !HARD CODED TO MODE 13H!
											; inputs:
											; none
											; returns:
											; none, prints to the screen
	; step 1 - erase old pixel 
	; drawPixel(black, ball_x, ball_y)
	push ball_y									
	push ball_x
	push black
	call drawPixel 	


	; step 2 - update x and y coordinates

	; x = x + vx
	mov ax, ball_x
	add ax, ball_x_vel
	mov ball_x, ax

	; y = y + vy
	mov ax, ball_y
	add ax, ball_y_vel
	mov ball_y, ax


	; step 3 - draw new colored pixel
	; drawPixel(ball_color, ball_x, ball_y)
	push ball_y									
	push ball_x
	push ball_color
	call drawPixel	

	ret 0



checkWallCollision: 						; int checkWallCollision(x, y)
											; checks wether the given x and y coordinates collide with a wall
											; inputs:
											; x  	: x position of the pixel
											; y  	: y position of the pixel
											; returns:
											; code in ax

	x EQU word ptr ss:[bp+4] 
	y EQU word ptr ss:[bp+6]

	push bp
	mov bp, sp	


	if_ret_1:
	; if ((x = 16 && y >= 33) || (x = 303 && Y >= 33)) {return 1;} else {goto if_ret_2;}
	; becomes: 
	; if ((y < 33) || (x != 16 && x != 303)) {goto if_ret_2;} else {return 1;}
	cmp y, 33 
	jl if_ret_2

	cmp x, 16
	je ret_1

	cmp x, 303
	jne if_ret_2

	ret_1:

	mov ax, 1
	jmp exit_checkWallCollision


	if_ret_2: 
	; if ((17 <= x && x <= 302) && y = 32) {return 2;} else {goto if_ret_3;}
	; becomes:
	; if (x < 17 || x > 302 || y != 32) {goto if_ret_2;} else {return 2;}
	cmp x, 17
	jl if_ret_3

	cmp x, 302
	jg if_ret_3

	cmp y, 32
	jne if_ret_3

	mov ax, 2
	jmp exit_checkWallCollision


	if_ret_3:
	; if ((x = 16 && y = 32) || (x = 303 && y = 32)) {return 3;} else {goto ret_0;}
	; becomes :
	; if (y != 32 || (x != 16 && x != 303) {goto ret_0;} else {return 3;}
	cmp y, 32
	jne ret_0

	cmp x, 16
	je ret_3

	cmp x, 303
	jne ret_0


	ret_3:

	mov ax, 3
	jmp exit_checkWallCollision


	ret_0:

	xor ax, ax
	jmp exit_checkWallCollision


	exit_checkWallCollision:

	; return value is in ax
	pop bp
	ret 4


handleCollision: 							; void handleCollision (void)
											; handles ball collision with walls
											; inputs:
											; none
											; returns:
											; none


	; block collisions:
	push ball_y_vel
	push ball_x_vel
	push ball_y
	push ball_x
	call checkBrickCollision
	; return value is inside ax						

	cmp ax, 1
	je handle_code_1_block

	cmp ax, 2
	je handle_code_2_block

	cmp ax, 3
	je handle_code_3_block

	; else, means code 0, so do nothing
	jmp handle_wall


	handle_code_1_block:
	neg ball_x_vel
	jmp handle_wall

	handle_code_2_block:
	neg ball_y_vel
	jmp handle_wall

	handle_code_3_block:
	neg ball_x_vel
	neg ball_y_vel



	; wall collisions:
	handle_wall:
	push ball_y
	push ball_x
	call checkWallCollision
	; return value is inside ax

	cmp ax, 1
	je handle_code_1_wall

	cmp ax, 2
	je handle_code_2_wall

	cmp ax, 3
	je handle_code_3_wall

	; else, means code 0, so do nothing
	jmp handle_paddle


	handle_code_1_wall:
	neg ball_x_vel
	jmp handle_paddle

	handle_code_2_wall:
	neg ball_y_vel
	jmp handle_paddle

	handle_code_3_wall:
	neg ball_x_vel
	neg ball_y_vel



	; paddle collisions:
	handle_paddle:

	cmp ball_y, 183
	jne exit_handleCollision

	; if ball is at y = 183
	call checkPaddleCollision
	; return value is inside ax

	cmp ax, 1
	je handle_code_1_paddle

	cmp ax, 2
	je handle_code_2_paddle

	cmp ax, 3
	je handle_code_3_paddle

	; else, means code 0, so do nothing
	jmp exit_handleCollision


	handle_code_1_paddle:
	mov ball_x_vel, -1
	mov ball_y_vel, -1
	jmp exit_handleCollision

	handle_code_2_paddle:
	mov ball_x_vel, 0
	mov ball_y_vel, -1
	jmp exit_handleCollision

	handle_code_3_paddle:
	mov ball_x_vel, 1
	mov ball_y_vel, -1



	exit_handleCollision:

	ret 0


resetAfterBallLoss:							; int resetAfterBallLoss (void)
											; resets ball to middle of the screen
											; inputs:
											; none
											; returns:
											; number of lives remaning in ax
	mov ball_x, 160
	mov ball_y, 144
	mov ball_x_vel, 0
	mov ball_y_vel, -1

	; draw the ball at this location:
	push ball_y
	push ball_x
	push ball_color
	call drawPixel


	; reset paddle
	mov paddle_x, 144
	mov paddle_length, 32
	call drawPaddle

	; drecrease live
	call decreaseLives
	; returns the number of lives remaining, inside of ax

	; return value is in ax
	ret 0	






drawPaddle: 								; void drawPaddle(void)

	; preserver registers
	push bx
	push cx

	call clearPaddleZone

	; draw left rectangle
	mov bx, paddle_length
	sub bx, 4
	shr bx, 1  								; bx = (paddle_length - 4)/2 = length of left/right paddles
	dec bx 									; bx = number of pixels to draw for left/right paddles

	mov cx, bx
	add cx, paddle_x						; cx = x right coordinate of left rectangle 


	; drawRectangle (left_paddle_color, paddle_x, ax)
	push cx
	push paddle_x
	push left_paddle_color
	call drawRectangle

	inc cx 									; cx is now the left pixel of next rectangle


	; draw middle rectangle
	; drawRectangle (middle_paddle_color, ax, ax + 3)
	add cx, 3
	push cx
	sub cx, 3   							; restore value of cx
	push cx
	push middle_paddle_color
	call drawRectangle


	add cx, 4 								; cx is now the left pixel of the next rectangle (3 + 1)
	add bx, cx 								; bx is now the right most pixel of the next rectangle

	; draw right rectangle
	; drawRectangle (right_paddle_color, ax, bx)
	push bx
	push cx
	push right_paddle_color
	call drawRectangle

	pop cx
	pop bx
	ret 0


checkPaddleCollision:						; int checkPaddleCollision(void)

	
	mov ax, ball_y
	inc ax

	; getPixelColor(ball_x, ball_y +1)
	push ax
	push ball_x
	call getPixelColor
	; result is inside al

	mov ah, 00h   							; clear ah for comparison

	cmp ax, left_paddle_color
	jne if_middle_paddle

	; if pixel color == left_paddle_color ->
	mov ax, 1
	jmp exit_checkPaddleCollision


	if_middle_paddle:
	cmp ax, middle_paddle_color
	jne if_right_paddle

	; if pixel color == middle_paddle_color ->
	mov ax, 2
	jmp exit_checkPaddleCollision


	if_right_paddle:
	cmp ax, right_paddle_color
	jne not_on_paddle

	; if pixel color == right_paddle_color
	mov ax, 3
	jmp exit_checkPaddleCollision


	not_on_paddle: ; not above paddle, so return 0

	xor ax, ax
	jmp exit_checkPaddleCollision

	exit_checkPaddleCollision:

	ret 0


update_available_score:
	
	push bx

	call getScore

	mov bx, ax
	sub bx, previous_iteration_score
	add available_score, bx  					; available score += getScore - previousIterationScore
	mov previous_iteration_score, ax


	pop bx
	ret 0




handle_power_up_one:
	; since default value is for the counter is 600, then if the current value is greater than 500, 
	; we know the counter is used yet, thus power up #1 is not active.

	cmp counter_power_up_one, 500
	jg exit_handle_power_up_one

	; if we are in the last iteration, stop the power up. Otherwise, continue

	cmp counter_power_up_one, 1
	jg decrement_counter

	; if (counter <= 1) 
	call reset_power_one
	jmp exit_handle_power_up_one

	decrement_counter:
	dec counter_power_up_one

	exit_handle_power_up_one:
	ret 0


reset_power_one:
	mov paddle_length, 32  					; restore default paddle length
	mov counter_power_up_one, 600 			; reset counter
	call drawPaddle 						; draw normal paddle

	ret 0



handle_power_up_two:
	cmp draw_laser, 0    					; verify if we need to draw the laser or not
	je exit_handle_power_up_two   			; if not, nothing to do, quit

	; delete old pixel laser
	; drawPixel(black, x, y)
	push laser_y
	push laser_x
	push black
	call drawPixel

	call handle_collision_laser
	cmp draw_laser, 0    					; verify if the laser has done collision
	jne drawLaser 				   			; if not, draw laser

	; if collision, reset laser:
	mov laser_x, 0
	mov laser_y, 183
	jmp exit_handle_power_up_two

	drawLaser:
	; drawPixel(magenta, x, y)
	push laser_y
	push laser_x
	push 05h
	call drawPixel

	exit_handle_power_up_two:
	ret 0


handle_collision_laser:
	; does current touch wall? if so, set to 0 and quit, if not, update y to be one pixel up

	; checkWallCollision(x, y)
	push laser_y
	push laser_x
	call checkWallCollision   				; result in ax

	cmp ax, 0
	jne collision_detected					; collision with wall

	; checkBrickCollision(x, y, vel_x, vel_y)
	push -1
	push 0
	push laser_y
	push laser_x
	call checkBrickCollision


	cmp ax, 0
	jne collision_detected					; collision with block


	; if no collision, we update the y position by one pixel
	dec laser_y
	jmp exit_handle_collision_laser

	collision_detected:
	mov draw_laser, 0

	exit_handle_collision_laser:
	ret 0





start:
    mov ax, @data
    mov ds, ax
	
	push OFFSET ID 							
	push ds
	call setupGame 							; change video mode, draw walls & write score, ID and lives
	call drawPaddle
	call drawBricks
	
main_loop:
	call sleep								; wait
	call drawBall							; draw ball
	call handleCollision 					; perform collisions
	call handle_power_up_one 				; update power up one features, if activated
	call handle_power_up_two				; update power up two features, if activated
	call update_available_score				; get new score that user can spent on power ups

	; verify if the ball is lost:
	cmp ball_y, 199
	jle keypressCheck

	; if (ball_y > 199) then ....
	call resetAfterBallLoss
	call reset_power_one  					; remove power up one
	mov draw_laser, 0  						; remove power up two

	cmp ax, 0
	jg keyboardInput


	; if (no more lives), wait for keypress and exit
wait_keypress_to_exit:	
	mov ah, 01h 							; check if keyboard is being pressed
	int 16h 								; zero flag (zf) is set to 1 if no key pressed
	jz wait_keypress_to_exit 				; if zero flag set to 1 (no key pressed), loop back

	jmp exit


keypressCheck:
	mov ah, 01h 							; check if keyboard is being pressed
	int 16h 								; zero flag (zf) is set to 1 if no key pressed
	jz main_loop 							; if zero flag set to 1 (no key pressed), loop back
keyboardInput:
	; else get the keyboard input
	mov ah, 00h
	int 16h

	; if a or A character
	cmp al, 61h
	je move_left

	cmp al, 41h
	je move_left


	; if d or D character
	cmp al, 64h
	je move_right

	cmp al, 44h
	je move_right


	; if 1

	cmp al, 31h
	je activate_power_up_one


	; if 2

	cmp al, 32h
	je activate_power_up_two


	; if escape character
	cmp al, 1Bh   							
	je exit_2

	; if any other character
	jmp main_loop

move_left:
	mov ax, paddle_x
	sub ax, 8
	cmp ax, 0
	jge modify_pos_left

	mov ax, 0

	modify_pos_left:
	mov paddle_x, ax
	call drawPaddle
	jmp main_loop


move_right:
	mov ax, paddle_x
	mov bx, 320
	sub bx, paddle_length  					; bx = 320 - paddle_length
	add ax, 8
	cmp ax, bx
	jl modify_pos_right

	mov ax, bx

	modify_pos_right:
	mov paddle_x, ax
	call drawPaddle	
	jmp main_loop


exit_2:
	jmp exit 								; label is too far for je instruction in the escape key check


activate_power_up_one:
	mov ax, score_for_power_ups
	cmp available_score, ax
	jge do_power_up_one

	jmp main_loop							; not enough points, so go into next iteration

	do_power_up_one:							

	; update available score
	mov available_score, 0  				; restart from 0 (so need 50 more points for next power up)
	mov paddle_length , 64   				; update paddle length
	mov counter_power_up_one, 500 			; start counter
	call drawPaddle 						; draw updated paddle
	jmp main_loop


activate_power_up_two:
	mov ax, score_for_power_ups
	cmp available_score, ax
	jge do_power_up_two

	jmp main_loop							; not enough points, so go into next iteration

	do_power_up_two:	
	mov available_score, 0  				; restart from 0 (so need 50 more points for next power up)
	;remove old pixel (not really needed, but in case we use power up 2 quickly in succession)
	push laser_y
    push laser_x
    push black
    call drawPixel

	mov laser_y, 183
	mov draw_laser, 1
	mov ax, paddle_length
	shr ax, 1  								; ax = paddle_length/2
	add ax, paddle_x  						; ax = paddle_x + (paddle_length/2)
	mov laser_x, ax
	; call handle_power_up_two   			; draw the laser
	jmp main_loop


exit:
    mov ax, 4f02h							; change video mode back to text
    mov bx, 3
    int 10h

    mov ax, 4c00h							; exit program
    int 21h

END start

