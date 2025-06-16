module ieee754_divide_fsm (
    input wire clk, rst, start,
    input wire [31:0] a, b,
    output reg [31:0] result,
    output reg done
    
);

    reg [2:0] state;
    parameter IDLE = 0, DECODE = 1, DIVIDE = 2, NORMALIZE = 3, ASSEMBLE = 4, DONE = 5;

    reg sign_a, sign_b;
    reg [7:0] exponent_a, exponent_b;
    reg [23:0] mantissa_a, mantissa_b;
    reg result_sign;
    reg [23:0] quotient_reg;
    wire [23:0] quotient;
    reg [7:0] result_exponent;
    wire divider_done;

    restoring_divider_24bit divider (
        .clk(clk),
        .reset(rst),
        .start(state == DIVIDE),
        .dividend(mantissa_a),
        .divisor(mantissa_b),
        .quotient(quotient),
        .done(divider_done)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            done <= 0;
            result <= 0;
            result_exponent <= 0;
            quotient_reg <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    result_exponent <= 0;
                    quotient_reg <= 0;
                    if (start)
                        state <= DECODE;
                end

                DECODE: begin
                    if (a == 0 && b == 0) begin
                      result <=0;
                      state <= DONE;
                    end
                    sign_a <= a[31];
                    sign_b <= b[31];
                    exponent_a <= a[30:23];
                    exponent_b <= b[30:23];
                    mantissa_a <= {1'b1, a[22:0]};
                    mantissa_b <= {1'b1, b[22:0]};
                    result_sign <= a[31] ^ b[31];
                    state <= DIVIDE;
                end

                DIVIDE: begin
                    if (divider_done) begin
                        quotient_reg <= quotient;  // lu n reset l?i gi  tr?
                        result_exponent <= exponent_a - exponent_b + 127;
                        state <= NORMALIZE;
                    end
                end

                NORMALIZE: begin
                    if (quotient_reg[23] == 0) begin
                        quotient_reg <= quotient_reg << 1;
                        result_exponent <= result_exponent - 1;
                    end else begin
                        state <= ASSEMBLE;
                    end
                end

                ASSEMBLE: begin
                    result <= {result_sign, result_exponent, quotient_reg[22:0]};
                    state <= DONE;
                end

                DONE: begin
                    done <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
