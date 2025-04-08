module Encoder (
    input [15:0] int_part,
    input [15:0] frac_part,
    output reg sign,
    output reg [7:0] exponent,
	 output reg [31:0] full_val,
    output reg [22:0] mantissa
);
    reg [31:0] shifted;
    reg [4:0] leading_one_pos;

    always @(*) begin
        // Giả sử chỉ xử lý số dương
        sign = 0;
        full_val = {int_part, frac_part[14:0]}; // fixed-point 16.16

        // Mặc định
        exponent = 0;
        mantissa = 0;
        leading_one_pos = 0;
        shifted = 0;


        // Tìm vị trí bit 1 đầu tiên, từ MSB đến LSz
		  if (full_val[30]) begin leading_one_pos = 31; shifted = full_val << 0; end
        else if (full_val[29]) begin leading_one_pos = 30; shifted = full_val << 1; end
        else if (full_val[28]) begin leading_one_pos = 29; shifted = full_val << 2; end
        else if (full_val[27]) begin leading_one_pos = 28; shifted = full_val << 3; end
        else if (full_val[26]) begin leading_one_pos = 27; shifted = full_val << 4; end
        else if (full_val[25]) begin leading_one_pos = 26; shifted = full_val << 5; end
        else if (full_val[24]) begin leading_one_pos = 25; shifted = full_val << 6; end
        else if (full_val[23]) begin leading_one_pos = 24; shifted = full_val << 7; end
        else if (full_val[22]) begin leading_one_pos = 23; shifted = full_val << 8; end
        else if (full_val[21]) begin leading_one_pos = 22; shifted = full_val << 9; end
        else if (full_val[20]) begin leading_one_pos = 21; shifted = full_val << 10; end
        else if (full_val[19]) begin leading_one_pos = 20; shifted = full_val << 11; end
        else if (full_val[18]) begin leading_one_pos = 19; shifted = full_val << 12; end
        else if (full_val[17]) begin leading_one_pos = 18; shifted = full_val << 13; end
        else if (full_val[16]) begin leading_one_pos = 17; shifted = full_val << 14; end
        else if (full_val[15]) begin leading_one_pos = 16; shifted = full_val << 15; end
        else if (full_val[14]) begin leading_one_pos = 15; shifted = full_val << 16; end
        else if (full_val[13]) begin leading_one_pos = 14; shifted = full_val << 17; end
        else if (full_val[12]) begin leading_one_pos = 13; shifted = full_val << 18; end
        else if (full_val[11]) begin leading_one_pos = 12; shifted = full_val << 19; end
        else if (full_val[10]) begin leading_one_pos = 11; shifted = full_val << 20; end
        else if (full_val[9]) begin leading_one_pos = 10; shifted = full_val << 21; end
        else if (full_val[8]) begin leading_one_pos = 9; shifted = full_val << 22; end
        else if (full_val[7]) begin leading_one_pos = 8; shifted = full_val << 23; end
        else if (full_val[6]) begin leading_one_pos = 7; shifted = full_val << 24; end
        else if (full_val[5]) begin leading_one_pos = 6; shifted = full_val << 25; end
        else if (full_val[4]) begin leading_one_pos = 5; shifted = full_val << 26; end
        else if (full_val[3]) begin leading_one_pos = 4; shifted = full_val << 27; end
        else if (full_val[2]) begin leading_one_pos = 3; shifted = full_val << 28; end
        else if (full_val[1]) begin leading_one_pos = 2; shifted = full_val << 29; end
        else if (full_val[0]) begin leading_one_pos = 1; shifted = full_val << 30; end
        else begin exponent = 0; mantissa = 0; end  // full_val = 0

        // Nếu full_val ≠ 0
        if (full_val != 0) begin
            exponent = leading_one_pos + 127 - 16; // bias 127
            mantissa = shifted[30:8]; // bỏ bit 1 đầu tiên, lấy 23 bit tiếp theo
        end
    end
endmodule   