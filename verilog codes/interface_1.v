/*
# Team ID:          1913
# Theme:            Maze Solver bot
# Author List:      Arulpavalan S A
# Filename:         interface_1
# File Description: Top-level module integrating ultrasonic sensors, IR sensors,
#                   maze explorer logic, motor driver, and encoder feedback
#                   to control a complete maze-solving robot.
# Global variables: None
*/

module interface_1 (
	input clk, reset, 
	input US_EC1, US_EC2, US_EC3,      // echo signals from left, front, right ultrasonic sensors
	input ir_left, ir_right, ir_front,// IR wall detection sensors
	output US_TR1, US_TR2, US_TR3,     // trigger signals to ultrasonic sensors
	output MD_ENA, MD_ENB,             // PWM enable signals for motor driver
	output MD_IN1, MD_IN2, MD_IN3, MD_IN4, // motor direction control pins
	input ENA_1, ENB_1, ENA_2, ENB_2   // encoder channel inputs for left and right wheels
);

(* keep = "true" *) wire [15:0] left_distance;   // filtered distance from left ultrasonic sensor
(* keep = "true" *) wire [15:0] front_distance;  // filtered distance from front ultrasonic sensor
(* keep = "true" *) wire [15:0] right_distance;  // filtered distance from right ultrasonic sensor

(* keep = "true" *) wire obstacle_left;   // left obstacle flag (1 = obstacle detected)
(* keep = "true" *) wire obstacle_front;  // front obstacle flag
(* keep = "true" *) wire obstacle_right;  // right obstacle flag

(* keep = "true" *) wire [2:0] move;      // movement command from maze logic to motor controller

(* keep = "true" *) wire [31:0] left_rotation;   // raw encoder count for left wheel
(* keep = "true" *) wire [31:0] right_rotation;  // raw encoder count for right wheel

(* keep = "true" *) wire [31:0] dist_left_wheel; // computed distance traveled by left wheel
(* keep = "true" *) wire [31:0] dist_right_wheel;// computed distance traveled by right wheel

(* keep = "true" *) wire reset_count;     // resets encoder counters after each move

wire [7:0] count_move;                    // counts number of completed moves

wire ready1, ready2, ready3;              // ready flags from ultrasonic modules

// ready_all: indicates all ultrasonic sensors have completed measurement
wire ready_all;
assign ready_all = ready1 & ready2 & ready3;


/*
Ultrasonic sensor modules
Each module measures distance and provides a filtered output and ready signal
*/
ultrasonic_distance_filter U1 (
	.clk_50M(clk), 
	.reset(reset), 
	.echo_rx(US_EC1), 
	.trig(US_TR1), 
	.op(obstacle_left), 
	.ready(ready1),
	.distance_out(left_distance)
);

ultrasonic_distance_filter U2 (
	.clk_50M(clk), 
	.reset(reset), 
	.echo_rx(US_EC2), 
	.trig(US_TR2), 
	.op(obstacle_front), 
	.ready(ready2),
	.distance_out(front_distance)
);

ultrasonic_distance_filter U3 (
	.clk_50M(clk), 
	.reset(reset), 
	.echo_rx(US_EC3), 
	.trig(US_TR3), 
	.op(obstacle_right), 
	.ready(ready3),
	.distance_out(right_distance)
);


/*
Maze movement sequence generator
Outputs predefined movement commands based on move count
*/
maze_move_sequence ME (
	.clk(clk),
	.rst_n(reset),
	.ready(ready_all),
	.count_move(count_move),
	.move(move)
);


/*
Motor drive controller
Executes movement commands using encoder, ultrasonic, and IR feedback
*/
motor_drive_controller MD (
	.clk(clk),
	.reset(reset),
	.move(move), 
	.dist_left_wheel(dist_left_wheel),
	.dist_right_wheel(dist_right_wheel),
	.left_distance(left_distance),
	.right_distance(right_distance),
	.front_distance(front_distance),
	.ir_left(ir_left),
	.ir_right(ir_right),
	.ir_front(ir_front),
	.ENA(MD_ENA),
	.ENB(MD_ENB),
	.IN1(MD_IN1),
	.IN2(MD_IN2),
	.IN3(MD_IN3),
	.IN4(MD_IN4),
	.reset_count(reset_count),
	.count_move(count_move),
);


/*
Quadrature encoders
Measure wheel rotation and convert it to linear distance
*/
quadrature_encoder E_1 (
	.clk(clk),
	.reset(reset),
	.ENA(ENA_1),
	.ENB(ENB_1),
	.reset_count(reset_count),
	.count(left_rotation),
	.distance(dist_left_wheel)
);

quadrature_encoder E_2 (
	.clk(clk),
	.reset(reset),
	.ENA(ENA_2),
	.ENB(ENB_2),
	.reset_count(reset_count),
	.count(right_rotation),
	.distance(dist_right_wheel)
);

endmodule
