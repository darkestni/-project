`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/28 18:29:01
// Design Name: 
// Module Name: ALU
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

module ALU (
    input [31:0] read_data1,
    input [31:0] read_data2,
    input [31:0] imm32,
    input [1:0] ALUOp,
    input [2:0] funct3,
    input [6:0] funct7,
    input ALUSrc,
    output reg [31:0] ALU_reslult,
    output zero
);

reg [3:0] ALUControl;
wire [31:0] operand2 = ALUSrc ? imm32 : read_data2;

always @* begin
    case(ALUOp)
        2'b00, 2'b01: ALUControl = {ALUOp, 2'b10};
        2'b10: begin
            case({funct7, funct3})
                {7'b0000000, 3'b000}: ALUControl = 4'b0010; // add
                {7'b0100000, 3'b000}: ALUControl = 4'b0110; // sub
                {7'b0000000, 3'b111}: ALUControl = 4'b0000; // and
                {7'b0000000, 3'b110}: ALUControl = 4'b0001; // or
                default: ALUControl = 4'b0000; // default to add
            endcase
        end
        default: ALUControl = 4'b0000; // default to add
    endcase
end

always @* begin
    case(ALUControl)
        4'b0010: ALU_reslult = read_data1 + operand2; // add
        4'b0110: ALU_reslult = read_data1 - operand2; // sub
        4'b0000: ALU_reslult = read_data1 & operand2; // and
        4'b0001: ALU_reslult = read_data1 | operand2; // or
        default: ALU_reslult = 32'b0; // default to 0
    endcase
end

// Generate zero signal
assign zero = (ALU_reslult == 32'b0);

endmodule
