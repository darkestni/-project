`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/04 17:46:09
// Design Name: 
// Module Name: Decoder
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


module Decoder (
    input  [31:0] instruction,  
    output reg [31:0] imm32,       
        
    output [4:0]  rs1,         
    output [4:0]  rs2,         
    output [4:0]  rd,
    output [6:0]  opcode,
    output [2:0]  funct3,      
    output [6:0]  funct7                 
);


assign opcode = instruction[6:0];
assign rs1    = instruction[19:15];
assign rs2    = instruction[24:20];
assign rd     = instruction[11:7];
assign funct3 = instruction[14:12];
assign funct7 = instruction[31:25];


always @(*) begin
    case (instruction[6:0])
        // I-type
        7'b0010011, 7'b0000011, 7'b1100111: 
            imm32 ={{20{instruction[31]}}, instruction[31:20]};
        
        // S-type
        7'b0100011: 
            imm32 = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
        
        // SB-type
        7'b1100011: 
            imm32 = {{19{instruction[31]}}, instruction[31], instruction[7], 
                    instruction[30:25], instruction[11:8], 1'b0};
        
        // U-type
        7'b0110111, 7'b0010111: 
            imm32 = {instruction[31:12], 12'b0};
        
        // UJ-type
        7'b1101111: 
            imm32 = {{11{instruction[31]}}, instruction[31], instruction[19:12], 
                    instruction[20], instruction[30:21], 1'b0};
        
        default: 
            imm32 = 32'h0;
    endcase
end





endmodule
