module Execute_Stage_Wrapper (
    input clk,
    input reset,

    // --- ���� ID/EX ��ˮ�߼Ĵ��������� ---
    // ����ͨ·
    input [31:0] rdata1_from_idex,
    input [31:0] rdata2_from_idex,
    input [31:0] imm32_from_idex,
    input [31:0] pc_from_idex,
    input [4:0]  rd_addr_from_idex,

    // �����ź�
    input        regWrite_ctrl_from_idex,   // �Ƿ�д�Ĵ��� (����Controller_ID)
    input        ALUSrc_ctrl_from_idex,
    input [3:0]  ALUOp_ctrl_from_idex,
    input        branch_ctrl_from_idex,     // ��֧����ָ�� (BEQ��JAL)
    input        jump_ctrl_from_idex,       // ��ת����ָ�� (JALR)
    input        isLoad_ctrl_from_idex,
    input        isStore_ctrl_from_idex,
    // input        isEcall_ctrl_from_idex,    // �źŴ���
    // input [1:0]  ecall_type_from_idex,      // �źŴ���

    // --- ����� EX/MEM ��ˮ�߼Ĵ��� ---
    // ����ͨ·
    output reg [31:0] alu_result_addr_to_exmem,  // PC+4,������ALU������ĵ�ַ/��� (���ݸ�MEM����Controller_EX) ALU ��ֱ�����
    output reg [31:0] rdata2_for_store_to_exmem,
    output reg [4:0]  rd_addr_to_exmem,

    // �����ź� (��Controller_EX_Logic���ɻ�͸��)
    output            MemRead_ctrl_to_exmem,     // ��Controller_EX����
    output            MemWrite_ctrl_to_exmem,    // ��Controller_EX����
    output            IORead_ctrl_to_exmem,      // ��Controller_EX����
    output            IOWrite_ctrl_to_exmem,     // ��Controller_EX����
    output            RegWrite_ctrl_to_exmem,    // ��Controller_EX����/�޸�
    output            MemToReg_ctrl_to_exmem,    // ��Controller_EX����
    // output reg        isEcall_ctrl_to_exmem,
    // output reg [1:0]  ecall_type_to_exmem,

    // --- ����� IF�׶� (����PC����) / Hazard Unit ---
    output reg        branch_or_jump_to_if,
    output reg [31:0] target_pc_ex
);

    // �ڲ��ź���
    wire [31:0] alu_operand_a;
    wire [31:0] alu_operand_b;
    wire [31:0] alu_arith_logic_result_internal; // ALU����������߼�������
    wire        alu_zero_flag;

    // 1. ALU������ѡ��
    assign alu_operand_a = rdata1_from_idex;
    assign alu_operand_b = ALUSrc_ctrl_from_idex ? imm32_from_idex : rdata2_from_idex;

    // 2. ʵ����ALU�����߼�
    Execute_ALU_Logic u_alu (
        .operand_a_from_ex(alu_operand_a),
        .operand_b_from_ex(alu_operand_b),
        .alu_op_from_ex(ALUOp_ctrl_from_idex),
        .alu_result_to_exmem(alu_arith_logic_result_internal), // ALU��ֱ������/�߼����
        .zero_flag_to_ex(alu_zero_flag)
    );

    // 3. ���� JAL/JALR ָ��ķ��ص�ַ (Link Address = PC + 4)
    wire [31:0] link_address_calc = pc_from_idex + 32'd4;

    // 4. ȷ������д��Ŀ��Ĵ��� rd ��ֵ �� ALU���/��ַ�����
    always @(*) begin
        if ((branch_ctrl_from_idex || jump_ctrl_from_idex) && regWrite_ctrl_from_idex) begin
            //��pc+4д��rd
            alu_result_addr_to_exmem = link_address_calc;
        end else begin
            //ALU��ֱ�����
            alu_result_addr_to_exmem = alu_arith_logic_result_internal;
        end

    end

    // ���� Controller_ID ������ JAL ָ��ʱ��Ҳ�Ὣ branch_ctrl_from_idex ��Ϊ 1'b1��
    // ͬʱ��Controller_ID ����������� ALUOp_ctrl_from_idex (�Լ����ܵ� ALUSrc_ctrl_from_idex ��ѡ�������)��
    // ʹ�� Execute_ALU_Logic ������� alu_zero_flag Ϊ 1'b1��������JAL �Ϳ��Ը��� BEQ �ġ�������������ת�����߼����Ӷ�ʵ����������ת��

    // ���� JALR: Controller_ID ���뽫 ALUOp_ctrl_from_idex ����Ϊִ�мӷ��������� (���� ALUOP_ADD)��
    // ���� ALUSrc_ctrl_from_idex ӦΪ 1'b1 ��ѡ�� imm32_from_idex ��ΪALU�ĵڶ�����������ALU�ĵ�һ���������� rdata1_from_idex (rs1��ֵ)��
    // ������ALU����� (alu_arith_logic_result_internal) ���� rs1 + imm��
    wire is_branch_type_ex;
    wire is_jalr_type_ex;
    wire condition_met_for_branch;
    wire [31:0] branch_jal_target_addr_calc;
    wire [31:0] jalr_target_addr_calc;

    assign is_branch_type_ex = branch_ctrl_from_idex;
    assign is_jalr_type_ex   = jump_ctrl_from_idex;
    assign condition_met_for_branch = alu_zero_flag;
    assign branch_jal_target_addr_calc = pc_from_idex + imm32_from_idex;
    assign jalr_target_addr_calc = alu_arith_logic_result_internal & ~32'h1;

    //����BEQ,JAL,JALRʱ branch_or_jump_to_if = 1
    always @(*) begin
        if (is_branch_type_ex && condition_met_for_branch) begin
            branch_or_jump_to_if = 1'b1;
            target_pc_ex            = branch_jal_target_addr_calc;
        end else if (is_jalr_type_ex) begin
            branch_or_jump_to_if = 1'b1;
            target_pc_ex            = jalr_target_addr_calc;
        end else begin
            branch_or_jump_to_if = 1'b0;
            target_pc_ex            = pc_from_idex + 32'd4;
        end
    end

    // 6. ʵ���� Controller_EX_Logic
    Controller_EX_Logic u_controller_ex (
        .isLoad_ctrl_from_wrapper(isLoad_ctrl_from_idex),
        .isStore_ctrl_from_wrapper(isStore_ctrl_from_idex),
        .regWrite_ctrl_from_wrapper(regWrite_ctrl_from_idex), // ����ID��ԭʼRegWrite
        .alu_result_addr_from_wrapper(alu_arith_logic_result_internal), // ALU����ĵ�ַ

        .MemRead_to_exmem(MemRead_ctrl_to_exmem),
        .MemWrite_to_exmem(MemWrite_ctrl_to_exmem),
        .IORead_to_exmem(IORead_ctrl_to_exmem),
        .IOWrite_to_exmem(IOWrite_ctrl_to_exmem),
        .RegWrite_to_exmem_final(RegWrite_ctrl_to_exmem), // ���ӵ���װ����RegWrite���
        .MemToReg_to_exmem(MemToReg_ctrl_to_exmem)
    );

    // 7. �������������EX/MEM��ˮ�߼Ĵ������ź�
    always @(*) begin
        // ����ͨ·͸��
        rdata2_for_store_to_exmem = rdata2_from_idex;
        rd_addr_to_exmem          = rd_addr_from_idex;

        // // �����ź�͸�� (Ecall���)
        // isEcall_ctrl_to_exmem     = isEcall_ctrl_from_idex;
        // ecall_type_to_exmem       = ecall_type_from_idex;
    end

endmodule
