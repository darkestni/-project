`timescale 1ns / 1ps

module tb_DebugMode();

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
  DebugMode uut (
    .clk(clk),
    .reset(rst),
    .switch_in(switch_in),
    .led(led_out),
    .seg1(seg_data),
    .seg2(seg_data2),
    .button(5'b0),
    .tub_control(seg_cs)
  );

//   module DebugMode(
//     input clk, 
//     input reset, // pass to cpu
//     input  [15:0] switch_in, // pass to cpu
//     output [15:0] led, // pass to cpu
//     input [4:0] button, //4 up 3 down 2 left 1 right 0 center
//     output wire[7:0]seg1,
//     output wire[7:0]seg2,
//     output wire[7:0]tub_control
// );

  // 时钟生成（100MHz）
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // 主测试逻辑
  initial begin
    // 初始状态
    rst = 1;
    switch_in = 16'b1;
    #800;
    rst = 0;
    #800
    rst = 1;
    #3000;
    switch_in[15] = ~switch_in[15];
        #300;
    switch_in[15] = ~switch_in[15];
        #300;
    switch_in[15] = ~switch_in[15];
        #300;
    switch_in[15] = ~switch_in[15];
        #300;
    switch_in[15] = ~switch_in[15];
        #300;
    switch_in[15] = ~switch_in[15];
        #300;
    switch_in[15] = ~switch_in[15];
        #300;
    switch_in[15] = ~switch_in[15];
        #300;
    switch_in[15] = ~switch_in[15];
        #300;
    switch_in[15] = ~switch_in[15];
            #300;
    switch_in[15] = ~switch_in[15];        #300;
    switch_in[15] = ~switch_in[15];        #300;
    switch_in[15] = ~switch_in[15];        #300;
    switch_in[15] = ~switch_in[15];        #300;
    switch_in[15] = ~switch_in[15];        #300;
    switch_in[15] = ~switch_in[15];        #300;
    switch_in[15] = ~switch_in[15];        #300;
    switch_in[15] = ~switch_in[15];        #300;
    switch_in[15] = ~switch_in[15];        #300;
    switch_in[15] = ~switch_in[15];        #300;
    switch_in[15] = ~switch_in[15];        #300;
    switch_in[15] = ~switch_in[15]; 
    #300;
    switch_in[0] = 1'b0;
    #5000000;
    switch_in[0] = 1'b1;
    switch_in[3:1] = 3'b101;
    // #300000;
    // switch_in[0] = 1'b1;
    // switch_in[15] = ~switch_in[15];
    //     #300;
    // switch_in[15] = ~switch_in[15];

    // #300;
    // switch_in[15] = ~switch_in[15];
    // #300;
    // switch_in[15] = ~switch_in[15];
    // #300;
    // switch_in[15] = ~switch_in[15];
    // #300;
    // switch_in[15] = ~switch_in[15];
    // #300;
    // switch_in[15] = ~switch_in[15];
    // #300;
    // switch_in[15] = ~switch_in[15];
    // #300;
    // switch_in[15] = ~switch_in[15];



        
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