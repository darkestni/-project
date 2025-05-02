`timescale 1ns / 1ps

//==============================================================================
// Description:
//     This module acts as the control unit for a simple processor, generating
//     control signals based on the opcode, ecall, and the upper bits of the ALU
//     result. These signals control various components in the datapath, including
//     the register file, ALU, memory, and I/O subsystems.
//     
//     The module supports multiple instruction formats:
//       - R-type: Arithmetic and logical instructions (e.g., add, sub, and, or)
//       - I-type: Immediate arithmetic, load, and jump instructions (e.g., addi, lw, jalr)
//       - S-type: Store instructions (e.g., sw)
//       - SB-type: Branch instructions (e.g., beq, bne, blt)
//       - U-type: Upper immediate instructions (e.g., lui, auipc)
//       - UJ-type: Jump and link instructions (e.g., jal)
//       - ecall instructions: System calls like writing to an LED
//==============================================================================
module Controller (
    input [6:0] opcode,           // 7-bit opcode from the instruction; determines the instruction type
    input [1:0] ecall,            // ecall control signal indicating syscall type (e.g., read, write)
    input [21:0] AlUResultHigh,  // High 22 bits of ALU result used to distinguish memory vs. IO access
    output reg regWrite,          // Enables register file write
    output reg ALUSrc,            // Selects between register and immediate as second ALU operand
    output reg [1:0] ALUOp,       // ALU operation type signal (passed to ALU control unit)
    output reg branch,            // Branch instruction flag
    output reg jump,              // Jump instruction flag (jal/jalr)
    output reg MemOrIOtoReg,      // if memory/IO output write to register
    output reg MemRead,           // Enables memory read operation
    output reg MemWrite,          // Enables memory write operation
    output reg IORead,            // Enables IO read operation (e.g., switches, buttons)
    output reg IOWrite            // Enables IO write operation (e.g., LEDs)
);


    always @(*) begin
        // Ĭ��ֵ
        regWrite = 0;
        ALUSrc = 0;
        ALUOp = 2'b00;
        branch = 0;
        jump = 0;
        MemOrIOtoReg = 0;
        MemRead = 0;
        MemWrite = 0;
        IORead = 0;
        IOWrite = 0;

        case (opcode)
            7'b0110011: begin // R �� (add, sub, and, or)
                regWrite = 1;
                ALUSrc = 0;
                ALUOp = 2'b10;
            end
            7'b0010011: begin // I �� (addi)
                regWrite = 1;
                ALUSrc = 1;
                ALUOp = 2'b00;
            end
            7'b0000011: begin // I �� (lw)
                regWrite = 1;
                ALUSrc = 1;
                ALUOp = 2'b00;
                if (AlUResultHigh == 22'h3FFFFF) begin
                    IORead = 1; // ��ַ�� IO ��Χ��
                end else begin
                    MemRead = 1; // ��ַ�ڴ洢����Χ��
                end
            end
            7'b0100011: begin // S �� (sw)
                ALUSrc = 1;
                ALUOp = 2'b00;
                if (AlUResultHigh == 22'h3FFFFF) begin
                    IOWrite = 1; // ��ַ�� IO ��Χ��
                end else begin
                    MemWrite = 1; // ��ַ�ڴ洢����Χ��
                end
            end
            7'b1100011: begin // SB �� (beq, bne, blt)
                branch = 1;
                ALUOp = 2'b01;
            end
            7'b1101111: begin // UJ �� (jal)
                regWrite = 1;
                jump = 1;
                ALUOp = 2'b00;
            end
            7'b1100111: begin // I �� (jalr)
                regWrite = 1;
                jump = 1;
                ALUSrc = 1;
                ALUOp = 2'b00;
            end
            7'b0010111: begin // U �� (auipc)
                regWrite = 1;
                ALUSrc = 1;
                ALUOp = 2'b00;
            end
            7'b0110111: begin // U �� (lui)
                regWrite = 1;
                ALUSrc = 1;
                ALUOp = 2'b00;
            end
            7'b1110011: begin // ecall
                if (ecall == 2'b01) begin
                    regWrite = 1;
                    ALUOp = 2'b00;
                end else if (ecall == 2'b10) begin
                    IOWrite = 1; // ecall ���� 2��д LED
                end
            end
        endcase

        // MemOrIOtoReg �߼�
        MemOrIOtoReg = IORead || MemRead;
    end

endmodule