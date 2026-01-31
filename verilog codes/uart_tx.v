
// module declaration
module uart_tx(
    input clk_3125,
    input parity_type,tx_start,
    input [7:0] data,
    output reg tx, tx_done
);

initial begin
    tx = 1'b1;
    tx_done = 1'b0;
end
//////////////////DO NOT MAKE ANY CHANGES ABOVE THIS LINE//////////////////
 
 /*  Add your logic here */
 
reg [10:0] frame;      // start + data + parity + stop bits
reg [3:0] bit_index;   // index counter
reg sending;           // transmission flag
reg parity;            // parity bit
reg [4:0] clk_count;   // counts up to 27 clocks for 1 bit time at 3125 KHz (115200 bps)

initial begin
	sending = 1'b0;
	bit_index = 0;
	parity = 0;
	frame = 0;
    clk_count = 0;
end

always @(posedge clk_3125) begin
    if ((tx_start) & (~sending)) begin

        // Step 1: Initialize transmission
        sending <= 1'b1;
        bit_index <= 0;
        tx_done <= 1'b0;
        tx <= 0;  // start bit
        clk_count <= 0;   // reset clock counter imp and start(0) is included here
    end

    else if (sending) begin

        // Step 2: Compute parity
        //parity <= ^data;                          // XOR of all bits (even parity)
        if (parity_type) parity = ~(^data);       // If odd parity selected
        else parity = ^data;                     // Even parity
            
        // Step 3: Build frame:  stop(1), parity, data(0:7)
        frame = {1'b1, data[0], data[1], data[2], data[3], data[4], data[5], data[6], data[7]};  // MSB = stop, LSB = start

        // Step 4: Send bits one by one
		if (clk_count < 26) begin
        	clk_count <= clk_count + 1;
    	end 
		else begin
        	clk_count <= 0;
        	bit_index <= bit_index + 1;
        	tx <= frame[8-bit_index];
            //if (bit_index == 10) tx_done <= 1'b1;
    	end

        if ((bit_index == 10)&(clk_count==25)) begin
            sending <= 1'b0;
            tx_done <= 1'b1;   // indicate done for one clock
            bit_index <= 0;
        end
    end

    else begin
        // Idle state
        tx <= 1'b1;
        tx_done <= 1'b0;
	    bit_index = 0;
	    parity = 0;
	    frame = 0;
        clk_count = 0;
    end
end

 
		
		
//////////////////DO NOT MAKE ANY CHANGES BELOW THIS LINE//////////////////

endmodule