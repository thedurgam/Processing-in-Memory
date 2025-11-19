module bit_serial_add (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,      // pulse high to start addition
    input  wire [15:0] a,
    input  wire [15:0] b,
    output reg  [15:0] sum,        // final 16-bit sum
    output reg         op_done
);

    // Internal registers
    reg [3:0]  bit_index;   // counts 0..15
    reg        carry;       // carry between bits
    reg [15:0] sum_reg;     // accumulates result
    reg        running;     // addition in progress

    // Sequential logic
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            sum        <= 16'd0;
            sum_reg    <= 16'd0;
            carry      <= 1'b0;
            bit_index  <= 4'd0;
            op_done    <= 1'b0;
            running    <= 1'b0;
        end
        else begin
            op_done <= 1'b0; // default

            if (start && !running) begin
                // Initialize addition
                running    <= 1'b1;
                bit_index  <= 4'd0;
                carry      <= 1'b0;
                sum_reg    <= 16'd0;
            end
            else if (running) begin
                // 1-bit addition
                sum_reg[bit_index] <= a[bit_index] ^ b[bit_index] ^ carry;
                carry <= (a[bit_index] & b[bit_index]) | (a[bit_index] & carry) | (b[bit_index] & carry);

                if (bit_index == 4'd15) begin
                    // Finished 16 bits
                    sum     <= sum_reg;
                    op_done <= 1'b1;
                    running <= 1'b0;
                end
                else begin
                    bit_index <= bit_index + 1;
                end
            end
        end
    end

endmodule
