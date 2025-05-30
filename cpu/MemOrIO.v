module MemOrIO(
     input        mRead,           // 内存读取使能
   input        mWrite,          // 内存写入使能
   input        ioRead,          // IO读取使能
   input        ioWrite,         // IO写入使能
   input  [31:0] addr_in,        // 来自ALU的地址
   input  [31:0] m_rdata,        // 从内存读取的数据
   input  [12:0] io_rdata,       // 从IO（SW）读取的数据（12位拨码）
   output [31:0] r_wdata,        // 写回寄存器的数据
   input  [31:0] r_rdata,        // 来自寄存器准备写入的数据
   output reg [31:0] m_wdata, // 实际写入内存
   output       LEDCtrl,         // 片选：LED
   output       SwitchCtrl,      // 片选：开关
   output       NumberCtrl       // 片选：数码管
);

assign LEDCtrl    = (addr_in == 32'hFFFF_F000);
    assign SwitchCtrl = (addr_in == 32'hFFFF_F010);
    assign NumberCtrl = (addr_in == 32'hFFFF_F020);

// write back to reg
//
assign r_wdata = (ioRead) ? io_rdata : m_rdata;




always @(*) begin
    if (mWrite) begin
        if (SwitchCtrl) begin
            m_wdata = {20'h00000, io_rdata[12:0]}; // 抽码读 IO，写入内存
        end else begin
            m_wdata = r_rdata; // 从存器写 IO (LED/数码符)
        end
    end else begin
        m_wdata = 32'b0;
    end
end

endmodule   