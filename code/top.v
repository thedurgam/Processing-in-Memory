module Top #(
    // Parameters for the PE grid
    parameter PE_GRID_SIZE = 4,
    parameter DATA_WIDTH   = 16,
    parameter ADDR_WIDTH   = 6,
    parameter ID_WIDTH     = 5
)
(
    input clk,
    input reset, // Active-low reset
    //input [3:0] PE_Addr, 
    //output [DATA_WIDTH-1:0] data,
    input [6*PE_GRID_SIZE-1:0] Instruction,
    // --- FIX: Correctly declared as an output port ---
    output [DATA_WIDTH*PE_GRID_SIZE-1:0] IO_buffer_E,
    output done,
    input instr_flag 
);

    // --- Internal Wires and Signals ---
    localparam NUM_PES = PE_GRID_SIZE * PE_GRID_SIZE;
    wire [DATA_WIDTH*PE_GRID_SIZE-1:0] IO_buffer_N;

    // --- Signals driven BY the Controller ---
    wire wea, web, ram_init;
    wire [ADDR_WIDTH-1:0] addra, addrb;
    wire east, west, south, north;
    wire [1:0] op;

    // --- Signals driven TO the Controller ---
    wire op_done;
    wire [3:0] opcode;
    wire [5:0] RegAddr;

    // --- Wires for the PE grid ---
    wire [DATA_WIDTH-1:0] DOA [NUM_PES-1:0];
    wire [DATA_WIDTH-1:0] DOB [NUM_PES-1:0];
    wire [DATA_WIDTH-1:0] EtoW [NUM_PES-1:0];
    wire [DATA_WIDTH-1:0] WtoE [NUM_PES-1:0];
    wire [DATA_WIDTH-1:0] StoN [NUM_PES-1:0];
    wire [DATA_WIDTH-1:0] NtoS [NUM_PES-1:0];
    wire [DATA_WIDTH-1:0] IO_buffer_N_array [PE_GRID_SIZE-1:0];
    wire [NUM_PES-1:0] alu_done;
    
    // --- Synthesizable array for initial BRAM weights ---
    wire [DATA_WIDTH-1:0] bram_init_values [NUM_PES-1:0];
    assign bram_init_values[0]  = 16'h2; assign bram_init_values[1]  = 16'h3;
    assign bram_init_values[2]  = 16'h4; assign bram_init_values[3]  = 16'h5;
    assign bram_init_values[4]  = 16'h1; assign bram_init_values[5]  = 16'h1;
    assign bram_init_values[6]  = 16'h1; assign bram_init_values[7]  = 16'h1;
    assign bram_init_values[8]  = 16'h1; assign bram_init_values[9]  = 16'h1;
    assign bram_init_values[10] = 16'h1; assign bram_init_values[11] = 16'h1;
    assign bram_init_values[12] = 16'h1; assign bram_init_values[13] = 16'h1;
    assign bram_init_values[14] = 16'h1; assign bram_init_values[15] = 16'h1;

    // Slicing instruction bits for controller and IO buffers
    assign IO_buffer_N = {{12'h0,Instruction[15:12]}, {12'h0,Instruction[11:8]}, {12'h0,Instruction[7:4]}, {12'h0,Instruction[3:0]}};
    assign opcode = Instruction[23:20];
    assign RegAddr = Instruction[21:16]; // Slice 6 bits for RegAddr
    
    assign IO_buffer_E = {EtoW[3], EtoW[7], EtoW[11], EtoW[15]};
    //assign data = DOA[PE_Addr];
    assign op_done = &alu_done;

    // --- Controller Instantiation ---
    Controller ctrl_inst (
        .clk        (clk),
        .reset_n    (reset),
        .RegAddr    (RegAddr),
        .addra      (addra),
        .addrb      (addrb),
        .wea        (wea),
        .web        (web),
        .north      (north),
        .south      (south),
        .east       (east),
        .west       (west),
        .ram_init   (ram_init),
        .operation  (op),
        .op_done    (op_done),
        .op_code    (opcode),
        .done       (done),
        .instr_flag(instr_flag)
    );

    // --- Generate Blocks ---
    genvar i;
    generate
        for (i = 0; i < PE_GRID_SIZE; i = i + 1) begin
            assign IO_buffer_N_array[i] = IO_buffer_N[(DATA_WIDTH*(i+1))-1 : DATA_WIDTH*i];
        end
    endgenerate

    genvar gi;
    generate
        for (gi = 0; gi < NUM_PES; gi = gi + 1) begin : PE_GRID
            PE_Block #(
                .DATA_WIDTH(DATA_WIDTH),
                .ADDR_WIDTH(ADDR_WIDTH),
                .ID_WIDTH(ID_WIDTH)
            ) block (
                .clk(clk), .reset(reset), .wea(wea), .web(web),
                .addra(addra), .addrb(addrb),
                .BRAM_IN(bram_init_values[gi]),
                .DOA(DOA[gi]), .DOB(DOB[gi]),
                .east(east), .west(west), .south(south), .north(north),
                .Ein(gi % PE_GRID_SIZE == PE_GRID_SIZE-1 ? 16'h0                       : WtoE[gi+1]),
                .Win(gi % PE_GRID_SIZE == 0               ? 16'h0                       : EtoW[gi-1]),
                .Nin(gi < PE_GRID_SIZE                    ? IO_buffer_N_array[gi]     : StoN[gi-PE_GRID_SIZE]),
                .Sin(gi >= (NUM_PES - PE_GRID_SIZE)       ? 16'h0                     : NtoS[gi+PE_GRID_SIZE]),
                .Eout(EtoW[gi]), .Wout(WtoE[gi]), .Nout(NtoS[gi]), .Sout(StoN[gi]),
                .ID(gi), .ram_init(ram_init),
                .op(op), .op_done(alu_done[gi])
            );
        end
    endgenerate

endmodule