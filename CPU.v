
`timescale 1ns / 1ps
// 模块名: CPU
// 描述: RISC-V 单周期 CPU 顶层模块，集成指令获取、解码、控制、ALU、数据存储器和 IO 处理
module CPU (
    input  clk,                 // 时钟信号
    input  rst,                 // 复位信号
    input  [15:0] switch_in,    // 开关输入（IO）
    output [15:0] led_out,       // LED 输出（IO）
    output [7:0] seg_data,      // 数码管段码
        output [7:0] seg_data2,
        output [7:0] seg_cs
);
    // 内部信号定义
    wire [31:0] inst;           // 指令
    wire [31:0] imm32;          // 立即数
    wire [4:0]  rs1, rs2, rd;   // 寄存器索引
    wire [6:0]  opcode;         // 操作码
    wire [2:0]  funct3;         // 功能码
    wire [6:0]  funct7;         // 功能码
    wire        RegWrite;       // 寄存器写使能
    wire        ALUSrc;         // ALU 源选择
    wire [1:0]  ALUOp;          // ALU 操作控制
    wire        branch;         // 分支信号
    wire        jump;           // 跳转信号
    wire        zero;           // ALU 零标志
    wire        MemRead;        // 内存读使能
    wire        MemWrite;       // 内存写使能
    wire        ioRead;         // IO 读使能
    wire        ioWrite;        // IO 写使能
    wire        MemorIOtoReg;   // 写回数据选择
    wire [31:0] alu_result;     // ALU 结果
    wire [31:0] read_data1;     // 寄存器读数据1
    wire [31:0] read_data2;     // 寄存器读数据2
    wire [31:0] mem_io_data;    // 内存/IO 读数据
    wire [31:0] mem_out;        // 内存读数据
    wire [31:0] pc;             // 程序计数器
    wire [31:0] write_data;     // 写内存/IO 数据
wire led_ctrl, sw_ctrl, number_ctrl;
    // 寄存器文件
    reg [31:0] registers[0:31];
    integer i;                  // 循环变量，移到 always 块外

    // 指令获取模块
    IFetch u_IF (
        .clk(clk),
        .rst(rst),
        .branch(branch),
        .jump(jump),
        .zero(zero),
        .imm32(imm32),
        .inst(inst),
        .pc(pc)
    );

    // 指令解码模块
    Decoder u_Decoder (
        .instruction(inst),
        .imm32(imm32),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7)
    );

    // 控制模块
    Controller u_Controller (
        .opcode(opcode),
        .ecall(2'b00),          // 默认绑定 ecall 为 00
        .AluResultHigh(alu_result[31:10]), // 已修正端口名称
        .RegWrite(RegWrite),
        .ALUSrc(ALUSrc),
        .ALUOp(ALUOp),
        .branch(branch),
        .jump(jump),
        .MemorIOtoReg(MemorIOtoReg),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .IORead(ioRead),
        .IOWrite(ioWrite)
    );

    // 寄存器文件读写逻辑
    always @(posedge clk) begin
        if (rst) begin
            // Reset all registers to 0
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'b0;
            end
        end else if (RegWrite && (rd != 0)) begin
            // 写寄存器（除 x0）：选择 ALU 结果或内存/IO 数据
            registers[rd] <= MemorIOtoReg ? mem_io_data : alu_result;
        end
    end

    // 寄存器读数据
    assign read_data1 = (rs1 != 0) ? registers[rs1] : 32'b0;
    assign read_data2 = (rs2 != 0) ? registers[rs2] : 32'b0;

    // ALU 模块
    ALU u_ALU (
        .ReadData1(read_data1),
        .ReadData2(read_data2),
        .imm32(imm32),
        .ALUOp(ALUOp),
        .funct3(funct3),
        .funct7(funct7),
        .ALUSrc(ALUSrc),
        .ALUResult(alu_result),
        .zero(zero)
    );

    // 数据存储器模块
    DMem u_DMem (
        .clk(clk),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .addr(alu_result),
        .din(write_data),
        .dout(mem_out)
    );

    // 内存/IO 控制模块
    MemOrIO u_MemOrIO (
        .mRead(MemRead),
        .mWrite(MemWrite),
        .ioRead(ioRead),
        .ioWrite(ioWrite),
        .addr_in(alu_result),
        .m_rdata(mem_out),
        .io_rdata(switch_in),
        .r_wdata(mem_io_data),
        .r_rdata(read_data2),
        .write_data(write_data),
        .LEDCtrl(led_ctrl),
          .SwitchCtrl(sw_ctrl),
          .NumberCtrl(number_ctrl)
    );

    // LED 输出
    assign led_out = ioWrite ? read_data2[15:0] : 16'b0;
    
    show_number show_inst (
            .clk(clk),
            .rst(rst),
            .data(number_ctrl ? write_data : 32'b0),
            .seg_data(seg_data),
            .seg_data2(seg_data2),
            .seg_cs(seg_cs)
        );
endmodule