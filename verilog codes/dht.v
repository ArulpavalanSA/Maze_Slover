module dht(
    input clk_50M,
    input reset,
    inout sensor,
    output reg [7:0] T_integral,
    output reg [7:0] RH_integral,
    output reg [7:0] T_decimal,
    output reg [7:0] RH_decimal,
    output reg [7:0] Checksum,
    output reg data_valid
    //output reg [2:0] state
);

//////////////////DO NOT MAKE ANY CHANGES ABOVE THIS LINE //////////////////

    // ======== FSM State Encoding ========
    localparam  IDLE        = 3'd0,
                START_SIG   = 3'd1,
                WAIT_RESP   = 3'd2,
                READ_BITS   = 3'd3,
                VALIDATE    = 3'd4,
                RESTART     = 3'd5,
                WAIT        = 3'd6;

(* keep *) reg [2:0] state;
    // ======== Internal Registers ========
    reg [19:0] clk_cnt;
    reg [5:0]  bit_index;
    reg [40:0] data_reg;
	reg [19:0] count;
    reg [19:0] escape;

    reg sensor_out;
    reg sensor_dir;
    assign sensor = sensor_dir ? 1'bz : sensor_out;
    wire sensor_in = sensor;
    reg wait_low;

    // ======== Initialization ========
    initial begin
        T_integral  = 0;
        RH_integral = 0;
        T_decimal   = 0;
        RH_decimal  = 0;
        Checksum    = 0;
        data_valid  = 0;

        clk_cnt     = 0;
        bit_index   = 0;
        data_reg    = 0;
		count       = 0;
        wait_low    = 0;
        sensor_out  = 1;
        sensor_dir  = 1;
        state       = IDLE;
    end

    reg next = 0 ;

    // ======== FSM Implementation ========
    always @(posedge clk_50M) begin
        if (~reset | next) begin
            clk_cnt     <= 0;
            bit_index   <= 0;
            data_reg    <= 0;
            sensor_out  <= 0;
            sensor_dir  <= 0;
            data_valid  <= 0;
            wait_low    <= 0;
            if(next) begin
                count <= count + 1;
                if(count>10000) begin
                    next <=0;
                    count<=0;
                    state <= IDLE;
                end
            end
            else begin
                count <=0;
                state <= IDLE;
            end
        end
        else begin
            case(state)

                // ===========================
                // IDLE → prepare for start
                // ===========================
                IDLE: begin
                    sensor_dir <= 0;
                    sensor_out <= 0;
                    data_valid <= 0;
                    clk_cnt    <= 0;
                    wait_low <=0;
                    state      <= START_SIG;
                    count <=0;
                    escape <=0;
                end

                // ===========================
                // START → drive low 18ms
                // ===========================
                START_SIG: begin
                    sensor_dir <= 0;
                    sensor_out <= 0;
                    clk_cnt    <= clk_cnt + 1;

                    if (clk_cnt >= 20'd900000) begin // ~18ms @50MHz
                        //sensor_out <= 1;  // set output high for 40 us
                        //count <= count + 1;
                        sensor_dir <= 1; // release line
                        //if(count > 2000) begin  //40us 
                            clk_cnt <= 0;
                            state <= WAIT_RESP;
                        //end
                    end
                end

                // ===========================
                // WAIT → look for sensor ACK
                // ===========================
                WAIT_RESP: begin
                    if (~sensor_in & ~wait_low) begin
                        clk_cnt <= clk_cnt + 1;
                    end
                    
                    if (clk_cnt >= 13'd2500 && sensor_in) begin // 80us  low {marigin correction}
                        clk_cnt <= 0;
                        wait_low <= 1;
                        escape <=0;
                    end

                    if(wait_low && sensor_in)begin
                        count <= count +1;
                    end
                    if(count >= 13'd2500 && ~sensor_in )begin  // 80us high
                        bit_index <= 0;
                        state <= READ_BITS;
                        wait_low <=0;
                        count <= 0;
                        escape <=0;
                    end

                    escape <= escape + 1;
                    if(count >= 10000 || clk_cnt >= 10000 ||escape >10000) state <=IDLE;

                end

                // ===========================
                // READ_BITS → capture 40 bits
                // ===========================
                READ_BITS: begin
                    if (bit_index < 40) begin
                        if (sensor_in)
                            clk_cnt <= clk_cnt + 1;
                        else if (clk_cnt > 0) begin
                            if (clk_cnt > 13'd3000)
                                data_reg[39 - bit_index] <= 1'b1;
                            else
                                data_reg[39 - bit_index] <= 1'b0;
                            bit_index <= bit_index + 1;
                            clk_cnt <= 0;
                        end
                        if(clk_cnt>10000) state <= IDLE;
                    end
                    else begin
                        state <= VALIDATE;
                    end
                    
                end

                WAIT:begin
                    state <= VALIDATE;
                end

                // ===========================
                // VALIDATE checksum
                // ===========================
                VALIDATE: begin

                    if (data_reg[7:0] == (data_reg[39:32] + data_reg[31:24] + data_reg[23:16] + data_reg[15:8]))begin
                        RH_integral <= data_reg[39:32];
                        RH_decimal  <= data_reg[31:24];
                        T_integral  <= data_reg[23:16];
                        T_decimal   <= data_reg[15:8];
                        Checksum    <= data_reg[7:0];
                        data_valid <= 1'b1;
					end
                    else begin
                        data_valid <= 1'b0;
                    end

                    state <= RESTART;
                end

                // ===========================
                // RESTART → reset & loop again
                // ===========================
                RESTART: begin
                    //clk_cnt    <= 0;
                    bit_index  <= 0;
                    data_reg   <= 0;
                    //sensor_dir <= 1;
                    //sensor_out <= 0;
                    data_valid <=0;
                    if (clk_cnt < 20'd5000000) begin 
                        clk_cnt <= clk_cnt + 1;
                    end 
                    else begin
                        clk_cnt <=0;
                        state       <= IDLE;
                    end
                        bit_index   <= 0;
                        data_reg    <= 0;
                        sensor_out  <= 0;
                        sensor_dir  <= 0;
                        count       <= 0;
                        wait_low    <= 0;
                    //state      <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

//////////////////DO NOT MAKE ANY CHANGES BELOW THIS LINE //////////////////

endmodule
