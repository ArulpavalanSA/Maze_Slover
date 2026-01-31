module message(
    input clk,
    input reset,
    input ir_flag,
    input sensor_flag,
    input [7:0] T_integral,
    input [7:0] RH_integral,
    input [11:0] moist_data,
    input tx_done,
    output reg tx_start,
    output reg [7:0] data
);

    reg [5:0] char_index;
    reg [1:0] mode;  
    // 0 = idle
    // 1 = IR message
    // 2 = MM message
    // 3 = TH message

    reg ir_sent, sensor_sent;
    reg [7:0] moist_char;
    reg m_sent=0;

    // moisture decision
    always @(*) begin
        if (moist_data < 350)
            moist_char = "M";
        else
            moist_char = "D";
    end

    always @(posedge clk) begin
        if (~reset) begin
            char_index <= 0;
            tx_start   <= 0;
            mode <= 0;
            ir_sent <= 0;
            sensor_sent <= 0;
            m_sent<=0;
        end else begin

            // Trigger selection
            if (!ir_flag && !ir_sent)
                mode <= 1;
            else if (sensor_flag && !sensor_sent && !m_sent)
                mode <= 2;

            // UART logic
            if (tx_done == 0 && tx_start == 0 && mode != 0) begin
                tx_start <= 1;

                case (mode)

                // ================= IR MESSAGE =================
                1: begin
                    case (char_index)
                        0: data <= "M";
                        1: data <= "P";
                        2: data <= "I";
                        3: data <= "M";
                        4: data <= "-";
                        5: data <= "1";
                        6: data <= "9";
                        7: data <= "1";
                        8: data <= "3";
                        9: data <= "-";
                        10:data <= "#";
                        default: data <= "\n";
                    endcase
                end

                // ================= MM MESSAGE =================
                2: begin
                    m_sent<=1;
                    case (char_index)
                        0: data <= "M";
                        1: data <= "M";
                        2: data <= "-";
                        3: data <= "2";   // mpi-id
                        4: data <= "-";
                        5: data <= moist_char;
                        6: data <= "-";
                        7: data <= "#";
                        default: data <= "\n";
                    endcase
                end

                // ================= TH MESSAGE =================
                3: begin
                    case (char_index)
                        0: data <= "T";
                        1: data <= "H";
                        2: data <= "-";
                        3: data <= "2";   // mpi-id
                        4: data <= "-";
                        5: data <= (T_integral/10) + "0";
                        6: data <= (T_integral%10) + "0";
                        7: data <= "-";
                        8: data <= (RH_integral/10) + "0";
                        9: data <= (RH_integral%10) + "0";
                        10:data <= "-";
                        11:data <= "#";
                        default: data <= "\n";
                    endcase
                end

                endcase
            end

            // After one char transmitted
            else if (tx_done) begin
                tx_start <= 0;

                char_index <= char_index + 1;

                // End of IR message
                if (mode == 1 && char_index == 11) begin
                    char_index <= 0;
                    mode <= 0;
                    ir_sent <= 1;
                end

                // End of MM message → go to TH
                if (mode == 2 && char_index == 8) begin
                    char_index <= 0;
                    mode <= 3;
                end

                // End of TH message
                else if (mode == 3 && char_index == 12) begin
                    char_index <= 0;
                    mode <= 0;
                    sensor_sent <= 1;
                end
            end
        end
    end
endmodule