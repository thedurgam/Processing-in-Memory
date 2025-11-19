module PE_Block #(
    // Parameters are now consistent and clear
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 6,
    parameter ID_WIDTH   = 5
)
(
    input clk,
    input reset,
    input wea,
    input web,
    // Port widths now use the clear parameters
    input [ADDR_WIDTH-1:0] addra,
    input [ADDR_WIDTH-1:0] addrb,
    input [DATA_WIDTH-1:0] BRAM_IN,
    
    output[DATA_WIDTH-1:0] DOA,
    output[DATA_WIDTH-1:0] DOB,
    
    input east, west, south, north,
    input [DATA_WIDTH-1:0] Ein, Win, Nin, Sin,
    output[DATA_WIDTH-1:0] Eout, Wout, Nout, Sout,
    
    input [ID_WIDTH-1:0] ID,
    input ram_init,
    //input move_add_res,
    input [1:0] op,
    output op_done
);

    wire[DATA_WIDTH-1:0] DIA; 
    wire[DATA_WIDTH-1:0] DIB;
    wire[DATA_WIDTH-1:0] alu_result;

    assign Wout = DOB;
    assign Nout = DOB; 
    assign Sout = DOB;
    assign Eout = DOB;
    assign DIA  = ram_init ? BRAM_IN : wea ? alu_result : 16'h0;
    assign DIB  = east ? Ein : west ? Win : south ? Sin : north ? Nin : 16'h0;

    // --- BRAM Instantiation with Correct Parameter Mapping ---
    BRAM #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .SIZE(ID_WIDTH)
    ) regfile (
        .clk(clk),
        .wea(wea),
        .web(web),
        .addra(addra),
        .addrb(addrb),
        .dia(DIA),
        .dib(DIB),
        .doa(DOA),
        .dob(DOB),
        .id(ID)
    );

    // --- ALU Instantiation with Correct Parameter Mapping ---
    ALU #(
        .SIZE(ID_WIDTH) // The ALU's SIZE parameter corresponds to our ID_WIDTH
    ) alu_inst (
        .clk(clk),
        .rst(reset),
        .a(DOA),
        .b(DOB),
        .result(alu_result),
        .id(ID),
        .operation(op),
        .op_done(op_done)
    );

endmodule