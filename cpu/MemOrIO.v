module MemOrIO(
    input        mRead,       // Memory Read Enable
    input        mWrite,      // Memory Write Enable
    input        ioRead,      // IO Read Enable
    input        ioWrite,     // IO Write Enable
    input  [31:0] addr_in,     // Address input from ALU
    input  [31:0] m_rdata,     // Data read from Memory
    input  [15:0] io_rdata,    // Data read from IO (only 16 bits valid)
    output [31:0] r_wdata,     // Data to register file (from memory or IO)
    input  [31:0] r_rdata,     // Data from register file (to be written to memory/IO)
    output reg [31:0] write_data, // Data to write into memory or IO
    output       LEDCtrl,     // LED device chip select
    output       SwitchCtrl,  // Switch device chip select
    output        NumberCtrl
);

assign LEDCtrl    = (addr_in == 32'hFFFF_F000);
    assign SwitchCtrl = (addr_in == 32'hFFFF_F010);
    assign NumberCtrl = (addr_in == 32'hFFFF_F020);

// write back to reg

assign r_wdata = (mRead)  ? m_rdata :
                 (ioRead) ? {16'h0000, io_rdata} :
                 32'h0000_0000; 





always @* begin
    if (mWrite || ioWrite) begin
        write_data = r_rdata;
    end else begin
        write_data = 32'hZZZZ_ZZZZ; //  write disabled
    end
end

endmodule
