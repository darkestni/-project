
`timescale 1ns / 1ps
// ģ����: CPU
// ����: RISC-V ������ CPU ����ģ�飬����ָ���ȡ�����롢���ơ�ALU�����ݴ洢���� IO ����
module CPU (
    input  clk,                 // ʱ���ź�
    input  rst,                 // ��λ�ź�
    input  [15:0] switch_in,    // �������루IO��
    output [15:0] led_out,       // LED �����IO��
    output [7:0] seg_data,      // ����ܶ���
        output [7:0] seg_data2,
        output [7:0] seg_cs
);
    // �ڲ��źŶ���
    wire [31:0] inst;           // ָ��
    wire [31:0] imm32;          // ������
    wire [4:0]  rs1, rs2, rd;   // �Ĵ�������
    wire [6:0]  opcode;         // ������
    wire [2:0]  funct3;         // ������
    wire [6:0]  funct7;         // ������
    wire        RegWrite;       // �Ĵ���дʹ��
    wire        ALUSrc;         // ALU Դѡ��
    wire [1:0]  ALUOp;          // ALU ��������
    wire        branch;         // ��֧�ź�
    wire        jump;           // ��ת�ź�
    wire        zero;           // ALU ���־
    wire        MemRead;        // �ڴ��ʹ��
    wire        MemWrite;       // �ڴ�дʹ��
    wire        ioRead;         // IO ��ʹ��
    wire        ioWrite;        // IO дʹ��
    wire        MemorIOtoReg;   // д������ѡ��
    wire [31:0] alu_result;     // ALU ���
    wire [31:0] read_data1;     // �Ĵ���������1
    wire [31:0] read_data2;     // �Ĵ���������2
    wire [31:0] mem_io_data;    // �ڴ�/IO ������
    wire [31:0] mem_out;        // �ڴ������
    wire [31:0] pc;             // ���������
    wire [31:0] write_data;     // д�ڴ�/IO ����
wire led_ctrl, sw_ctrl, number_ctrl;
    // �Ĵ����ļ�
    reg [31:0] registers[0:31];
    integer i;                  // ѭ���������Ƶ� always ����

    // ָ���ȡģ��
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

    // ָ�����ģ��
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

    // ����ģ��
    Controller u_Controller (
        .opcode(opcode),
        .ecall(2'b00),          // Ĭ�ϰ� ecall Ϊ 00
        .AluResultHigh(alu_result[31:10]), // �������˿�����
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

    // �Ĵ����ļ���д�߼�
    always @(posedge clk) begin
        if (rst) begin
            // Reset all registers to 0
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'b0;
            end
        end else if (RegWrite && (rd != 0)) begin
            // д�Ĵ������� x0����ѡ�� ALU ������ڴ�/IO ����
            registers[rd] <= MemorIOtoReg ? mem_io_data : alu_result;
        end
    end

    // �Ĵ���������
    assign read_data1 = (rs1 != 0) ? registers[rs1] : 32'b0;
    assign read_data2 = (rs2 != 0) ? registers[rs2] : 32'b0;

    // ALU ģ��
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

    // ���ݴ洢��ģ��
    DMem u_DMem (
        .clk(clk),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .addr(alu_result),
        .din(write_data),
        .dout(mem_out)
    );

    // �ڴ�/IO ����ģ��
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

    // LED ���
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