module Controller (
    input  wire        clk,
    input  wire        reset_n,    // active-low reset
    input  wire [5:0]  RegAddr,
    output reg  [5:0]  addra,
    output reg  [5:0]  addrb,
    output reg         wea,
    output reg         web,
    output reg         north,
    output reg         south,
    output reg         east,
    output reg         west,
    output reg         ram_init,
    //output reg         move_add_res,
    output reg  [1:0]  operation,
    input  wire        op_done,
    input  wire [3:0]  op_code,
    output reg         done,
    input instr_flag
);

    // --- FSM State Encoding for the New Sequence ---
    parameter IDLE             = 5'd0;
    parameter RAM_INIT         = 5'd1;
    parameter MOVE_S           = 5'd2;
    parameter READ_FOR_MUL     = 5'd3;
    parameter MULTIPLY         = 5'd4;
    parameter LATCH_MUL        = 5'd5;
    parameter WRITEBACK_MUL    = 5'd6;
    parameter READ_MUL_FROM_B  = 5'd7;
    parameter WRITE_FROM_WEST  = 5'd8;
    parameter READ_FROM_WEST   = 5'd9;
    parameter READ_FOR_ADD     = 5'd10;
    parameter ADD              = 5'd11;
    parameter LATCH_ADD        = 5'd12;
    parameter WRITEBACK_ADD    = 5'd13;
    parameter READ_ADD_RESULT_B = 5'd14;
    parameter WRITE_FROM_WEST_1 = 5'd15;
    parameter READ_FROM_WEST_1  = 5'd16;
    parameter WRITE_FROM_WEST_2 = 5'd17;
    parameter READ_FROM_WEST_2  = 5'd18;
    // --- New Final Sequence States ---
    parameter READ_FOR_ADD_2    = 5'd19;
    parameter ADD_2             = 5'd20;
    parameter LATCH_ADD_2       = 5'd21;
    parameter WRITEBACK_ADD_2   = 5'd22;
    parameter READ_ADD_2_RESULT_B = 5'd23;
    parameter DONE              = 5'd24;
    
    reg [4:0] state, next_state;
    reg [2:0] move_cnt; // 3-bit counter for 8-cycle move
    reg [5:0] offset,RegAddr_reg;
    reg instr_flag_reg,op_done_reg;
    reg [3:0] op_code_reg;
    
    // --- State Register ---
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)begin
             state <= IDLE;
             offset <=3'b000;
             instr_flag_reg <=1'b0;
             op_done_reg <= 0;
            op_code_reg <= 0;
            RegAddr_reg <= 0;
        end
        else begin
                 state <= next_state;
                 
                 instr_flag_reg <=instr_flag;
                 op_done_reg <= op_done;
                op_code_reg <= op_code;
                RegAddr_reg <= RegAddr;
                
                 if(state==DONE && offset<3)
                    offset <= offset+1;
        end
    end

    // --- Counter for MOVE_S State ---
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)              move_cnt <= 3'b000;
        else if (state == MOVE_S)  move_cnt <= move_cnt + 1'b1;
        else                       move_cnt <= 3'b000;
    end

    // --- Next-State Logic ---
    always @(*) begin
        case (state)
            IDLE:            next_state = (op_code_reg==4'h0 && instr_flag_reg) ? RAM_INIT : IDLE;
            RAM_INIT:        next_state = MOVE_S;
            MOVE_S:          next_state = (move_cnt == 3'd7) ? READ_FOR_MUL : MOVE_S;
            READ_FOR_MUL:    next_state = MULTIPLY;
            MULTIPLY:        next_state = op_done_reg ? LATCH_MUL : MULTIPLY;
            LATCH_MUL:       next_state = WRITEBACK_MUL;
            WRITEBACK_MUL:   next_state = READ_MUL_FROM_B;
            READ_MUL_FROM_B: next_state = WRITE_FROM_WEST;
            WRITE_FROM_WEST: next_state = READ_FROM_WEST;
            READ_FROM_WEST:  next_state = READ_FOR_ADD;
            READ_FOR_ADD:    next_state = ADD;
            ADD:             next_state = op_done_reg ? LATCH_ADD : ADD;
            LATCH_ADD:       next_state = WRITEBACK_ADD;
            WRITEBACK_ADD:   next_state = READ_ADD_RESULT_B;
            READ_ADD_RESULT_B: next_state = WRITE_FROM_WEST_1;
            WRITE_FROM_WEST_1: next_state = READ_FROM_WEST_1;
            READ_FROM_WEST_1:  next_state = WRITE_FROM_WEST_2;
            WRITE_FROM_WEST_2: next_state = READ_FROM_WEST_2;
            // --- New State Transitions ---
            READ_FROM_WEST_2:  next_state = READ_FOR_ADD_2;
            READ_FOR_ADD_2:    next_state = ADD_2;
            ADD_2:             next_state = op_done_reg ? LATCH_ADD_2 : ADD_2;
            LATCH_ADD_2:       next_state = WRITEBACK_ADD_2;
            WRITEBACK_ADD_2:   next_state = READ_ADD_2_RESULT_B;
            READ_ADD_2_RESULT_B: next_state = DONE;
            DONE:            next_state = IDLE;
            default:         next_state = IDLE;
        endcase
    end

    // --- Output Logic ---
    always @(*) begin
        // Default outputs
        addra = 0; addrb = 0; wea = 0; web = 0; north = 0; south = 0;
        east = 0; west = 0; ram_init = 0; operation = 0; done = 0;
        
        case (state)
            RAM_INIT: begin ram_init = 1'b1; wea = 1'b1; addra = RegAddr_reg+offset; end
            MOVE_S: begin north = 1'b1; web = 1'b1; addrb = RegAddr_reg+offset + 6'd5; end
            READ_FOR_MUL: begin addra = RegAddr_reg+offset; addrb = RegAddr_reg+offset + 6'd5; end
            MULTIPLY: begin operation = 2'b10; addra = RegAddr_reg+offset; addrb = RegAddr_reg+offset + 6'd5; end
            LATCH_MUL: begin addra = RegAddr_reg+offset; addrb = RegAddr_reg+offset + 6'd5; end
            WRITEBACK_MUL: begin wea = 1'b1; addra = RegAddr_reg+offset + 6'd10; end
            READ_MUL_FROM_B: begin addrb = RegAddr_reg+offset + 6'd10; end //move_east
            WRITE_FROM_WEST: begin west = 1'b1; web = 1'b1; addrb = RegAddr_reg+offset + 6'd15; end
            READ_FROM_WEST: begin addrb = RegAddr_reg+offset + 6'd15; end
            READ_FOR_ADD: begin addra = RegAddr_reg+offset + 6'd10; addrb = RegAddr_reg+offset + 6'd15; end
            ADD: begin operation = 2'b01; addra = RegAddr_reg+offset + 6'd10; addrb = RegAddr_reg+offset + 6'd15; end
            LATCH_ADD: begin addra = RegAddr_reg+offset + 6'd10; addrb = RegAddr_reg+offset + 6'd15; end
            WRITEBACK_ADD: begin wea = 1'b1; addra = RegAddr_reg+offset + 6'd20; end
            READ_ADD_RESULT_B: begin addrb = RegAddr_reg+offset + 6'd20; end //move_east
            WRITE_FROM_WEST_1: begin west = 1'b1; web = 1'b1; addrb = RegAddr_reg+offset + 6'd25; end
            READ_FROM_WEST_1: begin addrb = RegAddr_reg+offset + 6'd25; end //move_east
            WRITE_FROM_WEST_2: begin west = 1'b1; web = 1'b1; addrb = RegAddr_reg+offset + 6'd30; end
            READ_FROM_WEST_2: begin addrb = RegAddr_reg+offset + 6'd30; end
            // --- New Output Logic ---
            READ_FOR_ADD_2: begin addra = RegAddr_reg+offset + 6'd20; addrb = RegAddr_reg+offset + 6'd30; end
            ADD_2: begin operation = 2'b01; addra = RegAddr_reg+offset + 6'd20; addrb = RegAddr_reg+offset + 6'd30; end
            LATCH_ADD_2: begin addra = RegAddr_reg+offset + 6'd20; addrb = RegAddr_reg+offset + 6'd30; end
            WRITEBACK_ADD_2: begin wea = 1'b1; addra = RegAddr_reg+offset + 6'd35; end
            READ_ADD_2_RESULT_B: begin addrb = RegAddr_reg+offset + 6'd35; end //move_east
            DONE: begin done = 1'b1;addrb = RegAddr_reg + offset + 6'd35;addra = RegAddr_reg + offset + 6'd10; end
        endcase
    end

endmodule