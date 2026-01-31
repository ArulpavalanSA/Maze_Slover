/*====================================================================
# Team ID      : eYRC#1913
# Theme        : MazeSolver Bot
# Author       : Arulpavalan S A
# File Name    : depth_first_search.v
# File Description :
#   FSM-based Maze Exploring Logic for MazeSolver Bot.
#   - Takes left/mid/right wall sensors as input.
#   - Decides movement: STOP / FORWARD / LEFT / RIGHT / UTURN.
#   - Tracks current position (x,y) in 9×9 grid.
#   - Maintains map to avoid loops.
#   - Handles dead-end detection using U-turn.
#
# Global Variables :
#   map_visited[][] → stores dead end entry cells
#   state            → movement FSM
#====================================================================*/

module depth_first_search (
    input clk,
    input rst_n,
    input left, mid, right,     // 0 - no wall, 1 - wall
    output reg [2:0] move       // encoded movement command
);

/*
| cmd | move  | meaning   |
|-----|-------|-----------|
| 000 | 0     | STOP      |
| 001 | 1     | FORWARD   |
| 010 | 2     | LEFT      |
| 011 | 3     | RIGHT     | 
| 100 | 4     | U_TURN    |

START POS   : 4,0
EXIT POS    : 4,8
DEADENDS    : 9
*/

////////////////// DO NOT MAKE ANY CHANGES ABOVE THIS LINE //////////////////

// Movement encodings
localparam STOP    = 3'b000;
localparam FORWARD = 3'b001;
localparam LEFTM   = 3'b010;
localparam RIGHTM  = 3'b011;
localparam UTURN   = 3'b100;

// FSM States
localparam FIND   = 3'd1;
localparam LEFT   = 3'd2;
localparam FRONT  = 3'd3;
localparam RIGHT  = 3'd4;
localparam TURN   = 3'd5;
localparam STOPP  = 3'd6;

// --------------------------------------------------------
// Internal Registers
// --------------------------------------------------------
reg [2:0] state;                       // FSM state
reg unsigned n,e,w,s;                  // orientation flags
reg map_visited [8:0][8:0];            // MAP to block dead end path and to locate the position 
reg deadend;                           // dead-end flag
reg a = 0;                             // start control flag
reg gate = 0;                          // map update trigger
reg reset = 0;

reg unsigned [3:0] x, y;               // current coordinates
reg unsigned [3:0] px, py;             // previous coordinates

// --------------------------------------------------------
// Initial Robot Orientation and Position
// --------------------------------------------------------
initial begin
    x  = 4; y = 0;                      // Start at (4,0)
    px = 4; py = 0;
    n = 1; e = 0; w = 0; s = 0;         // Facing North
    a = 0;
    deadend = 1;
    state = STOPP;
end

// --------------------------------------------------------
// Function : get_cell(xx, yy)
// Returns 1 if blocked / visited / out of range
// Returns 0 if free
// --------------------------------------------------------
function [1:0] get_cell;
    input unsigned [3:0] xx, yy;
    begin
        if (xx == 4 && yy == 9)
            get_cell = 0;                  // exit safe zone
        else if (xx < 0 || xx > 8 || yy < 0 || yy > 8)
            get_cell = 1;                  // boundary treated as wall
        else
            get_cell = map_visited[xx][yy];
    end
endfunction

// --------------------------------------------------------
// Wall presence on Left / Front / Right
// Combine internal visited-map check + sensor inputs
// --------------------------------------------------------
wire lw, rw, fw;

assign lw = (get_cell(x - (n - s), y + (e - w)) | left);
assign fw = (get_cell(x + (e - w), y + (n - s)) | mid);
assign rw = (get_cell(x + (n - s), y - (e - w)) | right);

// --------------------------------------------------------
// FSM (Triggered every NEG edge of clock)
// --------------------------------------------------------
always @(negedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Reset everything
        state <= STOPP;
        x <= 4; y <= 0;
        n <= 1; e <= 0; w <= 0; s <= 0;
        deadend <= 1;
        a <= 0;
        px <= 4; py <= 0;
        gate <= ~gate;
    end else begin

        case (state)

            // ------------------------------------------------
            // FIND State — Decide which direction to move
            // ------------------------------------------------
            FIND: begin
                px <= x; 
                py <= y;

                casez({lw, fw, rw})
                    3'b111: begin state <= TURN;    deadend = 1; end
                    3'b110: begin state <= RIGHT;                  end
                    3'b101: begin state <= FRONT;                  end
                    3'b011: begin state <= LEFT;                   end

                    default: begin
                        // directional decision based on orientation
                        if (deadend) gate = ~gate;

                        if (w) begin
                            if (!fw) state <= FRONT;
                            else if (!lw) state <= LEFT;
                            else if (!rw) state <= RIGHT;
                        end
                        if (s) begin
                            if (!rw) state <= RIGHT;
                            else if (!fw) state <= FRONT;
                            else if (!lw) state <= LEFT;
                        end
                        if (e) begin
                            if (!rw) state <= RIGHT;
                            else if (!fw) state <= FRONT;
                            else if (!lw) state <= LEFT;
                        end
                        if (n) begin
                            if (!lw) state <= LEFT;
                            else if (!rw) state <= RIGHT;
                            else if (!fw) state <= FRONT;
                        end
                    end
                endcase

                // Exit check
                if ((x == 4) && (y == 8) && a) begin
                    if (n) state <= FRONT;
                    if (w) state <= RIGHT;
                    if (e) state <= LEFT;
                end

                if ((x == 4) && (y == 8)) a <= 1;
            end

            // ------------------------------------------------
            // Turn around at Deadend
            // ------------------------------------------------
            TURN: begin
                move <= UTURN;
                state <= FIND;

                // flip orientation
                n <= s; s <= n;
                e <= w; w <= e;

                // step back
                x <= x - (e - w);
                y <= y - (n - s);
            end

            // ------------------------------------------------
            // TURN LEFT
            // ------------------------------------------------
            LEFT: begin
                move <= LEFTM;
                state <= FIND;

                w <= n; n <= e; e <= s; s <= w;
                x <= x - (n - s);
                y <= y + (e - w);
            end

            // ------------------------------------------------
            // MOVE FRONT
            // ------------------------------------------------
            FRONT: begin
                move <= FORWARD;
                state <= FIND;

                x <= x + (e - w);
                y <= y + (n - s);
            end

            // ------------------------------------------------
            // TURN RIGHT
            // ------------------------------------------------
            RIGHT: begin
                move <= RIGHTM;
                state <= FIND;

                e <= n; n <= w; w <= s; s <= e;
                x <= x + (n - s);
                y <= y - (e - w);
            end

            // ------------------------------------------------
            // STARTUP State
            // ------------------------------------------------
            STOPP: begin
                a <= 1;
                if (a == 1) begin
                    state <= FIND;
                    a <= 0;
                end
            end

        endcase
    end
end

// --------------------------------------------------------
// MAP UPDATE BLOCK — triggered by gate toggle
// --------------------------------------------------------
integer i, j;

always @(gate) begin
    if (!rst_n) begin
        // clear whole grid
        for (i = 0; i < 9; i = i + 1)
        for (j = 0; j < 9; j = j + 1)
            map_visited[i][j] = 0;
    end else begin
        // mark visited cell
        map_visited[px][py] = 1;
        deadend = 0;
    end
end

////////////////// DO NOT MAKE ANY CHANGES BELOW THIS LINE //////////////////

endmodule
