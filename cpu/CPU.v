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
    input  [15:0] switch_in,  // ���뿪������
    output [15:0] led_out     // LED���
);

    wire [31:0] inst;         
    wire [31:0] imm32;         
    wire [4:0]  rs1, rs2, rd;  
    wire [6:0]  opcode;        
    wire [2:0]  funct3;        
    wire [6:0]  funct7;        
    wire        RegWrite;      // �Ĵ���дʹ��
    wire        ALUSrc;        // ALUԴѡ��
    wire [1:0]  ALUOp;         // ALU������
    wire        branch;        // ��֧�ź�
    wire        zero;          // ALU���־
    wire        MemRead;       // �ڴ��
    wire        MemWrite;      // �ڴ�д
    wire        ioRead;        // IO��
    wire        ioWrite;       // IOд
    wire        MemorIOtoReg;  // д������ѡ��
    wire [31:0] alu_result;    // ALU������
    wire [31:0] read_data1;    // �Ĵ���������1
    wire [31:0] read_data2;    // �Ĵ���������2
    wire [31:0] mem_io_data;   // �ڴ��IO��ȡ����
    wire [31:0] mem_out;       // �ڴ��ȡ����
    wire [31:0] pc;            // PC��ǰֵ
    wire [31:0] write_data;


    reg [31:0] registers[0:31];  

    IFetch u_IF (
        .clk(clk),
        .rst(rst),
        .branch(branch),
        .zero(zero),
        .imm32(imm32),
        .inst(inst),
        .pc(pc)
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
        .Alu_resultHigh(alu_result[31:10]),
        .RegWrite(RegWrite),
        .ALUSrc(ALUSrc),
        .ALUOp(ALUOp),
        .branch(branch),
        .MemorIOtoReg(MemorIOtoReg),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .ioRead(ioRead),
        .ioWrite(ioWrite)
    );

    //�Ĵ����ļ���д�߼� 
    always @(posedge clk) begin
        if (rst) begin
            // ��λʱ��ʼ�����мĴ���Ϊ0������x0��
            for (integer i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'b0;
            end
        end else if (RegWrite && (rd != 0)) begin
            // ��x0�Ĵ���д�룺ѡ��ALU������ڴ�/IO����
            registers[rd] <= (MemorIOtoReg) ? mem_io_data : alu_result;
        end
    end

    assign read_data1 = (rs1 != 0) ? registers[rs1] : 32'b0;  
    assign read_data2 = (rs2 != 0) ? registers[rs2] : 32'b0;

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

    DMem u_DMem (
        .clk(clk),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .addr(alu_result),       
        .din(write_data), // ʹ��MemOrIO������д����
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
        .LEDCtrl(LEDCtrl),
        .SwitchCtrl(SwitchCtrl)
);

    assign led_out = (LEDCtrl) ? read_data2[15:0] : 16'b0;

endmodule
