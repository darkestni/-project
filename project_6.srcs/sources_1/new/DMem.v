`timescale 1ns / 1ps

//==============================================================================
// Description:
//     This module implements the data memory (DMem) for the processor. It supports
//     both read and write operations with byte, half-word, and word granularity,
//     as determined by the funct3 input (as per RISC-V load/store encoding).
//     It is synchronous to the system clock and can be reset to an initial state.
//
//     The address is byte-addressed and should be word-aligned for 32-bit access.
//==============================================================================
module DMem (
    input clk,                      // System clock
    input reset,                    // Active-high reset signal
    input [2:0] funct3,             // Function code specifying data width (e.g., byte/half/word) for load/store
    input memRead,                  // Enables memory read operation
    input memWrite,                 // Enables memory write operation
    input [31:0] address,           // Memory address for read or write
    input [31:0] writeData,         // Data to be written to memory
    output reg [31:0] readData      // Data read from memory
);

    // ´æ´¢Æ÷¶¨Òå (64KB)
    reg [31:0] memory [0:16383]; // 64KB = 16384 ×Ö

    // ³õÊ¼»¯´æ´¢Æ÷
    integer i;
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 16384; i = i + 1) begin
                memory[i] <= 32'd0;
            end
        end
    end

    // Ð´²Ù×÷
    always @(posedge clk) begin
        if (memWrite) begin
            case (funct3)
                3'b000: memory[address[15:2]][7:0]   <= writeData[7:0];   // sb
                3'b001: memory[address[15:2]][15:0]  <= writeData[15:0];  // sh
                3'b010: memory[address[15:2]]        <= writeData;        // sw
                default: memory[address[15:2]]       <= writeData;
            endcase
        end
    end

    // ¶Á²Ù×÷
    always @(*) begin
        if (memRead) begin
            case (funct3)
                3'b000: readData = {{24{memory[address[15:2]][7]}}, memory[address[15:2]][7:0]};   // lb
                3'b001: readData = {{16{memory[address[15:2]][15]}}, memory[address[15:2]][15:0]};  // lh
                3'b010: readData = memory[address[15:2]];                                          // lw
                default: readData = memory[address[15:2]];
            endcase
        end else begin
            readData = 32'd0;
        end
    end

endmodule