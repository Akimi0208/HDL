module restoring_divider_24bit (
    input wire [23:0] dividend,
    input wire [23:0] divisor,
    input wire start,
    input wire clk,
    input wire reset,
    output reg [23:0] quotient,
    output reg done
	 
);

reg [4:0] count;
reg [4:0] count2;
reg busy;
reg [48:0] temp;
reg [23:0] remainder;
always @(posedge clk or posedge reset) begin
    if (reset) begin
        quotient <= 0;
        remainder <= 0;
        done <= 0;
        busy <= 0;
        count <= 0;
		  count2 <= 0;
        temp <= 0;

    end
    else begin
        if (start && !busy) begin
				temp[48] <=0;
            temp[47:0] <= { dividend, 24'b0}; 
            count <= 24;                
            busy <= 1;
            done <= 0;
        end
        else if (busy) begin
            if (count > 0) begin
                if (temp[48:24] >= divisor[23:0]) begin						  
                    temp[48:24] <= temp[48:24] - divisor;
                    temp[0] <= 1; 
						  count2 <= count2 + 1;
                end
					 
					 else begin
							temp <= temp << 1;
					 end
						
                count <= count - 1;
				
            end
            else begin
						if (count2 > 1) begin
							temp <= temp << 1;
							count2 <= count2 - 1;
						end
						else begin// Xuất kết quả
							quotient <= temp[23:0];
							remainder <= temp[47:24];
							done <= 1;
							busy <= 0;
						end
            end
        end
    end
end

endmodule