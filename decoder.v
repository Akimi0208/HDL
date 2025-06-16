module decoder (
    input  wire [31:0] ieee_in,
    output reg  [7:0] int_part,
    output reg  [7:0] frac_part,
    output reg        sign_bit
);
    reg [7:0] exponent;
    reg [22:0] mantissa;
    reg [54:0] binary_result;  // ?? l?n ?? ch?a d? li?u d?ch
    integer shift;

    always @(*) begin
        // B??c 1: T�ch tr??ng IEEE
        sign_bit = ieee_in[31];
        exponent = ieee_in[30:23];
        mantissa = ieee_in[22:0];

        if (exponent == 0 && mantissa == 0) begin
            // S? 0
            int_part = 8'b0;
            frac_part = 8'b0;
        end else begin
            // B??c 2: Chu?n h�a mantissa: th�m 1 v�o ??u
            binary_result = {7'b0, 1'b1, mantissa, 24'b0};  // 1.M � 2^(exp - 127), ?? l?i room cho d?ch tr�i/ph?i

            // B??c 3: T�nh shift = exponent - 127
            shift = exponent - 127;

            if (shift > 0)
                binary_result = binary_result << shift;
            else
                binary_result = binary_result >> (-shift);

            // B??c 4: L?y ph?n nguy�n v� ph?n th?p ph�n
            int_part = binary_result[54:47];     // 8 bit ph?n nguy�n
            frac_part = binary_result[46:39];    // 8 bit ph?n th?p ph�n (sau d?u ch?m)
        end
    end
endmodule

