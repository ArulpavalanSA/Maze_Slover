/*
# Team ID:          1913
# Theme:            Maze Solver bot
# Author List:      Arulpavalan S A
# Filename:         maze_move_sequence.v
# File Description: Generates predefined movement commands (FORWARD, LEFT,
#                   RIGHT, UTURN, STOP) based on the move count to guide
#                   the robot through the maze.
# Global variables: None
*/

module maze_move_sequence(
    input clk,                // System clock
    input rst_n,              // Active-low reset
    //input left, mid, right,  // Wall detection inputs 
    input ready,              // Indicates all sensors are ready
    input [7:0] count_move,   // Step counter indicating current move index
    output reg [2:0] move     // Movement command output
);

// -----------------------------------------------------------------------------
// Movement command encodings
// -----------------------------------------------------------------------------
localparam STOP    = 3'b000; // Stop the robot
localparam FORWARD = 3'b001; // Move forward
localparam LEFTM   = 3'b010; // Turn left
localparam RIGHTM  = 3'b011; // Turn right
localparam UTURN   = 3'b100; // Perform U-turn


always @(posedge clk) begin
/*
Purpose:
---
Generates the robot movement command based on the current move count.
Implements a predefined path by mapping count_move values to movement
directions. Resets movement when system is not ready or reset is asserted.
*/

    if(!rst_n || !ready) begin
        // Reset or sensor-not-ready condition: keep robot stopped
        move <= STOP;
    end 
    
    else begin
        // Lookup table mapping move count to movement command
        case (count_move)
            7'd0:   move <= FORWARD;
            7'd1:   move <= LEFTM;
            7'd2:   move <= LEFTM;
            7'd3:   move <= RIGHTM;
            7'd4:   move <= FORWARD;
            7'd5:   move <= FORWARD;
            7'd6:   move <= RIGHTM;
            7'd7:   move <= FORWARD;
            7'd8:   move <= RIGHTM;
            7'd9:   move <= LEFTM;
            7'd10:  move <= LEFTM;
            7'd11:  move <= UTURN;
            7'd12:  move <= LEFTM;
            7'd13:  move <= LEFTM;
            7'd14:  move <= RIGHTM;
            7'd15:  move <= RIGHTM;
            7'd16:  move <= FORWARD;
            7'd17:  move <= LEFTM;
            7'd18:  move <= RIGHTM;
            7'd19:  move <= LEFTM;
            7'd20:  move <= FORWARD;
            7'd21:  move <= LEFTM;
            7'd22:  move <= LEFTM;
            7'd23:  move <= UTURN;
            7'd24:  move <= LEFTM;
            7'd25:  move <= LEFTM;
            7'd26:  move <= RIGHTM;
            7'd27:  move <= LEFTM;
            7'd28:  move <= LEFTM;
            7'd29:  move <= UTURN;
            7'd30:  move <= RIGHTM;
            7'd31:  move <= RIGHTM;
            7'd32:  move <= LEFTM;
            7'd33:  move <= LEFTM;
            7'd34:  move <= UTURN;
            7'd35:  move <= FORWARD;
            7'd36:  move <= FORWARD;
            7'd37:  move <= RIGHTM;
            7'd38:  move <= FORWARD;
            7'd39:  move <= RIGHTM;
            7'd40:  move <= LEFTM;
            7'd41:  move <= RIGHTM;
            7'd42:  move <= FORWARD;
            7'd43:  move <= LEFTM;
            7'd44:  move <= LEFTM;
            7'd45:  move <= FORWARD;
            7'd46:  move <= RIGHTM;
            7'd47:  move <= FORWARD;
            7'd48:  move <= FORWARD;
            7'd49:  move <= RIGHTM;
            7'd50:  move <= UTURN;
            7'd51:  move <= LEFTM;
            7'd52:  move <= RIGHTM;
            7'd53:  move <= LEFTM;
            7'd54:  move <= UTURN;
            7'd55:  move <= LEFTM;
            7'd56:  move <= FORWARD;
            7'd57:  move <= FORWARD;
            7'd58:  move <= RIGHTM;
            7'd59:  move <= RIGHTM;
            7'd60:  move <= LEFTM;
            7'd61:  move <= LEFTM;
            7'd62:  move <= FORWARD;
            7'd63:  move <= LEFTM;
            7'd64:  move <= RIGHTM;
            7'd65:  move <= RIGHTM;
            7'd66:  move <= UTURN;
            7'd67:  move <= LEFTM;
            7'd68:  move <= LEFTM;
            7'd69:  move <= RIGHTM;
            7'd70:  move <= FORWARD;
            7'd71:  move <= RIGHTM;
            7'd72:  move <= RIGHTM;
            7'd73:  move <= LEFTM;
            7'd74:  move <= LEFTM;
            7'd75:  move <= FORWARD;
            7'd76:  move <= RIGHTM;
            7'd77:  move <= FORWARD;
            7'd78:  move <= LEFTM;
            7'd79:  move <= RIGHTM;
            7'd80:  move <= RIGHTM;
            7'd81:  move <= FORWARD;
            7'd82:  move <= RIGHTM;
            7'd83:  move <= FORWARD;
            7'd84:  move <= LEFTM;
            7'd85:  move <= FORWARD;
            7'd86:  move <= RIGHTM;
            7'd87:  move <= LEFTM;
            7'd88:  move <= LEFTM;
            7'd89:  move <= FORWARD;
            7'd90:  move <= FORWARD;
            7'd91:  move <= FORWARD;
            7'd92:  move <= FORWARD;
            7'd93:  move <= LEFTM;
            7'd94:  move <= LEFTM;
            7'd95:  move <= RIGHTM;
            7'd96:  move <= LEFTM;
            7'd97:  move <= FORWARD;
            7'd98:  move <= LEFTM;
            7'd99:  move <= LEFTM;
            7'd100: move <= UTURN;
            7'd101: move <= RIGHTM;
            7'd102: move <= RIGHTM;
            7'd103: move <= FORWARD;
            7'd104: move <= RIGHTM;
            7'd105: move <= LEFTM;
            7'd106: move <= RIGHTM;
            7'd107: move <= LEFTM;
            7'd108: move <= LEFTM;
            7'd109: move <= FORWARD;
            7'd110: move <= LEFTM;
            7'd111: move <= RIGHTM;
            7'd112: move <= LEFTM;
            7'd113: move <= RIGHTM;
            7'd114: move <= RIGHTM;
            7'd115: move <= FORWARD;
            7'd116: move <= RIGHTM;
            7'd117: move <= UTURN;
            7'd118: move <= RIGHTM;

            default: move <= STOP; // Safety default
        endcase
    end
end

//////////////////DO NOT MAKE ANY CHANGES BELOW THIS LINE //////////////////

endmodule
