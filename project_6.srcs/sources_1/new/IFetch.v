`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/21 14:38:26
// Design Name: 
// Module Name: IFetch
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module IFetch(
    input         rst,
    input         clk,       
    input         branch,    
    input         zero,      
    input  [31:0] imm32,    
    output [31:0] inst,
    output reg [31:0] pc
);

    wire [31:0] pc_next;     

    prgrom urom(
        .clka(clk),         
        .addra(pc[15:2]),    
        .douta(instruction) 
    );

    assign pc_next = (branch & zero) ? (pc + imm32) : (pc + 4);

    always @(posedge clk) begin
        pc <= pc_next;      // 时钟上升沿更新PC
    end

    initial begin
        pc = 32'h00000000;  
    end
endmodule
