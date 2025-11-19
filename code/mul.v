module multiplier(
    input  wire        clk,
    input  wire        reset,         // <-- MODIFIED: Active-low reset
    input  wire        start,
    input  wire [7:0]  multiplicand,
    input  wire [7:0]  multiplier,
    output wire [15:0] op,
    output reg         mul_done       // <-- MODIFIED: Done flag
);

    //  registers
    reg [7:0] A, Q, M;
    reg       Q_1;
    reg [3:0] count;

    // Combinational 
    reg [7:0] nextA;
    reg [16:0] concat_shifted;

    // assign busy = (count < 8); // <-- REMOVED
    assign op   = {A, Q};

    // Combinational block (unchanged)
    always @(*) begin
        case ({Q[0], Q_1})
            2'b01: nextA = A + M;
            2'b10: nextA = A - M;
            default: nextA = A;
        endcase
        concat_shifted = {nextA, Q, Q_1};
        concat_shifted = {concat_shifted[16], concat_shifted[16:1]};
    end

    // Sequential logic
    always @(posedge clk or negedge reset) begin // <-- MODIFIED: negedge reset
        if (!reset) begin // <-- MODIFIED: Active-low check
            A        <= 8'b0;
            Q        <= 8'b0;
            M        <= 8'b0;
            Q_1      <= 1'b0;
            count    <= 4'd8; 
            mul_done <= 1'b0; // <-- MODIFIED: Reset done flag
        end
        else begin
            // By default, mul_done is low. It will only be asserted for one cycle.
            mul_done <= 1'b0;

            if (start) begin
                A     <= 8'b0;
                Q     <= multiplier;
                M     <= multiplicand;
                Q_1   <= 1'b0;
                count <= 4'b0;
            end
            else if (count < 8) begin
                {A, Q, Q_1} <= concat_shifted;
                count <= count + 1;
                
                // When count is 7, the operation is on its last cycle.
                // Signal that the multiplication will be done on the next clock edge.
                if (count == 4'd7) begin
                    mul_done <= 1'b1; // <-- MODIFIED: Assert done flag
                end
            end
        end
    end

endmodule