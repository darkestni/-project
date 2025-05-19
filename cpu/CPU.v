`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/21 15:15:03
// Design Name: 
// Module Name: CPU
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

module CPU(
    input  clk,
    input  rst,
    input  [15:0] switch_in,    // 开关输入（IO）
    output [15:0] led_out,       // LED 输出（IO）
    output [7:0] seg_data,      // 数码管段码
    output [7:0] seg_data2,
    output [7:0] seg_cs

);
//    wire [2:0]  caseId;      // 用例编号（高3位）
//    wire [7:0]  dataIn;      // 输入数据（低8位）

//    assign caseId = switchIn[10:8];  
//    assign dataIn = switchIn[7:0];   
    wire [31:0] inst;         
    wire [31:0] imm32;         
    wire [4:0]  rs1;
     wire [4:0]  rs2; 
    wire [4:0]  rd;
    wire [6:0]  opcode;        
    wire [2:0]  funct3;        
    wire [6:0]  funct7;        
    wire        RegWrite;      // 寄存器写使能
    wire        ALUSrc;        // ALU源选择
    wire [1:0]  ALUOp;         // ALU操作码
    wire        branch;        // 分支信号
    wire        jump;
    wire        zero;          // ALU零标志
    wire        MemRead;       // 内存读
    wire        MemWrite;      // 内存写
    wire        ioRead;        // IO读
    wire        ioWrite;       // IO写
    wire        MemorIO_to_Reg;  // 写回数据选择
    wire [31:0] ALU_result;    // ALU计算结果
    wire [31:0] read_data1;    // 寄存器读数据1
    wire [31:0] read_data2;    // 寄存器读数据2
    wire [31:0] mem_io_data;   // 内存或IO读取数据
    wire [31:0] mem_out;       // 内存读取数据
 
    wire [31:0] write_data;
    wire led_ctrl,sw_ctrl,number_crtl;
    reg [31:0] registers[0:31];  

    IFetch u_IF (
        .clk(clk),
        .branch(branch),
        .zero(zero),
        .imm32(imm32),
        .inst(inst)
    );

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

    Controller u_Controller (
        .opcode(opcode),
        .ecall(2'b00),
        .ALU_result_high(ALU_result[31:10]),
        .RegWrite(RegWrite),
        .ALUSrc(ALUSrc),
        .ALUOp(ALUOp),
        .branch(branch),
        .jump(jump),
        .MemorIO_to_Reg(MemorIO_to_Reg),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .IORead(ioRead),
        .IOWrite(ioWrite)
    );

    //寄存器文件读写逻辑 
    always @(posedge clk) begin
        if (rst) begin
            // 复位时初始化所有寄存器为0（包括x0）
            for (integer i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'b0;
            end
        end else if (RegWrite && (rd != 0)) begin
            // 非x0寄存器写入：选择ALU结果或内存/IO数据
            registers[rd] <= (MemorIO_to_Reg) ? mem_io_data : ALU_result;
        end
    end

    assign read_data1 = (rs1 != 0) ? registers[rs1] : 32'b0;  
    assign read_data2 = (rs2 != 0) ? registers[rs2] : 32'b0;

    ALU u_ALU (
        .read_data1(read_data1),
        .read_data2(read_data2),
        .imm32(imm32),
        .ALUOp(ALUOp),
        .funct3(funct3),
        .funct7(funct7),
        .ALUSrc(ALUSrc),
        .ALU_result(ALU_result),
        .zero(zero)
    );

    DMem u_DMem (
        .clk(clk),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .mem_width(funct3[1:0]),
        .sign_ext(~funct3[2]),
        .addr(ALU_result),       
        .din(write_data), // 使用MemOrIO处理后的写数据
        .dout(mem_out)
    );

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
