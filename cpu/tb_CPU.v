`timescale 1ns / 1ps

module tb_CPU();

  // 输入信号
  reg clk;
  reg rst;
  reg [15:0] switch_in;

  // 输出信号
  wire [15:0] led_out;
  wire [7:0] seg_data;
  wire [7:0] seg_data2;
  wire [7:0] seg_cs;

  // 实例化 CPU
  CPU uut (
    .clk(clk),
    .rst(rst),
    .switch_in(switch_in),
    .led_out(led_out),
    .seg_data(seg_data),
    .seg_data2(seg_data2),
    .seg_cs(seg_cs)
  );

  // 时钟生成（100MHz）
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // 主测试逻辑
  initial begin
    // 初始状态
    rst = 1;
    switch_in = 16'b0;
    #18;
    rst = 0;

    #2000;
    switch_in = 16'h0c18;
        #700;
    // case2
//    switch_in[12]=1'b0;
//    switch_in[10:8] = 3'b010;
//    switch_in[7:0]  = 8'b01010000;
//    #10;
//    switch_in[11]=1'b1;
//    #400;
    
//    switch_in[11]=1'b0;
//    switch_in[12]=1'b1;
//    switch_in[10:8] = 3'b010;
//    switch_in[7:0]  = 8'b01001000;
//    #20;
//    switch_in[11]=1'b1;
//    #400;
    
//    switch_in[11]=1'b0;
//    switch_in[12]=1'b0;
//    switch_in[10:8] = 3'b011;
//    switch_in[7:0]  = 8'b00000000;
//    #20;
//    switch_in[11]=1'b1;
//    #800;

    $display("Test completed.");
    $stop;
  end

endmodule