module fp_mul_fsm (
    input clk,
    input rst,
    input start,
    input [31:0] a,
    input [31:0] b,
    output reg [31:0] result,
    output reg done
);

    // FSM states
    reg [2:0] state;
    parameter IDLE = 3'd0,
              UNPACK = 3'd1,
              MULTIPLY = 3'd2,
              NORMALIZE = 3'd3,
              ROUND = 3'd4,
              PACK = 3'd5,
              DONE = 3'd6;

    // Internal registers
    reg sign_a, sign_b, sign_res;
    reg [7:0] exp_a, exp_b, exp_res;
    reg [23:0] mant_a, mant_b;
    reg [47:0] mant_prod;
    reg [22:0] mant_res;
    reg guard, round_bit, sticky;
    reg [7:0] exp_tmp;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            done <= 0;
            result <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start) begin
                        if ((a[30:0] == 31'b0) || (b[30:0] == 31'b0)) begin
                            result <= {a[31] ^ b[31], 31'b0};
                            done <= 1;
                            state <= IDLE;
                        end else begin
                            state <= UNPACK;
                        end
                    end
                end

                UNPACK: begin
                    sign_a <= a[31];
                    sign_b <= b[31];
                    sign_res <= a[31] ^ b[31];
                    exp_a <= a[30:23];
                    exp_b <= b[30:23];
                    mant_a <= {1'b1, a[22:0]};
                    mant_b <= {1'b1, b[22:0]};
                    state <= MULTIPLY;
                end

                MULTIPLY: begin
                    mant_prod <= mant_a * mant_b;
                    exp_tmp <= exp_a + exp_b - 8'd127;
                    state <= NORMALIZE;
                end

                NORMALIZE: begin
                    if (mant_prod[47]) begin
                        mant_res <= mant_prod[46:24];
                        guard <= mant_prod[23];
                        round_bit <= mant_prod[22];
                        sticky <= |mant_prod[21:0];
                        exp_res <= exp_tmp + 1;
                    end else begin
                        mant_res <= mant_prod[45:23];
                        guard <= mant_prod[22];
                        round_bit <= mant_prod[21];
                        sticky <= |mant_prod[20:0];
                        exp_res <= exp_tmp;
                    end
                    state <= ROUND;
                end

                ROUND: begin
                    if (guard && (round_bit || sticky || mant_res[0])) begin
                        mant_res <= mant_res + 1;
                        if (mant_res == 23'h7FFFFF) begin // overflow
                            exp_res <= exp_res + 1;
                            mant_res <= 23'h400000;
                        end
                    end
                    state <= PACK;
                end

                PACK: begin
                    result <= {sign_res, exp_res, mant_res[22:0]};
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

