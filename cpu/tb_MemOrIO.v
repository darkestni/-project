`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/11 15:21:25
// Design Name: 
// Module Name: tb_MemOrIO
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


`timescale 1ns / 1ps
`timescale 1ns / 1ps

module tb_MemOrIO();

reg         mRead, mWrite, ioRead, ioWrite;
reg  [31:0] addr_in, m_rdata, r_rdata;
reg  [15:0] io_rdata;
wire [31:0] r_wdata, write_data;
wire        LEDCtrl, SwitchCtrl;

MemOrIO uut (
    .mRead(mRead),
    .mWrite(mWrite),
    .ioRead(ioRead),
    .ioWrite(ioWrite),
    .addr_in(addr_in),
    .m_rdata(m_rdata),
    .io_rdata(io_rdata),
    .r_wdata(r_wdata),
    .r_rdata(r_rdata),
    .write_data(write_data),
    .LEDCtrl(LEDCtrl),
    .SwitchCtrl(SwitchCtrl)
);


initial begin
    // ≥ı ºªØ–≈∫≈
    mRead    = 0;
    mWrite   = 0;
    ioRead   = 0;
    ioWrite  = 0;
    addr_in  = 32'h0;
    m_rdata  = 32'h0;
    io_rdata = 16'h0;
    r_rdata  = 32'h0;

    #10;
    mRead    = 1;
    m_rdata  = 32'h12345678;
    #10;

    mRead = 0;


    #10;
    ioRead   = 1;
    io_rdata = 16'hABCD;
    #10;

    ioRead = 0;


    #10;
    mWrite  = 1;
    r_rdata = 32'hDEADBEEF;
    #10;

    mWrite = 0;


    #10;
    ioWrite = 1;
    r_rdata = 32'hCAFEBABE;
    #10;

    ioWrite = 0;

    #10;
    addr_in = 32'hFFFF_FC60;
    #10;



    #10;
    addr_in = 32'hFFFF_FC62;
    #10;


    #10;
    mRead   = 1;
    ioWrite = 1;
    m_rdata = 32'h11223344;
    r_rdata = 32'h55667788;
    #10;
 
    mRead   = 0;
    ioWrite = 0;

    #10;
 

    #10;
 
    $finish;
end



endmodule
