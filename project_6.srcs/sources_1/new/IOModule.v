
`timescale 1ns / 1ps
module IOModule (
    input clk,
    input [31:0] address,
    input [31:0] writeData,
    input memWrite,
    input memRead,
    input [7:0] dipSwitch,
    input button,
    output reg [31:0] readData,
    output reg [7:0] led,
    output reg [6:0] seg,
    output reg [3:0] an
);

    localparam DIP_ADDR = 32'hFFFF0000;
    localparam BUTTON_ADDR = 32'hFFFF0004;
    localparam LED_ADDR = 32'hFFFF0008;
    localparam SEG_ADDR = 32'hFFFF000C;

    reg [6:0] seg_codes [0:9];
    initial begin
        seg_codes[0] = 7'b1000000;
        seg_codes[1] = 7'b1111001;
        seg_codes[2] = 7'b0100100;
        seg_codes[3] = 7'b0110000;
        seg_codes[4] = 7'b0011001;
        seg_codes[5] = 7'b0010010;
        seg_codes[6] = 7'b0000010;
        seg_codes[7] = 7'b1111000;
        seg_codes[8] = 7'b0000000;
        seg_codes[9] = 7'b0010000;
    end

    always @(*) begin
        if (memRead) begin
            case (address)
                DIP_ADDR: readData = {24'd0, dipSwitch};
                BUTTON_ADDR: readData = {31'd0, button};
                default: readData = 32'd0;
            endcase
        end else begin
            readData = 32'd0;
        end
    end

    always @(posedge clk) begin
        if (memWrite) begin
            case (address)
                LED_ADDR: led <= writeData[7:0];
                SEG_ADDR: begin
                    seg <= seg_codes[writeData[3:0]];
                    an <= 4'b1110;
                end
            endcase
        end
    end

endmodule