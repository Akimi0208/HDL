module Decoder (
    input sign,
    input [7:0] exponent,
    input [22:0] mantissa,
    output reg [15:0] int_part,
	 output reg [31:0] full_val,
	 output reg [37:0] aligned,
    output reg [15:0] frac_decimal
);
    
    reg [7:0] shift_amount;

    always @(*) begin
        // Mặc định
        int_part = 0;
        frac_decimal = 0;
        full_val = 0;
        aligned = 0;
		  shift_amount = 0;

        // Tạo 1.mantissa (bit 1 ẩn ở trước)
        full_val = mantissa;  // căn giữa thành 1.23 thành 32-bit fixed-point 9.23

        // Tính số bit cần shift (exponent - 127)
        if (exponent > 127) begin
            shift_amount = exponent - 127;
            aligned = full_val << shift_amount;
        end else begin
            shift_amount = 127 - exponent;
            aligned = full_val >> shift_amount;
        end

        // Tách phần nguyên và phần thập phân
        int_part = aligned[37:22];
        frac_decimal = {1'b0,aligned[21:7]};

        // Nếu bit dấu là 1 thì lấy bù 2 (âm)
        if (sign) begin
            int_part = ~int_part + 1;
            // phần thập phân có thể set = 0 hoặc giữ nguyên tùy yêu cầu
            frac_decimal = 0; // đơn giản hóa
        end
    end
endmodule
