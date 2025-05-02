
`timescale 1ns / 1ps
//==============================================================================
// Description:
//     This module provides memory-mapped I/O support for peripherals such as 
//     DIP switches, buttons, LEDs, and seven-segment displays (7-seg). It decodes 
//     address inputs to determine which I/O device to interact with, handles 
//     read/write operations, and provides the appropriate data routing.
//
//     Supported devices:
//       - Button: readable via specific I/O address
//       - LEDs: writable via specific I/O address
//==============================================================================
module IOModule (
    input clk,                      // System clock
    input [31:0] address,           // Address to select which I/O device to access
    input [31:0] writeData,         // Data to be written to the I/O device
    input memWrite,                 // Enable signal for write operation
    input memRead,                  // Enable signal for read operation
    input [7:0] dipSwitch,          // Input from DIP switch (8 bits)
    input button,                   // Input from single push button
    output reg [31:0] readData,     // Data read from selected I/O device
    output reg [7:0] led,           // Output to 8-bit LED array
    output reg [6:0] seg,           // Output to 7-segment display segments (a¨Cg)
    output reg [3:0] an             // Output to 7-segment display anode controls (digit enable)
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