module servo(
    input  clk_50MHz,
    input  reset,
    input  ir_flag,
    output reg servo1,
    output reg servo2,
    output reg [2:0] state,
    output reg in
);

    localparam PWM_PERIOD = 1_000_000;   // 20 ms @ 50 MHz

    localparam SERVO_NEG90 = 27_000;     // -90°
    localparam SERVO_0     = 75_000;     // 0°
    localparam SERVO_90    = 127_000;    // +90°

    localparam INIT          = 0;
    localparam SERVO2_TO_0   = 1;
    localparam SERVO1_TO_NEG90  = 2;
	localparam B_SERVO1_TO_90 = 3;
	localparam B_SERVO2_TO_NEG90 = 4;
	localparam STEP = 1000;  // smooth step size
    localparam IDEAL = 5;

    //reg [2:0] state;

    reg [19:0] pwm_cnt;       // PWM counter
    reg [25:0] state_cnt;     // delay counter

    reg [20:0] delay;

    reg [19:0] servo1_pw;
    reg [19:0] servo2_pw;

    reg flag = 0;

    initial begin
        in <= 0;
    end

    always @(posedge clk_50MHz) begin

        if (!reset) begin
            pwm_cnt <= 0;
            servo1 <= 0;
            servo2 <= 0;
            state     <= IDEAL;
            state_cnt <= 0;
            servo1_pw <= SERVO_NEG90;
            servo2_pw <= SERVO_NEG90;
            delay <=0;
            in<=0;
            flag<=0;
        end 
		else begin
            state_cnt <= state_cnt + 1;

			if (pwm_cnt == PWM_PERIOD - 1)
				pwm_cnt <= 0;
			else
				pwm_cnt <= pwm_cnt + 1;

            servo1 <= (pwm_cnt < servo1_pw);
            servo2 <= (pwm_cnt < servo2_pw);

            case (state)

                IDEAL: begin
                    servo2_pw <=0;
                    servo1_pw <=0;
                    if(!ir_flag && !flag) state<=INIT;
                end

                INIT: begin
                    servo1_pw <= SERVO_90;
                    servo2_pw <= SERVO_NEG90;

                    if (!ir_flag) begin // ~1 sec
                        state     <= SERVO2_TO_0;
                        state_cnt <= 0;

                    end
                end

                SERVO2_TO_0: begin
                    //servo1_pw <= SERVO_90;
                    //servo2_pw <= SERVO_0;

					if (servo2_pw < SERVO_0 && pwm_cnt == 0)
                        servo2_pw <= servo2_pw + STEP;

                    if (servo2_pw >= SERVO_0) begin
                        state     <= SERVO1_TO_NEG90;
                        state_cnt <= 0;
                    end
                end

                SERVO1_TO_NEG90: begin
                    //servo1_pw <= SERVO_NEG90;
                    //servo2_pw <= SERVO_0;

					if (servo1_pw > SERVO_NEG90 && pwm_cnt == 0)
                        servo1_pw <= servo1_pw - STEP;
					if(servo1_pw <= SERVO_NEG90) begin
                        delay <= delay + 1;
                        in <= 1;
                        if (delay > 100000) begin
						    state <= B_SERVO1_TO_90;
                            delay <= 0;
                        end
                    end
                    // final state, hold
                end

				B_SERVO1_TO_90: begin
					//servo1_pw <= SERVO_NEG90;
					//servo2_pw <= SERVO_0;
					if (servo1_pw < SERVO_90 && pwm_cnt == 0)
						servo1_pw <= servo1_pw + STEP;

					if(servo1_pw >= SERVO_90)
						state <= B_SERVO2_TO_NEG90;
				end

				B_SERVO2_TO_NEG90: begin
					//servo1_pw <= SERVO_90;
                    flag<=1;
					if(servo2_pw > SERVO_NEG90 && pwm_cnt == 0)
						servo2_pw <= servo2_pw - STEP;

                    if(servo2_pw <= SERVO_NEG90)
                        state <= IDEAL;
				end

                default: state <= INIT;

            endcase
        end
    end

endmodule
