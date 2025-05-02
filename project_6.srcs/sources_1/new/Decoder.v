`timescale 1ns / 1ps


//==============================================================================
// Description:
//     This module is a simple instruction decoder that extracts various fields 
//     from the instruction (e.g., immediate value, registers, funct3, funct7, etc.)
//     and outputs the decoded values. It also provides control signals for the
//     control unit and the register file, and handles the instruction's 
//     immediate values (32-bit). The module also supports the ecall functionality 
//     (system call) for processing special instructions like writing to LEDs or 
//     reading from I/O.
//==============================================================================
module Decoder (
    input clk,                    // Clock input to synchronize the decoding process
    input reset,                  // Reset signal to initialize or reset the decoder
    input regWrite,               // Register write control signal (determines if register should be written)
    input [31:0] instruction,     // 32-bit instruction to be decoded
    input [4:0] writeAddress,     // The address (register number) to be written to
    input [31:0] writeData,       // Data to be written into the register
    input [31:0] pc,              // Program counter value (used for certain instruction types)
    
    output [31:0] rdata1,         // Data from the first source register (rs1)
    output [31:0] rdata2,         // Data from the second source register (rs2)
    output reg [31:0] imm32,      // Immediate value extracted from the instruction (32 bits)
    output [2:0] funct3,          // 3-bit funct3 field from the instruction (used for ALU control)
    output [6:0] funct7,          // 7-bit funct7 field from the instruction (used for ALU control)
    output [4:0] rd,              // Destination register (rd)
    output reg [1:0] ecall,        // ecall signal used for system calls (e.g., writing to LEDs)
    output [6:0] opcode
);
//=================== Parameter Declarations ===================
    parameter OPCODE_RTYPE  = 7'b0110011;
    parameter OPCODE_ITYPE  = 7'b0010011;
    parameter OPCODE_LOAD   = 7'b0000011;
    parameter OPCODE_JALR   = 7'b1100111;
    parameter OPCODE_STORE  = 7'b0100011;
    parameter OPCODE_BRANCH = 7'b1100011;
    parameter OPCODE_JAL    = 7'b1101111;
    parameter OPCODE_AUIPC  = 7'b0010111;
    parameter OPCODE_ECALL  = 7'b1110011;

    // ecall types
    parameter ECALL_NONE = 2'b00;
    parameter ECALL_READ = 2'b01;
    parameter ECALL_WRITE = 2'b10;


    reg [31:0] registers [31:0];
    integer i;

    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'd0;
            end
        end else if (regWrite && writeAddress != 5'd0) begin
            registers[writeAddress] <= writeData;
        end
    end

    assign opcode = instruction[6:0];
    wire [4:0] rs1 = instruction[19:15];
    wire [4:0] rs2 = instruction[24:20];
    assign rd = instruction[11:7];
    assign funct3 = instruction[14:12];
    assign funct7 = instruction[31:25];

    assign rdata1 = (rs1 == 5'd0) ? 32'd0 : registers[rs1];
    assign rdata2 = (rs2 == 5'd0) ? 32'd0 : registers[rs2];


//=================== Always Block ===================
always @(*) begin
    ecall = ECALL_NONE;
    case (opcode)
        OPCODE_RTYPE: begin  // R-type
            imm32 = 32'd0;
        end
        OPCODE_ITYPE, OPCODE_LOAD, OPCODE_JALR: begin  // I-type
            imm32 = {{20{instruction[31]}}, instruction[31:20]};
        end
        OPCODE_STORE: begin  // S-type
            imm32 = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
        end
        OPCODE_BRANCH: begin  // SB-type
            imm32 = {{19{instruction[31]}}, instruction[31], instruction[7],
                      instruction[30:25], instruction[11:8], 1'b0};
        end
        OPCODE_JAL: begin  // UJ-type
            imm32 = {{11{instruction[31]}}, instruction[31], instruction[19:12],
                      instruction[20], instruction[30:21], 1'b0};
        end
        OPCODE_AUIPC: begin
            imm32 = {instruction[31:12], 12'd0} + pc;
        end
        OPCODE_ECALL: begin
            imm32 = 32'd0;
            if (funct3 == 3'b000) begin
                if (instruction[31:20] == 12'd0)
                    ecall = ECALL_READ;
                else if (instruction[31:20] == 12'd1)
                    ecall = ECALL_WRITE;
            end
        end
        default: begin
            imm32 = 32'd0;
        end
    endcase
end


endmodule