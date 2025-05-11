//==============================================================================
// Description:
//     此模块作为流水线MEM阶段的核心逻辑，负责处理访存和I/O操作。路由地址和数据。
//     支持对数据存储器以及类似LED和开关的I/O设备的读写。

//==============================================================================
module MemOrIO_Pipeline (
    // from EX/MEM pipe reg
    input        MemRead_ctrl_from_exmem,     // 内存读使能信号
    input        MemWrite_ctrl_from_exmem,    // 内存写使能信号
    input        IORead_ctrl_from_exmem,      // I/O读使能信号 
    input        IOWrite_ctrl_from_exmem,     // I/O写使能信号 
    input [31:0] alu_result_addr_from_exmem,  // ALU计算结果作为地址 (来自EX级)
    input [31:0] rdata2_for_store_from_exmem, // 要写入的数据 (来自EX, 原rs2数据)

    input [31:0] data_read_from_dmem,         
    input [15:0] data_read_from_io,         

    // to mem/wb pipe reg
    output reg [31:0] data_read_to_memwb,     // 从内存或I/O读取的数据，送往WB

    // to mem/io
    output [31:0] addr_to_dmem_io,           // 将地址传递给DMEM和IO，DMEM或IO也要根据使能信号判断地址是否属于自己
    output reg [31:0] data_to_write_to_dmem_io, // 要写入的数据

    //to io
    output led_write_enable_to_io,           // LED写使能信号
    output switch_read_enable_to_io        // 开关读使能信号
);

    localparam IO_LED_ADDR          = 32'hFFFFFC60; // LED地址
    localparam IO_SWITCH_ADDR_LOW   = 32'hFFFFFC70; // 开关地址 (16位)

    assign addr_to_dmem_io = alu_result_addr_from_exmem;


    // 判断数据从IO还是DMEM读取
    always @(*) begin
        if (IORead_ctrl_from_exmem) begin //unsigned extend
            data_read_to_memwb = {16'd0, data_read_from_io}; 
        end else if (MemRead_ctrl_from_exmem) begin
            data_read_to_memwb = data_read_from_dmem;
        end else begin
            data_read_to_memwb = 32'h00000000;
        end
    end


    // 决定要写入内存或I/O设备的数据
    always @(*) begin
        if (MemWrite_ctrl_from_exmem || IOWrite_ctrl_from_exmem) begin
            data_to_write_to_dmem_io = rdata2_for_store_from_exmem;
        end else begin
            data_to_write_to_dmem_io = 32'h00000000;
        end
    end

    assign led_write_enable_to_io = (IOWrite_ctrl_from_exmem && (alu_result_addr_from_exmem == IO_LED_ADDR));
    assign switch_read_enable_to_io = (IORead_ctrl_from_exmem && (alu_result_addr_from_exmem == IO_SWITCH_ADDR_LOW));

endmodule
