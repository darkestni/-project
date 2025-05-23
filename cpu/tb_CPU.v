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

    // 用例 0：输入 a=2，caseId = 000
    switch_in[10:8] = 3'b000;
    switch_in[7:0]  = 8'd2;
    #10;
    switch_in[11]=1'b1;
    #100;
    switch_in[11]=1'b0;
    // 用例 1：输入 a=5，写入寄存器
    switch_in[10:8] = 3'b001;
    switch_in[7:0]  = 8'd5;
    #10;
        switch_in[11]=1'b1;
        #100;
        switch_in[11]=1'b0;

    // 用例 2：输入 b=3，写入寄存器
    switch_in[10:8] = 3'b010;
    switch_in[7:0]  = 8'd3;
    #10;
        switch_in[11]=1'b1;
        #100;
        switch_in[11]=1'b0;

    // 用例 3：beq 比较 (5 == 3) -> false
    switch_in[10:8] = 3'b011;
   
        #200;


    // 用例 4：blt 比较 (5 < 3) -> false
    switch_in[10:8] = 3'b100;

        #200;


    // 用例 5：bltu 比较 (5 < 3) -> false
    switch_in[10:8] = 3'b101;
    #10;
        switch_in[11]=1'b1;
        #100;
        switch_in[11]=1'b0;

    // 用例 6：slt 比较 (5 < 3) -> false
    switch_in[10:8] = 3'b110;
    #10;
        switch_in[11]=1'b1;
        #100;
        switch_in[11]=1'b0;

    // 用例 7：sltu 比较 (5 < 3) -> false
    switch_in[10:8] = 3'b111;
    #10;
        switch_in[11]=1'b1;
        #100;
        switch_in[11]=1'b0;

    $display("Test completed.");
    $stop;
  end

endmodule