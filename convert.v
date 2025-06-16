module convert (
    input  wire [7:0] int_part,      // ph?n nguy�n, VD: 10
    input  wire [7:0] frac_part,     // ph?n th?p ph�n, d?ng: frac/256, VD: 0.625 => 160
    input  wire       sign_bit,      // bit d?u
    output reg  [31:0] ieee_out      // output IEEE-754 32-bit
);

    reg [47:0] binary_combined;      // 48 bit ?? ch?a ph?n nguy�n + th?p ph�n
    integer i;
    integer shift;
    reg [7:0] exponent;
    reg [22:0] mantissa;

    always @(*) begin
        // B??c 1: chuy?n th�nh fixed-point nh? ph�n
        // D?i int_part v�o gi?a d�y bit, ph?n th?p ph�n n?m sau
        binary_combined = {int_part, frac_part[7:0]} << 16;

        // N?u l� s? 0 th� output lu�n l� 0
        if (binary_combined == 0) begin
            ieee_out = 32'b0;
        end else begin
            // B??c 2: Chu?n h�a - t�m bit 1 ??u ti�n t? tr�i
            shift = 0;
            while (binary_combined[47] == 0 && shift < 48) begin
                binary_combined = binary_combined << 1;
                shift = shift + 1;
            end

            // B??c 3: T�nh s? m?
            // V? tr� ban ??u c?a ph?n nguy�n l� bit 31
            // exponent th?c = 31 - shift
            exponent = 127 + (23 - shift);

            // B??c 4: T?o mantissa: b? bit 1 ??u ti�n, l?y 23 bit ti?p theo
            mantissa = binary_combined[46:24];

            // G?p th�nh IEEE-754: sign | exponent | mantissa
            ieee_out = {sign_bit, exponent, mantissa};
        end
    end
endmodule
