`timescale 1ns / 1ps

module DMem (
    input clk,
    input reset,
    input [2:0] funct3,
    input memRead,
    input memWrite,
    input [31:0] address,
    input [31:0] writeData,
    output reg [31:0] readData
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