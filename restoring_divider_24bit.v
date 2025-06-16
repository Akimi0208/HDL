module restoring_divider_24bit (
    input wire clk,
    input wire reset,
    input wire start,
    input wire [23:0] dividend,
    input wire [23:0] divisor,
    output reg [23:0] quotient,
    output reg done
);

    // Tr?ng thái FSM
	 reg [1:0] state;
    parameter IDLE = 0, OPERATE = 1, DONE = 2;

    // Thanh ghi n?i b?
    reg [48:0] temp;
    reg [4:0] count;
    reg [4:0] count2;

    // FSM logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state    <= IDLE;
            quotient <= 0;
            temp     <= 0;
            count    <= 0;
            count2   <= 0;
            done     <= 0;
        end else begin
            case (state)
                // ====================
                // IDLE: ch? tín hi?u start
                // ====================
                IDLE: begin
                    done <= 0;
                    if (start) begin
						      
                        temp[48] <=0;
								temp[47:0] <= { dividend, 24'b0}; 
								count <= 24;     
								count2 <= 0; 								
                        state <= OPERATE;
                    end
                end

                // ====================
                // OPERATE: th?c hi?n phép chia khôi ph?c
                // ====================
                OPERATE: begin
                    if (count > 0) begin
                        if (temp[48:24] >= divisor[23:0]) begin
                            temp[48:24] <= temp[48:24] - divisor;
                            temp[0] <= 1'b1;
                            count2 <= count2 + 1;
                        end else begin
                            temp <= temp << 1;
                        end
                        count <= count - 1;
                    end else begin
                        if (count2 > 1) begin
                            temp <= temp << 1;
                            count2 <= count2 - 1;
                        end else begin
                            state <= DONE;
                        end
                    end
                end

                // ====================
                // DONE: xu?t k?t qu?
                // ====================
                DONE: begin
                     quotient <= temp[23:0];
							done <= 1;
                     state <= IDLE;
                end
            endcase
        end
    end

endmodule

