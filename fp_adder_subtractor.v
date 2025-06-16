module fp_adder_subtractor (
    input wire clk,
    input wire reset,
    input wire start,
    input wire [31:0] a,
    input wire [31:0] b,
    input wire subtract, // 0 = c?ng, 1 = tr?
    output reg [31:0] result,
    output reg done
);

    // Tr?ng thái FSM
    reg [2:0] state;
    parameter IDLE = 3'd0,
              UNPACK = 3'd1,
              ALIGN = 3'd2,
              OPERATE = 3'd3,
              NORMALIZE = 3'd4,
              NORMALIZE_LOOP = 3'd5,
              PACK = 3'd6,
              DONE = 3'd7;

    // Thanh ghi t?m
    reg sign_a, sign_b, sign_res;
    reg [7:0] exp_a, exp_b, exp_res;
    reg [23:0] mant_a, mant_b;
    reg [24:0] mant_res;
    reg [7:0] exp_diff;
    reg [4:0] shift_count;

    // C? nh?n di?n NaN / Infinity
    reg is_nan_a, is_nan_b;
    reg is_inf_a, is_inf_b;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            result <= 0;
            done <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start)
                        state <= UNPACK;
                end

                UNPACK: begin
                    sign_a <= a[31];
                    sign_b <= b[31] ^ subtract;
                    exp_a <= a[30:23];
                    exp_b <= b[30:23];
                    mant_a <= (a[30:23] == 0) ? {1'b0, a[22:0]} : {1'b1, a[22:0]};
                    mant_b <= (b[30:23] == 0) ? {1'b0, b[22:0]} : {1'b1, b[22:0]};
                    
                    // Nh?n di?n NaN / Infinity
                    is_nan_a <= (a[30:23] == 8'b11111111) && (a[22:0] != 0);
                    is_nan_b <= (b[30:23] == 8'b11111111) && (b[22:0] != 0);
                    is_inf_a <= (a[30:23] == 8'b11111111) && (a[22:0] == 0);
                    is_inf_b <= (b[30:23] == 8'b11111111) && (b[22:0] == 0);

                    state <= ALIGN;
                end

                ALIGN: begin
                    // ?u tiên x? lý ??c bi?t
                    if (is_nan_a || is_nan_b) begin
                        result <= 32'h7FC00000; // quiet NaN
                        state <= DONE;
                    end else if (is_inf_a && is_inf_b) begin
                        if (sign_a == sign_b)
                            result <= {sign_a, 8'hFF, 23'b0}; // ? + ?
                        else
                            result <= 32'h7FC00000; // ? - ? = NaN
                        state <= DONE;
                    end else if (is_inf_a) begin
                        result <= {sign_a, 8'hFF, 23'b0};
                        state <= DONE;
                    end else if (is_inf_b) begin
                        result <= {sign_b, 8'hFF, 23'b0};
                        state <= DONE;
                    end else begin
                        // C?n ch?nh s? m? và d?ch mantissa
                        if (exp_a > exp_b) begin
                            exp_diff <= exp_a - exp_b;
                            mant_b <= mant_b >> (exp_a - exp_b);
                            exp_res <= exp_a;
                        end else begin
                            exp_diff <= exp_b - exp_a;
                            mant_a <= mant_a >> (exp_b - exp_a);
                            exp_res <= exp_b;
                        end
                        state <= OPERATE;
                    end
                end

                OPERATE: begin
                    if (sign_a == sign_b) begin
                        mant_res <= mant_a + mant_b;
                        sign_res <= sign_a;
                    end else begin
                        if (mant_a >= mant_b) begin
                            mant_res <= mant_a - mant_b;
                            sign_res <= sign_a;
                        end else begin
                            mant_res <= mant_b - mant_a;
                            sign_res <= sign_b;
                        end
                    end
                    state <= NORMALIZE;
                end

                NORMALIZE: begin
                    if (mant_res[24]) begin
                        mant_res <= mant_res >> 1;
                        exp_res <= exp_res + 1;
                        state <= PACK;
                    end else if (mant_res == 0) begin
                        exp_res <= 0;
                        state <= PACK;
                    end else begin
                        shift_count <= 0;
                        state <= NORMALIZE_LOOP;
                    end
                end

                NORMALIZE_LOOP: begin
                    if (mant_res[23] == 0 && exp_res > 0 && shift_count < 23) begin
                        mant_res <= mant_res << 1;
                        exp_res <= exp_res - 1;
                        shift_count <= shift_count + 1;
                    end else begin
                        state <= PACK;
                    end
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
