`timescale 1ns/1ps

// Simplified Testbench: Unit-level testing of MemOrIO module (lw, IO read)
module tb_lw_complete;
    // Inputs to MemOrIO
    reg         mRead;
    reg         mWrite;
    reg         ioRead;
    reg         ioWrite;
    reg  [31:0] addr_in;
    reg  [31:0] m_rdata;
    reg  [11:0] io_rdata;
    reg  [31:0] r_rdata;

    // Outputs from MemOrIO
    wire [31:0] r_wdata;
    wire [31:0] m_wdata;
    wire        LEDCtrl;
    wire        SwitchCtrl;
    wire        NumberCtrl;

    // Instantiate only MemOrIO for unit testing
    MemOrIO dut (
        .mRead      (mRead),
        .mWrite     (mWrite),
        .ioRead     (ioRead),
        .ioWrite    (ioWrite),
        .addr_in    (addr_in),
        .m_rdata    (m_rdata),
        .io_rdata   (io_rdata),
        .r_rdata    (r_rdata),
        .r_wdata    (r_wdata),
        .m_wdata    (m_wdata),
        .LEDCtrl    (LEDCtrl),
        .SwitchCtrl (SwitchCtrl),
        .NumberCtrl (NumberCtrl)
    );

    initial begin
        // Initialize inputs
        mRead     = 0;
        mWrite    = 0;
        ioRead    = 0;
        ioWrite   = 0;
        addr_in   = 0;
        m_rdata   = 0;
        io_rdata  = 0;
        r_rdata   = 0;
        #10;

        // Test 1: lw from memory
        $display("-- Test 1: lw (memory) --");
        mRead     = 1;
        addr_in   = 32'h0000_0010;
        m_rdata   = 32'hDEADBEEF;
        #10;
        if (r_wdata === m_rdata)
            $display("[PASS] lw read data = 0x%08h", r_wdata);
        else
            $display("[FAIL] lw expected 0xDEADBEEF, got 0x%08h", r_wdata);
        mRead     = 0;
        #10;

        // Test 2: IO read from SwitchCtrl
        $display("-- Test 2: IO Read (Switch) --");
        ioRead    = 1;
        addr_in   = 32'hFFFFF010;
        io_rdata  = 12'hABC;
        #10;
        if (r_wdata === {20'd0, io_rdata})
            $display("[PASS] ioRead zero-extend = 0x%08h", r_wdata);
        else
            $display("[FAIL] ioRead expected 0x00000ABC, got 0x%08h", r_wdata);
        ioRead    = 0;
        #10;

        // Finish simulation
        $display("-- MemOrIO unit tests complete --");
        $finish;
    end
endmodule
