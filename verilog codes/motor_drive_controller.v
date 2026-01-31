/*
# Team ID:          1913
# Theme:            MazeSolver bot
# Author List:      Arulpavalan S A
# Filename:         motor_drive_controller.v
# File Description: Motor drive control module for left and right DC motors with
#                   PWM generation, movement control (forward, left, right,
#                   u-turn), and sensor-based error correction.
# Global variables: None
*/

`timescale 1ns / 1ps

module motor_drive_controller ( 
	input clk, reset,  					// system clock and reset
	input [2:0] move,  					// movement command input
	input [31:0] dist_left_wheel,		// left motor distance
	input [31:0] dist_right_wheel, 		// right motor distance
	input [15:0] left_distance, 		// from ultrasonic
	input [15:0] right_distance, 		// from ultrasonic
	input [15:0] front_distance, 		// from ultrasonic
	input ir_left,  					// left IR sensor
	input ir_right,						// right IR sensor
	input ir_front,						// front IR sensor
	output reg ENA, ENB, 				// enable signals for left and right motors
	output IN1, IN2, IN3, IN4, 			// direction control signals for motors
	output reg reset_count,				// reset signal for encoders after a move
	output reg [7:0] count_move  		// move counter to track number of moves
);

reg [31:0] count;           // PWM counter

reg [1:0] controla = 0;		// for left motor control
reg [1:0] controlb = 0;		// for right motor control

integer timeperiod = 5000;

integer fastpulse = 4150;  // for moving a step ahead

integer slowpulse = 4100;  // for turning

integer forw_dist = 262;   // distance for moving forward one cell

integer turn_dist = 79;    // distance for 90 degree turn

integer uturn_dist = 176;  // distance for 180 degree turn

reg [8:0] crt=0;           // if my bot moves forward in a curve (not stright line) then crt will count that extra distance to be added in forw_dist

// Movement command encoding
localparam STOP    = 3'b000;
localparam FORWARD = 3'b001;
localparam LEFT   = 3'b010;
localparam RIGHT  = 3'b011;
localparam UTURN   = 3'b100;

// state: main FSM state
reg [1:0] state;

// FSM states
localparam direction = 2'b00;   // deciding direction based on move
localparam step_ahead = 2'b01;  // forward motion with correction
localparam ideal = 2'b10;       // idle state between moves


/*
Purpose:
---
Initialize FSM state, PWM values, counters, and control signals
to known safe defaults at simulation start.
*/

initial begin
	state = direction;
	count = 0;
	controla = 2'b00;
	controlb = 2'b00;	
	reset_count = 1;
	count_move = 0;
	pwm_left = fastpulse;
	pwm_right = fastpulse;

end

// change: flag to ensure one-time setup per movement
reg change = 1;

// pwm_left: PWM duty cycle for left motor
reg [15:0] pwm_left;

// pwm_right: PWM duty cycle for right motor
reg [15:0] pwm_right;

// prev_move: stores previous movement command
reg [3:0] prev_move = 0;

// error_wheel: encoder-based wheel mismatch error
reg signed [15:0] error_wheel = 0;

// error_center: wall-centering error from ultrasonic sensors
reg signed [15:0] error_center = 0;

// hit_left, hit_right: penalty applied when wall is detected too close
reg [7:0] hit_left=0;
reg [7:0] hit_right=0;

// ir_left_crt, ir_ryt_crt: correction offsets from IR sensors
reg [15:0] ir_left_crt=0;
reg [15:0] ir_ryt_crt=0;

// uv_left, uv_right: ultrasonic-based correction for disrable posistions
reg [9:0] uv_left = 0;
reg [9:0] uv_right = 0;  // i haven't used these two variables now due to overcorrection issue

always @(posedge clk)begin
	
/*
Purpose:
---
Main motor control FSM.
Handles PWM generation, movement execution, encoder-based distance tracking,
IR/ultrasonic correction, and move completion logic.
*/
	if(~reset) begin
		// Reset all control signals and internal registers
		count<=0;
		controla <= 2'b00;
		controlb <= 2'b00;
		ENA <= 1'b0;
		ENB <= 1'b0;
		state <= direction;
		change <= 1;
		reset_count <= 1;
		count_move <= 0;
		pwm_left <= fastpulse;
		pwm_right <= fastpulse;	
		error_wheel <= 0;
		error_center <= 0;
		prev_move <= 0;
		hit_left <= 0;
		hit_right <= 0;
		ir_left_crt <=0;
		ir_ryt_crt <=0;
		crt <=0;
	end
	
	else begin

	// IR-based correction flags
		if(~ir_left)begin
			ir_left_crt <= 120;
		end
		else begin
			ir_left_crt <=0;
		end

		if(~ir_right)begin
			ir_ryt_crt <= 120;
		end
		else begin
			ir_ryt_crt <=0;
		end

	// PWM counter increment and wrap-around
		if (count < timeperiod) begin
			count<=count + 1;
		end
		else count<=0;

	// Encoder mismatch error calculation
		if(dist_left_wheel != 0 && dist_right_wheel != 0) begin
			error_wheel = dist_left_wheel - dist_right_wheel;
		end
		else begin
			error_wheel = 0;
		end

		case(state)

			ideal:begin
			// Stop motors and reset state
				controla <= 2'b00;
				controlb <= 2'b00;
				ENA <= 1'b0;
				ENB <= 1'b0;
				change <= 1;
				reset_count <= 1;
				state <= direction;
				pwm_left <= fastpulse;
				pwm_right <= fastpulse;
				error_wheel <= 0;
				
			end

			direction: begin
				// Execute movement based on command
				case(move)

					STOP: begin
						controla <= 2'b00;
						controlb <= 2'b00;
						change <= 1;
						ENA <= 1'b0;
						ENB <= 1'b0;
						reset_count <= 1;
						state <= direction;
					end

					FORWARD: begin
						state <= step_ahead;
						ENA <= 1'b0;
						ENB <= 1'b0;
						change <= 1;
						reset_count <= 1;
					end

					// LEFT, RIGHT, and UTURN cases include:
					// - encoder-based rotation
					// - IR-based correction
					// - PWM balancing using error_wheel

					LEFT: begin

						if(dist_left_wheel < turn_dist - 20)begin    // giving a tolerance of 20 to avoid overcorrection 
							pwm_left <= slowpulse - error_wheel*10 ; // it will be allined properly by ir sensor
							pwm_right <= slowpulse + error_wheel*10;   
						end
						else begin
							pwm_left <= slowpulse + 2*ir_left_crt - 2*ir_ryt_crt;
							pwm_right <= slowpulse - 2*ir_left_crt + 2*ir_ryt_crt;
						end

						if(dist_left_wheel > turn_dist || dist_right_wheel > turn_dist) begin
							
							state <= step_ahead;
							controla <= 2'b11;
							controlb <= 2'b11;
							change <= 1;
							ENA <= 1'b0;
							ENB <= 1'b0;
							reset_count <= 1;
							pwm_left <= fastpulse;
							pwm_right <= fastpulse;
						end
						else begin
							reset_count <= 0;
							if(change)begin
								controla <= 2'b10;
								controlb <= 2'b10;
								change <= 0;
							end
							else begin
								ENA <= (count < pwm_left) ? 1'b1 : 1'b0;
								ENB <= (count < pwm_right) ? 1'b1 : 1'b0;
							end
						end

					end

					RIGHT: begin

						if(dist_left_wheel < turn_dist - 20)begin
							pwm_left <= slowpulse - error_wheel*10 ;    // same logic as left applys here
							pwm_right <= slowpulse + error_wheel*10; 
						end
						else begin
							pwm_left <= slowpulse + 2*ir_left_crt - 2*ir_ryt_crt;
							pwm_right <= slowpulse - 2*ir_left_crt + 2*ir_ryt_crt;
						end
						
						if(dist_left_wheel > turn_dist || dist_right_wheel > turn_dist) begin
							state <= step_ahead;
							controla <= 2'b11;
							controlb <= 2'b11;
							change <= 1;
							reset_count <= 1;
							ENA <= 1'b0;
							ENB <= 1'b0;
							pwm_left <= fastpulse;
							pwm_right <= fastpulse;
						end
						else begin
							reset_count <= 0;
							if(change)begin
								controla <= 2'b01;
								controlb <= 2'b01;
								change <= 0;
							end
							else begin
								ENA <= (count < pwm_left) ? 1'b1 : 1'b0;
								ENB <= (count < pwm_right) ? 1'b1 : 1'b0;
							end
						end
					end

					UTURN: begin

						if(dist_left_wheel < uturn_dist - 30)begin      // tolerance of 30
							pwm_left <= slowpulse - error_wheel*10 ; 	// rest of the logic remains same as left and right
							pwm_right <= slowpulse + error_wheel*10;
						end
						else begin
							pwm_left <= slowpulse + 2*ir_left_crt - 2*ir_ryt_crt;
							pwm_right <= slowpulse - 2*ir_left_crt + 2*ir_ryt_crt;
						end

						if(dist_left_wheel > uturn_dist || dist_right_wheel > uturn_dist) begin
							state <= step_ahead;
							controla <= 2'b11;
							controlb <= 2'b11;
							change <= 1;
							reset_count <= 1;
							pwm_left <= fastpulse;
							pwm_right <= fastpulse;
						end
						else begin
							reset_count <= 0;
							if(change)begin
							// u-turn logic with IR fallback
								if(!ir_right) begin
									controla <= 2'b10;      //as i need some space for uturn... so if right ir detects obstacle i will turn more to left. istead of always trun in same direction
									controlb <= 2'b10;      // this aviods collision during uturn
								end
								else if(!ir_left) begin
									controla <= 2'b01;
									controlb <= 2'b01;
								end
								else begin
									controla <= 2'b10;
									controlb <= 2'b10;
									change <= 0;
								end
							end
							else begin
								ENA <= (count < pwm_left) ? 1'b1 : 1'b0;
								ENB <= (count < pwm_right) ? 1'b1 : 1'b0;
							end
						end
					end

					default: begin
						controla <= 2'b00;
						controlb <= 2'b00;
						ENA <= 1'b0;
						ENB <= 1'b0;
						change <= 1;
					end		
				endcase
			end
			

			step_ahead: begin

				// Forward motion with wall-centering correction
				// Uses ultrasonic + IR + encoder feedback

				if(left_distance != 0 && right_distance != 0 && left_distance < 120 && right_distance <120 && (dist_left_wheel > 120 || prev_move == FORWARD)) begin
					error_center <= left_distance - right_distance;    // to align the bot in center of the path
				end
				else if ((left_distance>150 && left_distance <300) || (right_distance>150 && right_distance <300)) begin
					error_center <= 0;
				end

				if ((left_distance >5 && left_distance <60) || (right_distance > 90 && right_distance < 140) )begin
					hit_left <= -30;    // to avoid getting too close to wall
				end
				else begin
					hit_left <= 0;
				end

				if ((right_distance >5 && right_distance < 60)||(left_distance>90 && left_distance<140))begin
					hit_right <= -30;  // to avoid getting too close to wall
				end
				else begin
					hit_right <= 0;
				end

				if(ir_left || ir_right)begin
					crt <= crt + 1;  // counting extra distance moved in curve
				end


				/*if (left_distance != 0 && left_distance <75) uv_left <= (left_distance - 80)/2;
				if ( left_distance >290 && left_distance < 390) uv_left <= (left_distance - 340)/2;    // these two variables are not used now due to overcorrection issue

				if (right_distance != 0 && right_distance <75) uv_right <= (right_distance - 80)/2;
				if (right_distance >290 && right_distance < 390) uv_right <= (right_distance - 340)/2;*/

				if(pwm_left > fastpulse + 1000) begin   //safety limits for pwm
					pwm_left <= fastpulse + 1000;   
				end 

				if(pwm_left < fastpulse - 1000) begin   //safety limits for pwm
					pwm_left <= fastpulse - 1000;
				end
				else begin  // applying all corrections to pwm
					pwm_left <= (fastpulse - 4*error_center - (hit_left + 2*ir_left_crt) + (hit_right + 2*ir_ryt_crt)); // + uv_left - uv_right;   
				end

				if(pwm_right > fastpulse + 1000) begin  //safety limits for pwm
					pwm_right <= fastpulse + 1000;
				end
				if(pwm_right < fastpulse - 1000) begin  //safety limits for pwm
					pwm_right <= fastpulse - 1000;
				end
				else begin // applying all corrections to pwm
					pwm_right <= fastpulse + 4*error_center + hit_left + 2*ir_left_crt - (hit_right + 2*ir_ryt_crt); // - uv_left + uv_right;
				end

//i am removing thr lolarance of half froward dist(13) when the move is forward for error correction
				if( (dist_left_wheel > (forw_dist + crt/2))  ||  (dist_right_wheel > (forw_dist + crt/2))  ||  ( ((front_distance >30 && front_distance < 50)||(~ir_front && move == UTURN) ) && dist_left_wheel > 132) ) begin 
					state <= ideal;    // if fornt ultrasonic tells that the wall is too close i will move to next stage (redendency for safety)(instead of always depending of constsnt forward distance)
					controla <= 2'b11;
					controlb <= 2'b11;
					change <= 1;
					reset_count <= 1;
					if(move != FORWARD) crt <=0;   // aviod reseting path drift correction if next move is also forward
					error_wheel <= 0;
				end
				else begin
					reset_count <= 0;
					if(change)begin
						count_move <= count_move + 1;
						controla <= 2'b01;
						controlb <= 2'b10;
						change <= 0;
						prev_move <= move;
					end
					else begin
						ENA <= (count < pwm_left) ? 1'b1 : 1'b0;
						ENB <= (count < pwm_right) ? 1'b1 : 1'b0;
					end
				end

			end
		endcase
	end
		
end 

//assign ENA = (count < pulsewidth) ? 1'b1 : 1'b0;
assign IN1 = controla[1];
assign IN2 = controla[0];

//assign ENB = (count < pulsewidth) ? 1'b1 : 1'b0;
assign IN3 = controlb[1];
assign IN4 = controlb[0];

endmodule
