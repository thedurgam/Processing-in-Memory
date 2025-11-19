module ALU #(parameter SIZE = 5)
(
    input  wire          clk,
    input  wire          rst,
    input  wire [15:0]   a,         // First operand
    input  wire [15:0]   b,         // Second operand
    output reg  [15:0]   result,    // ALU result
    input  wire [SIZE-1:0] id,
    input  wire [1:0]    operation,
    output reg           op_done
);

    // Operation codes
    localparam ADD = 2'b01;
    localparam MUL = 2'b10;

    // --------------------
    // Multiplier signals
    // --------------------
    reg       mul_start;
    reg       mul_active;
    reg       mul_done_seen;
    reg [15:0] a_reg, b_reg;
    reg [7:0] b_reg_mul,a_reg_mul;
    wire [15:0] res_mul;
    // wire      mul_busy;      // <-- REMOVED
    wire      mul_done;      // <-- ADDED

    // --- MODIFIED INSTANTIATION ---
    multiplier mul (
        .clk(clk),
        .reset(rst),         // <-- ADDED: Pass-through reset
        .start(mul_start),
        .multiplicand(a_reg_mul),
        .multiplier(b_reg_mul),
        .op(res_mul),
        .mul_done(mul_done)    // <-- MODIFIED: From 'busy' to 'mul_done'
    );

    // --------------------
    // Serialized Adder signals
    // --------------------
    reg       add_start;
    reg       add_active;
    reg       add_done_seen;
    wire [15:0] add_sum;
    wire      add_done;

    bit_serial_add serial_add (
        .clk(clk),
        .rst(rst),
        .start(add_start),
        .a(a_reg),
        .b(b_reg),
        .sum(add_sum),
        .op_done(add_done)
    );

    // --------------------
    // ALU Control
    // --------------------
    reg [1:0] op_reg;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            // Reset everything
            result        <= 16'd0;
            op_done       <= 1'b0;
            mul_start     <= 1'b0;
            mul_active    <= 1'b0;
            mul_done_seen <= 1'b0;
            a_reg         <= 16'd0;
            b_reg         <= 16'd0;
            add_start     <= 1'b0;
            add_active    <= 1'b0;
            add_done_seen <= 1'b0;
        end 
        else begin
            // Defaults each cycle
            op_done   <= 1'b0;
            mul_start <= 1'b0;
            add_start <= 1'b0;
            op_reg    <= operation;

            case (op_reg)
                // --------------------
                // ADD path
                // --------------------
                ADD: begin
                    if (!add_active && !add_done_seen) begin
                        a_reg      <= a;
                        b_reg      <= b;
                        add_start  <= 1'b1;
                        add_active <= 1'b1;
                    end
                    else if (add_active && add_done) begin
                        result        <= add_sum;
                        op_done       <= 1'b1;
                        add_active    <= 1'b0;
                        add_done_seen <= 1'b1;
                    end
                end

                // --------------------
                // MUL path
                // --------------------
                MUL: begin
                    if (!mul_active && !mul_done_seen) begin
                        a_reg_mul  <= a[7:0];
                        b_reg_mul  <= b[7:0];
                        mul_start  <= 1'b1;
                        mul_active <= 1'b1;
                    end
                    // --- MODIFIED COMPLETION LOGIC ---
                    else if (mul_active && mul_done) begin // <-- MODIFIED: Check for done pulse
                        result        <= res_mul;
                        op_done       <= 1'b1;
                        mul_active    <= 1'b0;
                        mul_done_seen <= 1'b1;
                    end
                end

                // --------------------
                // Default / No-op
                // --------------------
                default: begin
                    op_done       <= 1'b0;
                    mul_active    <= 1'b0;
                    mul_done_seen <= 1'b0;
                    add_active    <= 1'b0;
                    add_done_seen <= 1'b0;
                end
            endcase
        end
    end

endmodule