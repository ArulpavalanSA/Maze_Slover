
/*
# Team ID:          1913
# Theme:            Maze Solver bot
# Author List:      Arulpavalan S A
# Filename:         quadrature_encoder.v
# File Description: Processes wheel encoder signals to count rotation pulses
#                   and compute linear distance traveled by the wheel.
# Global variables: None
*/

module quadrature_encoder(
  input clk, reset,
	input ENA,ENB,
  input reset_count,
	output reg [31:0] count,
	output [31:0] distance
);

reg [2:0] ENA_delayed = 3'b000;
reg [2:0] ENB_delayed = 3'b000;

// count = number of quadrature edges detected

//wire count_enable = ENA_delayed[1] ^ ENA_delayed[2] ^ ENB_delayed[1] ^ ENB_delayed[2];
//wire count_direction = ENA_delayed[1] ^ ENB_delayed[2];

// the above mentioned method is to find the direction, i don't need now so i commented it

wire count_enable = ENA_delayed[1] && !ENA_delayed[2];

initial begin
    count = 0;
    ENA_delayed = 3'b000;
    ENB_delayed = 3'b000;
end

always @(posedge clk) begin
    if(!reset || reset_count) begin
        count <= 0;
        ENA_delayed <= 3'b000;
        ENB_delayed <= 3'b000;
    end
    else begin
        ENA_delayed <= {ENA_delayed[1:0], ENA};
        ENB_delayed <= {ENB_delayed[1:0], ENB};
        if(count_enable) begin
            count <= count + 1;
        end
    end
end

wire [48:0] mult;
assign mult = count * 195;
assign distance = mult / 1000;

/*
Distance calculation math:
Wheel radius r = 21 mm
Wheel circumference:
C = 2 * π * r
  = 2 * π * 21
  ≈ 131.95 mm
N20 motor with gearbox + encoder gives approximately:
Distance per encoder count:
≈ 0.195 mm per count
To avoid floating-point arithmetic in FPGA:
0.195 mm = 195 / 1000 mm 
*/

endmodule