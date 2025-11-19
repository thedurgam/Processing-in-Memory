module Instruction_Fetcher #(
    parameter PROGRAM_LENGTH = 3,
    parameter INSTR_WIDTH    = 24,
    parameter ADDR_WIDTH     = 3
)
(
    input clk,
    input reset_n,     // Active-low reset for this module
    
    // Interface to Instruction BRAM
    input [INSTR_WIDTH-1:0] instruction_from_bram,
    output reg [ADDR_WIDTH-1:0] bram_address,
    output reg bram_enable,

    // Interface to the main processing core
    input core_done,
    output reg [INSTR_WIDTH-1:0] instruction_to_core,
    output reg core_reset_n,
    
    // Status
    output reg program_done,
    output reg new_fetch_pulse
);

    // --- State Machine Definition with a new dedicated reset state ---
    localparam S_IDLE        = 4'd0;
    localparam S_FETCH       = 4'd1;
    localparam S_WAIT_BRAM1  = 4'd2;
    localparam S_WAIT_BRAM2   = 4'd3;
    localparam S_RESET_CORE  = 4'd4; // <-- New state for the one-cycle reset pulse
    localparam instr_pulse   = 4'd5;
    localparam S_EXECUTE     = 4'd6;
    localparam S_FINISH      = 4'd7;
    
    reg [3:0] state, next_state;
    reg [ADDR_WIDTH-1:0] pc; // Program Counter

    // --- Sequential Logic Block (State and PC Registers) ---
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= S_IDLE;
            pc    <= 0;
        end else begin
            state <= next_state;
            if (state == S_EXECUTE && core_done && pc < PROGRAM_LENGTH) begin
                pc <= pc + 1;
            end
        end
    end

    // --- Combinational Logic Block (Next-State and Outputs) ---
    always @(*) begin
        // Default values for all outputs
        next_state          = state;
        program_done        = 1'b0;
        core_reset_n        = 1'b1; // Default to de-asserted
        bram_address        = pc;
        bram_enable         = (state == S_IDLE) ? 1'b0 : 1'b1;
        instruction_to_core = 0;
        new_fetch_pulse     = 1'b0;

        case(state)
            S_IDLE: begin
                 if(reset_n) next_state = S_FETCH; // Auto-start
            end
            S_FETCH: begin
                next_state = S_WAIT_BRAM1;
            end
            S_WAIT_BRAM1: begin
                next_state = S_WAIT_BRAM2;
            end
            S_WAIT_BRAM2: begin
                // After waiting for BRAM data, decide if we need to reset the core
                if (pc == 0) begin
                    next_state = S_RESET_CORE; // First instruction: go to reset state
                end else begin
                    next_state = instr_pulse;    // Subsequent instructions: skip reset
                end
            end

            S_RESET_CORE: begin
                // --- FIX: Assert reset only in this one-cycle state ---
                core_reset_n        = 1'b0;
                instruction_to_core = instruction_from_bram;
                next_state          = instr_pulse; // Immediately go to execute next
            end
            instr_pulse: begin
                instruction_to_core = instruction_from_bram;
                new_fetch_pulse     = 1'b1;
                next_state          = S_EXECUTE; // Immediately go to execute next
            end
            S_EXECUTE: begin
                instruction_to_core = instruction_from_bram;                
                if (core_done) begin
                    if (pc == PROGRAM_LENGTH-1) next_state = S_FINISH;
                    else                          next_state = S_FETCH;
                end
            end
            S_FINISH: begin
                program_done = 1'b1;
                //next_state   = S_IDLE;
            end
            default: begin
                next_state = S_IDLE;
            end
        endcase
    end

endmodule