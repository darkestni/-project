
`timescale 1ns / 1ps
module VGAModule (
    input clk,
    input [31:0] address,
    input [31:0] writeData,
    input memWrite,
    output reg [3:0] vga_r, vga_g, vga_b,
    output reg vga_hs, vga_vs
);

    reg [0:0] vram [0:639][0:479];
    reg [9:0] hcount, vcount;

    localparam VGA_ADDR = 32'hFFFF1000;

    always @(posedge clk) begin
        if (memWrite && address >= VGA_ADDR && address < VGA_ADDR + 640*480/32) begin
            vram[(address - VGA_ADDR) % 640][(address - VGA_ADDR) / 640] <= writeData[0];
        end
    end

    always @(posedge clk) begin
        if (hcount < 799) hcount <= hcount + 1;
        else begin
            hcount <= 0;
            if (vcount < 524) vcount <= vcount + 1;
            else vcount <= 0;
        end
    end

    always @(*) begin
        vga_hs = (hcount < 704 || hcount >= 752) ? 1 : 0;
        vga_vs = (vcount < 523 || vcount >= 524) ? 1 : 0;
        if (hcount < 640 && vcount < 480 && vram[hcount][vcount])
            {vga_r, vga_g, vga_b} = {4'hF, 4'hF, 4'hF};
        else
            {vga_r, vga_g, vga_b} = {4'h0, 4'h0, 4'h0};
    end

endmodule