module InstructionDecode_ID_Stage (
    input clk,
    input reset,

    // --- ���� IF/ID ��ˮ�߼Ĵ��������� ---
    input [31:0] instruction_ifid,
    input [31:0] pc_ifid,
    // input [31:0] pc_plus_4_ifid, // ���JAL/JALR�ķ��ص�ַ�������ȡ

    // --- (�������ӵ��ڲ�RegisterFileʵ��) ����WB�׶ε�д���ź� ---
    input        reg_write_enable_from_wb,
    input [4:0]  write_addr_from_wb,
    input [31:0] write_data_from_wb,

    // --- ����� ID/EX ��ˮ�߼Ĵ��� (����ͨ·����) ---
    output [31:0] rdata1_to_ex,
    output [31:0] rdata2_to_ex,
    output reg [31:0] imm32_to_ex,
    output [4:0]  rd_addr_to_ex,
    output [4:0]  rs1_addr_to_ex,
    output [4:0]  rs2_addr_to_ex,
    output [31:0] pc_to_ex,
    // output [31:0] pc_plus_4_to_ex, // �����Ҫ����

    // --- ����� ID/EX ��ˮ�߼Ĵ��� (����Controller_ID�Ŀ����ź�) ---
    output regWrite_ctrl_to_ex,
    output ALUSrc_ctrl_to_ex,
    output [2:0] ALUOp_ctrl_to_ex, // ��Controller_ID��ALUOp_o���һ��
    output branch_ctrl_to_ex,
    output jump_ctrl_to_ex,
    output isLoad_ctrl_to_ex,
    output isStore_ctrl_to_ex,
    output isEcall_ctrl_to_ex,
    output [1:0] ecall_type_to_ex // ��ecall���ʹ��ݸ�EX�����ں�����ȷ����
);

    // �ڲ�����
    wire [6:0] opcode_w;
    wire [4:0] rs1_w;
    wire [4:0] rs2_w;
    wire [4:0] rd_w;
    wire [2:0] funct3_w; // funct3���ܱ�Controller_IDʹ��
    wire [6:0] funct7_w; // funct7���ܱ�Controller_IDʹ��
    wire [1:0] ecall_type_w;

    // --- 1. ָ���ֶ���ȡ ---
    assign opcode_w = instruction_ifid[6:0];
    assign rs1_w    = instruction_ifid[19:15];
    assign rs2_w    = instruction_ifid[24:20];
    assign rd_w     = instruction_ifid[11:7];
    assign funct3_w = instruction_ifid[14:12];
    assign funct7_w = instruction_ifid[31:25];
    assign pc_to_ex = pc_ifid;
    // assign pc_plus_4_to_ex = pc_plus_4_ifid;

    assign rs1_addr_to_ex = rs1_w;
    assign rs2_addr_to_ex = rs2_w;
    assign rd_addr_to_ex  = rd_w;

    // Ecall������ȡ (����ԭDecoder��ecall����߼�����)
    localparam OPCODE_ECALL_ID_STAGE  = 7'b1110011;
    localparam ECALL_TYPE_NONE_ID     = 2'b00;
    localparam ECALL_TYPE_READ_ID     = 2'b01; // ��Ӧ��ԭController�� ecall == 2'b01
    localparam ECALL_TYPE_WRITE_ID    = 2'b10; // ��Ӧ��ԭController�� ecall == 2'b10

    assign ecall_type_w = (opcode_w == OPCODE_ECALL_ID_STAGE && funct3_w == 3'b000) ?
                            ((instruction_ifid[31:20] == 12'd0) ? ECALL_TYPE_READ_ID :
                             (instruction_ifid[31:20] == 12'd1) ? ECALL_TYPE_WRITE_ID :
                                                                  ECALL_TYPE_NONE_ID) :
                                                                  ECALL_TYPE_NONE_ID;
    assign ecall_type_to_ex = ecall_type_w; // �������ʹ��ݵ�EX��

    // --- 2. �����Ĵ����� ---
    RegisterFile reg_file_inst (
        .clk(clk),
        .reset(reset),
        .read_addr1(rs1_w),
        .read_addr2(rs2_w),
        .reg_write_enable_wb(reg_write_enable_from_wb),
        .write_addr_wb(write_addr_from_wb),
        .write_data_wb(write_data_from_wb),
        .read_data1_id(rdata1_to_ex),
        .read_data2_id(rdata2_to_ex)
    );

    // --- 3. ���������� ---
    always @(*) begin
        imm32_to_ex = 32'd0; // Ĭ��ֵ
        case (opcode_w)
            7'b0110011: imm32_to_ex = 32'd0; // R-type
            7'b0010011: imm32_to_ex = {{20{instruction_ifid[31]}}, instruction_ifid[31:20]}; // I-type Arith
            7'b0000011: imm32_to_ex = {{20{instruction_ifid[31]}}, instruction_ifid[31:20]}; // I-type Load
            7'b1100111: imm32_to_ex = {{20{instruction_ifid[31]}}, instruction_ifid[31:20]}; // I-type jalr
            7'b0100011: imm32_to_ex = {{20{instruction_ifid[31]}}, instruction_ifid[31:25], instruction_ifid[11:7]}; // S-type
            7'b1100011: imm32_to_ex = {{19{instruction_ifid[31]}}, instruction_ifid[31], instruction_ifid[7], instruction_ifid[30:25], instruction_ifid[11:8], 1'b0}; // SB-type
            7'b0110111: imm32_to_ex = {instruction_ifid[31:12], 12'b0}; // U-type (lui)
            7'b0010111: imm32_to_ex = {instruction_ifid[31:12], 12'b0} + pc_ifid; // U-type (auipc)
            7'b1101111: imm32_to_ex = {{11{instruction_ifid[31]}}, instruction_ifid[31], instruction_ifid[19:12], instruction_ifid[20], instruction_ifid[30:21], 1'b0}; // UJ-type
            7'b1110011: imm32_to_ex = 32'd0; // ECALL
            default:    imm32_to_ex = 32'd0;
        endcase
    end

    // --- 4. ���� Controller_ID ģ�� ---
    Controller_ID controller_id_inst (
        .opcode(opcode_w),
        .funct3(funct3_w),         // ����funct3
        .funct7(funct7_w),         // ����funct7
        .ecall_type_in(ecall_type_w), // ʹ����ȡ����ecall����
        // ����Controller_ID���������ģ�������˿�
        .regWrite_o(regWrite_ctrl_to_ex),
        .ALUSrc_o(ALUSrc_ctrl_to_ex),
        .ALUOp_o(ALUOp_ctrl_to_ex),
        .branch_o(branch_ctrl_to_ex),
        .jump_o(jump_ctrl_to_ex),
        .isLoad_o(isLoad_ctrl_to_ex),
        .isStore_o(isStore_ctrl_to_ex),
        .isEcall_o(isEcall_ctrl_to_ex)
    );
endmodule