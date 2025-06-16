`timescale 1ns / 1ps

module FPU_tb_file;

  reg clk, reset, start;
  reg sign_bit_a, sign_bit_b;
  reg [7:0] int_part_a, frac_part_a;
  reg [7:0] int_part_b, frac_part_b;
  reg [1:0] S;
  wire [31:0] result;
  wire sign_bit_result;
  wire [7:0] int_part_result, frac_part_result;
  wire done;
  wire [31:0] result_wire_add_sub, result_wire_multiply, result_wire_divide;

  integer i, test_count;
  integer fd, r;
  reg [1023:0] line;
  reg [31:0] expected_result;
  reg test_passed;

  reg [1:0] mem_S [0:99];
  reg mem_signA [0:99];
  reg [7:0] mem_intA [0:99];
  reg [7:0] mem_fracA [0:99];
  reg mem_signB [0:99];
  reg [7:0] mem_intB [0:99];
  reg [7:0] mem_fracB [0:99];
  reg [31:0] mem_expected [0:99];

  
  FPU_FSM dut (
    .clk(clk),
    .reset(reset),
    .start(start),
    .sign_bit_a(sign_bit_a),
    .int_part_a(int_part_a),
    .frac_part_a(frac_part_a),
    .sign_bit_b(sign_bit_b),
    .int_part_b(int_part_b),
    .frac_part_b(frac_part_b),
    .S(S),
    .result(result),
    .sign_bit_result(sign_bit_result),
    .int_part_result(int_part_result),
    .frac_part_result(frac_part_result),
    .done(done),
    .result_wire_add_sub(result_wire_add_sub),
    .result_wire_multiply(result_wire_multiply),
    .result_wire_divide(result_wire_divide)
  );

  
  always #10 clk = ~clk;

  
  initial begin
    $display("Reading test cases...");
    fd = $fopen("testcases.csv", "r");
    if (fd == 0) begin
      $display("ERROR: Cannot open file testcases.csv");
      $finish;
    end

    
    r = $fgets(line, fd);

    i = 0;
    while (!$feof(fd) && i < 100) begin
      r = $fgets(line, fd); 

      
      r = $sscanf(line, "%d,%d,%d,%d,%d,%d,%d,%h",
                  mem_S[i],
                  mem_signA[i],
                  mem_intA[i],
                  mem_fracA[i],
                  mem_signB[i],
                  mem_intB[i],
                  mem_fracB[i],
                  mem_expected[i]);

      
      if (r == 8)
        i = i + 1;
    end
    test_count = i;
    $fclose(fd);
    $display("Loaded %0d test cases.", test_count);
  end

  
  initial begin
    $dumpfile("fpu_fsm_tb.vcd");
    $dumpvars(0, FPU_tb_file);

    clk = 0;
    reset = 1;
    start = 0;
    test_passed = 1; 

    #20 reset = 0;

    for (i = 0; i < test_count; i = i + 1) begin
      S           = mem_S[i];
      sign_bit_a  = mem_signA[i];
      int_part_a  = mem_intA[i];
      frac_part_a = mem_fracA[i];
      sign_bit_b  = mem_signB[i];
      int_part_b  = mem_intB[i];
      frac_part_b = mem_fracB[i];
      expected_result = mem_expected[i];

      @(posedge clk);
      start = 1;
      @(posedge clk);
      start = 0;

      
      wait (done);
      @(posedge clk); 

      
      $display("Test %0d: S=%0b | A={%0d.%0d, sign=%0b}, B={%0d.%0d, sign=%0b}", 
               i, S, int_part_a, frac_part_a, sign_bit_a, int_part_b, frac_part_b, sign_bit_b);
      $display("  => Expected = 0x%08h | Got = 0x%08h %s", 
               expected_result, result,
               (expected_result === result) ? "[PASS]" : "[FAILLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL]");

      
      if (expected_result !== result) begin
        test_passed = 0;
        $display("    Mismatch detected!");
      end
    end

    
    if (test_passed) begin
      $display("All %0d tests PASSED!", test_count);
    end else begin
      $display("Some tests FAILED!");
    end

    $display("Simulation finished.");
    $finish;
  end

endmodule

