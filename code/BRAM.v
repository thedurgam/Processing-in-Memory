module BRAM #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 6,
    parameter RAM_DEPTH  = 1 << ADDR_WIDTH,
    parameter SIZE = 5
)(
    input clk,
    input wea, web,
    input [ADDR_WIDTH-1:0] addra, addrb,
    input [DATA_WIDTH-1:0] dia, dib,
    output reg [DATA_WIDTH-1:0] doa, dob,
    input [SIZE-1:0] id
);

    // A single memory, RAM_DEPTH deep and DATA_WIDTH wide
    reg [DATA_WIDTH-1:0] ram [0:RAM_DEPTH-1];

    // --- All logic for both ports MUST be in a SINGLE always block ---
    always @(posedge clk) begin
        
        // --- Port A Logic ---
        if (wea) begin
            ram[addra] <= dia; // Write on Port A
        end
        // The read for Port A happens UNCONDITIONALLY on every clock cycle.
        doa <= ram[addra];
    end
        
    always @(posedge clk) begin

        // --- Port B Logic ---
        if (web) begin
            ram[addrb] <= dib; // Write on Port B
        end
        // The read for Port B also happens UNCONDITIONALLY.
        dob <= ram[addrb];
        
    end
    
endmodule