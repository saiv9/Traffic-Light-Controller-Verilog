// Two-road traffic light controller with six Moore FSM states.
// Outputs are active high and ordered as {red, yellow, green}.
module traffic_light_controller #(
    parameter integer GREEN_CYCLES = 10,
    parameter integer YELLOW_CYCLES = 3,
    parameter integer ALL_RED_CYCLES = 1
) (
    input  wire       clk,
    input  wire       rst_n,
    output reg  [2:0] ns_light,
    output reg  [2:0] ew_light
);

    localparam [2:0] NS_GREEN      = 3'd0;
    localparam [2:0] NS_YELLOW     = 3'd1;
    localparam [2:0] ALL_RED_TO_EW = 3'd2;
    localparam [2:0] EW_GREEN      = 3'd3;
    localparam [2:0] EW_YELLOW     = 3'd4;
    localparam [2:0] ALL_RED_TO_NS = 3'd5;

    localparam [2:0] RED    = 3'b100;
    localparam [2:0] YELLOW = 3'b010;
    localparam [2:0] GREEN  = 3'b001;

    function integer clog2;
        input integer value;
        integer temp;
        begin
            temp = value - 1;
            for (clog2 = 0; temp > 0; clog2 = clog2 + 1)
                temp = temp >> 1;
            if (clog2 < 1)
                clog2 = 1;
        end
    endfunction

    localparam integer MAX_DURATION =
        (GREEN_CYCLES > YELLOW_CYCLES) ?
            ((GREEN_CYCLES > ALL_RED_CYCLES) ? GREEN_CYCLES : ALL_RED_CYCLES) :
            ((YELLOW_CYCLES > ALL_RED_CYCLES) ? YELLOW_CYCLES : ALL_RED_CYCLES);

    localparam integer COUNTER_WIDTH = clog2(MAX_DURATION);

    reg [2:0] state;
    reg [COUNTER_WIDTH-1:0] cycle_count;

    `ifndef SYNTHESIS
    initial begin
        if (GREEN_CYCLES < 1 || YELLOW_CYCLES < 1 || ALL_RED_CYCLES < 1)
            $error("All phase lengths must be positive.");
    end
    `endif

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= NS_GREEN;
            cycle_count <= 0;
        end else begin
            case (state)
                NS_GREEN: begin
                    if (cycle_count == GREEN_CYCLES - 1) begin
                        state       <= NS_YELLOW;
                        cycle_count <= 0;
                    end else cycle_count <= cycle_count + 1'b1;
                end
                NS_YELLOW: begin
                    if (cycle_count == YELLOW_CYCLES - 1) begin
                        state       <= ALL_RED_TO_EW;
                        cycle_count <= 0;
                    end else cycle_count <= cycle_count + 1'b1;
                end
                ALL_RED_TO_EW: begin
                    if (cycle_count == ALL_RED_CYCLES - 1) begin
                        state       <= EW_GREEN;
                        cycle_count <= 0;
                    end else cycle_count <= cycle_count + 1'b1;
                end
                EW_GREEN: begin
                    if (cycle_count == GREEN_CYCLES - 1) begin
                        state       <= EW_YELLOW;
                        cycle_count <= 0;
                    end else cycle_count <= cycle_count + 1'b1;
                end
                EW_YELLOW: begin
                    if (cycle_count == YELLOW_CYCLES - 1) begin
                        state       <= ALL_RED_TO_NS;
                        cycle_count <= 0;
                    end else cycle_count <= cycle_count + 1'b1;
                end
                ALL_RED_TO_NS: begin
                    if (cycle_count == ALL_RED_CYCLES - 1) begin
                        state       <= NS_GREEN;
                        cycle_count <= 0;
                    end else cycle_count <= cycle_count + 1'b1;
                end
                default: begin
                    state       <= NS_GREEN;
                    cycle_count <= 0;
                end
            endcase
        end
    end

    // Outputs depend only on the current FSM state.
    always @(*) begin
        ns_light = RED;
        ew_light = RED;
        case (state)
            NS_GREEN: begin
                ns_light = GREEN;
                ew_light = RED;
            end
            NS_YELLOW: begin
                ns_light = YELLOW;
                ew_light = RED;
            end
            ALL_RED_TO_EW: begin
                ns_light = RED;
                ew_light = RED;
            end
            EW_GREEN: begin
                ns_light = RED;
                ew_light = GREEN;
            end
            EW_YELLOW: begin
                ns_light = RED;
                ew_light = YELLOW;
            end
            ALL_RED_TO_NS: begin
                ns_light = RED;
                ew_light = RED;
            end
            default: begin
                ns_light = RED;
                ew_light = RED;
            end
        endcase
    end

endmodule
