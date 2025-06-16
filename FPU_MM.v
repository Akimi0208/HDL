module FPU_MM (
  input wire clk,
  input wire reset,

  // Avalon-MM Slave interface
  input wire [4:0]  address,
  input wire        write,
  input wire        read,
  input wire [31:0] writedata,
  output reg [31:0] readdata,
  input wire        chipselect
);

  // Registers for inputs
  reg sign_bit_a, sign_bit_b;
  reg [7:0] int_part_a, frac_part_a;
  reg [7:0] int_part_b, frac_part_b;
  reg [1:0] opcode;
  reg start_reg;
  wire done_wire;
  wire [31:0] result_wire;

  // Internal signal to detect edge of start
  reg start_prev;
  wire start_edge;
  assign start_edge = start_reg && ~start_prev;

  // Write logic
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      sign_bit_a <= 0;
      int_part_a <= 0;
      frac_part_a <= 0;
      sign_bit_b <= 0;
      int_part_b <= 0;
      frac_part_b <= 0;
      opcode <= 0;
      start_reg <= 0;
    end else if (chipselect && write) begin
      case (address)
        5'h00: sign_bit_a   <= writedata[0];
        5'h01: int_part_a   <= writedata[7:0];
        5'h02: frac_part_a  <= writedata[7:0];
        5'h03: sign_bit_b   <= writedata[0];
        5'h04: int_part_b   <= writedata[7:0];
        5'h05: frac_part_b  <= writedata[7:0];
        5'h06: opcode       <= writedata[1:0];
        5'h07: start_reg    <= writedata[0];
      endcase
    end
  end

  // Track previous start to detect edge
  always @(posedge clk or posedge reset) begin
    if (reset)
      start_prev <= 0;
    else
      start_prev <= start_reg;
  end

  // Read logic
  always @(*) begin
    readdata = 32'd0;
    if (chipselect && read) begin
      case (address)
        5'h08: readdata = result_wire;
        5'h09: readdata = {31'd0, done_wire};
      endcase
    end
  end

  // Instantiate the original FPU module
  FPU fpu_core (
    .clk(clk),
    .reset(reset),
    .start(start_edge),  // trigger start only on rising edge
    .sign_bit_a(sign_bit_a),
    .int_part_a(int_part_a),
    .frac_part_a(frac_part_a),
    .sign_bit_b(sign_bit_b),
    .int_part_b(int_part_b),
    .frac_part_b(frac_part_b),
    .S(opcode),
    .result(result_wire),
    .sign_bit_result(),        // optional: can expose if needed
    .int_part_result(),
    .frac_part_result(),
    .done(done_wire)
  );

endmodule
