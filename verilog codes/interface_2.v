//i made arm,mositure sensor ,dht and bluetooth to work together.

module interface_2(
    input  clk_50MHz,
    input  reset,
    input dout,
    input ir_flag,
    inout dht_sensor,
    output reg servo1,
    output reg servo2,
    output reg tx
);

wire [2:0] servo_state;
wire [7:0] T_integral;
wire [7:0] RH_integral;
wire [7:0] T_decimal;
wire [7:0] RH_decimal;
wire [7:0] Checksum;
wire dht_data_valid;
wire [11:0] d_out_ch0;

wire tx_start;
wire tx_done;
wire [7:0] data_sample;

reg [2:0] c =0;
reg clk_3125;
wire in;

always @(posedge clk_50MHz)begin
  c<=c+1;
  if(c==0) clk_3125 <= ~clk_3125;
end

wire send = 0;

//assign sevo_state = 

servo(
    .clk_50MHz(clk_50MHz),
    .reset(reset),
    .ir_flag(ir_flag),
    .servo1(servo1),
    .servo2(servo2),
    .state(servo_state),
    .in(in)
);

dht(
    .clk_50M(clk_50MHz),
    .reset(reset),  
    .sensor(dht_sensor),
    .T_integral(T_integral),
    .RH_integral(RH_integral),
    .T_decimal(T_decimal),
    .RH_decimal(RH_decimal),
    .Checksum(Checksum),
    .data_valid(dht_data_valid)
);

moisture_sensor(
    .dout(dout),
    .clk50(clk_50MHz),
    //output adc_cs_n, din, adc_sck,
    .d_out_ch0(d_out_ch0)
    //output [7:0] led_ind
);

message(
    .clk(clk_3125),
    .reset(reset),
    .ir_flag(ir_flag),
    .sensor_flag(in),
    .T_integral(T_integral),
    .RH_integral(RH_integral),
    .moist_data(d_out_ch0),
    .tx_done(tx_done),
    .tx_start(tx_start),
    .data(data_sample)
);

uart_tx(
    .clk_3125(clk_3125),
	.reset(reset),
    .tx_start(tx_start),
    .data(data_sample),
    .tx(tx),
    .tx_done(tx_done)
);





endmodule
