/*
# Team ID:          1913
# Theme:            Maze Solver bot
# Author List:      Arulpavalan S A
# Filename:         ultrasonic_distance_filter.v
# File Description: HC-SR04 ultrasonic sensor interface module that measures
#                   distance in millimeters using echo timing and applies
#                   a 3-sample moving average filter for stable output.
# Global variables: None
*/


/*
Module HC_SR04 Ultrasonic Sensor

This module will detect objects present in front of the range,
and give the distance in mm.

Input:
    clk_50M - 50 MHz system clock
    reset   - active-low reset signal
    echo_rx - echo pulse received from HC-SR04 sensor

Output:
    trig         - trigger pulse to ultrasonic sensor
    op           - object present indicator
    ready        - indicates a valid distance measurement
    distance_out - filtered distance output in millimeters
*/

// Module declaration
module ultrasonic_distance_filter(
    input clk_50M, reset, echo_rx,
    output reg trig,
    output op,
    output reg ready,
    output wire [15:0] distance_out
);

//////////////////DO NOT MAKE ANY CHANGES ABOVE THIS LINE //////////////////

/*
Add your logic here
*/

// FSM state encoding
localparam ideal     = 2'b00; // Idle state between measurements
localparam tsend     = 2'b01; // Trigger pulse generation state
localparam emonitor  = 2'b10; // Echo monitoring and distance calculation

// count: counts echo pulse width (time-of-flight)
reg [19:0] count;

// state: current FSM state
reg [1:0] state;

// delay: timeout counter to avoid getting stuck waiting for echo
reg [19:0] delay;

// distance: raw distance computed from echo pulse width
reg [15:0] distance;

// d0, d1, d2: last three valid distance samples for moving average filter
reg [15:0] d0, d1, d2;

// sum: sum of last three distance samples
reg [31:0] sum;

// valid_count: tracks how many valid samples are collected (0 to 3)
reg [1:0]  valid_count;

// avg_distance: filtered distance after applying moving average
reg [15:0] avg_distance;


/*
Purpose:
---
Initialize FSM state, counters, and registers to known values
at simulation start.
*/
initial begin
	state = ideal;
	count = 0;
	trig = 1'b0;
	delay = 0;
	distance = 0;
	ready = 0;
end


always @(posedge clk_50M) begin
/*
Purpose:
---
Main FSM controlling ultrasonic trigger generation, echo timing,
distance calculation, and moving average filtering.
*/

	if (!reset) begin
		// reset: clear all registers
		trig <= 1'b0;
		count <= 0;
		state <= ideal;
		delay <= 0;
		distance <= 0;
		ready <= 0;
	end
	else begin
		case (state)

			ideal: begin
				// Idle delay before sending trigger pulse
				count <= count + 1;
				trig <= 1'b0;

				// Short wait before triggering sensor
				if(count == 19'd50) begin
					state <= tsend;
					count <= 0;
				end
			end

			tsend: begin
				// Generate trigger pulse 
				trig <= 1'b1;
				count <= count + 1;

				// End trigger pulse after fixed duration
				if(count == 500) begin
					state <= emonitor;
					count <= 0;
					trig <= 1'b0;
				end
			end

			emonitor: begin
				// Monitor echo signal and measure pulse width
				trig <= 1'b0;
				delay <= delay + 1;

				// Count clock cycles while echo is high
				if(echo_rx == 1'b1) begin
					count <= count + 1;
				end
				else begin
					// Convert echo pulse width to distance (in mm)
					// distance ≈ (count * 17) / 5000
					distance <= (count * 17) / 5000;
				end

				// Timeout condition to end measurement cycle
				if(delay > 600000) begin
					count <= 0;
					state <= ideal;
					delay <= 0;
					ready <= 1;

					// Moving average filter logic (3 samples)
					if(distance != 0) begin
						if(valid_count < 3) begin
							// Filling stage: collect first 3 samples
							d2 <= d1;
							d1 <= d0;
							d0 <= distance;

							sum <= sum + distance;
							valid_count <= valid_count + 1;
						end
						else begin
							// Sliding window stage: update sum
							sum <= sum - d2 + distance;

							d2 <= d1;
							d1 <= d0;
							d0 <= distance;
						end
					end

					// Compute average once 3 valid samples are available
					if(valid_count == 3)
						avg_distance <= sum / 3;
				end
			end

		endcase
	end

end


// distance_out: final filtered distance output
assign distance_out = avg_distance;

// op: object present flag when distance is within valid range
assign op = (distance_out < 7'd90) && (distance_out > 5);

//////////////////DO NOT MAKE ANY CHANGES BELOW THIS LINE //////////////////

endmodule
