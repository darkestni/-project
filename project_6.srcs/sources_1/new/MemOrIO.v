`timescale 1ns / 1ps

module MemOrIO (
    input mRead,
    input mWrite,
    input ioRead,
    input ioWrite,
    input [31:0] addr_in,
    output [31:0] addr_out,
    input [31:0] m_rdata,
    input [15:0] io_rdata,
    input [31:0] r_rdata,
    output [31:0] r_wdata,
    output reg [31:0] write_data,
    output LEDCtrl,
    output SwitchCtrl
);

    // ��ַ����
    // ���ݴ洢����0x00000000 - 0x0000FFFF
    // IO �豸��0xFFFFFC00 - 0xFFFFFFFF
    wire isDMem = (addr_in <= 32'h0000FFFF);
    wire isIO = (addr_in >= 32'hFFFFFC00 && addr_in <= 32'hFFFFFFFF);

    // ��ֱַ�Ӵ���
    assign addr_out = addr_in;

    // ����·�ɣ�д�ؼĴ����ļ���������Դ
    assign r_wdata = (ioRead && isIO) ? {16'd0, io_rdata} : // �� IO �豸��ȡ
                     (mRead && isDMem) ? m_rdata :          // �����ݴ洢����ȡ
                     32'hZZZZZZZZ;                          // Ĭ��ֵ

    // �����ź�����
    assign LEDCtrl = (ioWrite && addr_in == 32'hFFFFFC60) ? 1'b1 : 1'b0;
    assign SwitchCtrl = (ioRead && (addr_in == 32'hFFFFFC70 || addr_in == 32'hFFFFFC72)) ? 1'b1 : 1'b0;

    // д����·��
    always @(*) begin
        if (mWrite && isDMem) begin
            write_data = r_rdata;
        end else if (ioWrite && isIO) begin
            write_data = r_rdata;
        end else begin
            write_data = 32'hZZZZZZZZ;
        end
    end

endmodule