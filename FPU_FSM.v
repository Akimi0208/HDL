module FPU_FSM (
  input wire clk,
  input wire reset,
  input wire start,
  input wire       sign_bit_a,
  input wire [7:0] int_part_a,
  input wire [7:0] frac_part_a,  
  input wire       sign_bit_b,
  input wire [7:0] int_part_b,
  input wire [7:0] frac_part_b,
  input wire [1:0] S, // 00 = cong, 01 = tru, 10 = nhan, 11 = chia
  output reg [31:0] result,
  output wire       sign_bit_result,
  output wire [7:0] int_part_result,
  output wire [7:0] frac_part_result,  
  output reg done,
  output wire [31:0] result_wire_add_sub,
  output wire [31:0] result_wire_multiply,
  output wire [31:0] result_wire_divide
);

  reg [3:0] state;
  parameter IDLE = 4'b0000,
            UNPACK = 4'b0001,
            ALIGN = 4'b0010,
            OPERATE = 4'b0011,
            ADD_SUB = 4'b0100,
            MULTIPLY = 4'b0101,
            DIVIDE = 4'b0110,
            NORMALIZE = 4'b0111,
            PACK = 4'b1000,
            DONE = 4'b1001;

  wire [31:0] a;
  wire [31:0] b;
  wire add_sub_done;
  wire multiply_done;
  wire divider_done;

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

        UNPACK: state <= ALIGN;
        ALIGN:  state <= OPERATE;

        OPERATE: begin
          case (S)
            2'b00, 2'b01: state <= ADD_SUB;
            2'b10:       state <= MULTIPLY;
            2'b11:       state <= DIVIDE;
          endcase
        end

        ADD_SUB: begin
          if (add_sub_done) begin
            result <= result_wire_add_sub;
            state <= NORMALIZE;
          end
        end

        MULTIPLY: begin
          if (multiply_done) begin
            result <= result_wire_multiply;
            state <= NORMALIZE;
          end
        end

        DIVIDE: begin
          if (divider_done) begin
            result <= result_wire_divide;
            state <= NORMALIZE;
          end
        end

        NORMALIZE: state <= PACK;
        PACK:      state <= DONE;

        DONE: begin
          done <= 1;
          state <= IDLE;
        end
      endcase
    end
  end

  // C c module con
  fp_adder_subtractor adder_unit (
    .clk(clk),
    .reset(reset),
    .start(state == ADD_SUB),
    .a(a),
    .b(b),
    .subtract(S[0]),
    .result(result_wire_add_sub),
    .done(add_sub_done)
  );

  fp_mul_fsm mul_unit (
    .clk(clk),
    .rst(reset),
    .start(state == MULTIPLY),
    .a(a),
    .b(b),
    .result(result_wire_multiply),
    .done(multiply_done)
  );

  ieee754_divide_fsm div_unit (
    .clk(clk),
    .rst(reset),
    .start(state == DIVIDE),
    .a(a),
    .b(b),
    .result(result_wire_divide),
    .done(divider_done)
  );

  convert conv_a (
    .int_part(int_part_a),
    .frac_part(frac_part_a),
    .sign_bit(sign_bit_a),
    .ieee_out(a)
  );

  convert conv_b (
    .int_part(int_part_b),
    .frac_part(frac_part_b),
    .sign_bit(sign_bit_b),
    .ieee_out(b)
  );

  decoder dec_result (
    .ieee_in(result),
    .int_part(int_part_result),
    .frac_part(frac_part_result),
    .sign_bit(sign_bit_result)
  );

endmodule

