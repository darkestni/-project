module Execute_Stage_Wrapper (
    // --- ����ID/EX��ˮ�߼Ĵ��������� ---
    input clk, // ��ȻALU����������߼�����EX��������ʱ�ӿ���
    input reset,

    // ����ͨ·ֵ
    input [31:0] pc_from_idex,
    input [31:0] rdata1_from_idex,
    input [31:0] rdata2_from_idex,
    input [31:0] imm32_from_idex,
    input [4:0]  rd_addr_from_idex,
    input [4:0]  rs1_addr_from_idex, // ����ת��
    input [4:0]  rs2_addr_from_idex, // ����ת��

    // �����ź� (����Controller_ID)
    input        regWrite_ctrl_from_idex,
    input        ALUSrc_ctrl_from_idex,
    input [2:0]  ALUOp_ctrl_from_idex,
    input        branch_ctrl_from_idex, // Controller_ID ����� branch_o
    input        jump_ctrl_from_idex,   // Controller_ID ����� jump_o
    input        isLoad_ctrl_from_idex,
    input        isStore_ctrl_from_idex,
    input        isEcall_ctrl_from_idex,
    input [1:0]  ecall_type_from_idex,
    input [2:0]  funct3_from_idex,      // ָ���funct3
    input [6:0]  funct7_from_idex,      // ָ���funct7


    // --- �����EX/MEM��ˮ�߼Ĵ��� ---
    // ����ͨ·ֵ
    output reg [31:0] alu_result_to_exmem,
    output reg        branch_condition_met_to_exmem,
    output reg [31:0] branch_target_addr_to_exmem, // ������ķ�֧/JALĿ���ַ
    output reg [31:0] rdata2_for_store_to_exmem, // ����swָ�������
    output reg [4:0]  rd_addr_to_exmem,          // Ŀ��Ĵ�����ַ

    // �����ź� (��������Controller_EX_Logic, ����͸��)
    output reg        final_RegWrite_to_exmem, // ���յ�дʹ�� (��Controller_EXȷ��)
    output reg        MemRead_to_exmem,
    output reg        MemWrite_to_exmem,
    output reg        IORead_to_exmem,
    output reg        IOWrite_to_exmem,
    output reg        MemToReg_to_exmem // ���ͨ�õ�DataSourceForWB
);

    wire [31:0] alu_result_internal;
    wire        branch_condition_met_internal;
    wire [21:0] alu_result_high_internal; // ALU�����λ��Controller_EX

    // 1. ����ALU�����߼�
    Execute_ALU_Logic alu_core_inst (
        .rdata1_in(rdata1_from_idex),
        .rdata2_in(rdata2_from_idex),
        .imm32_in(imm32_from_idex),
        .ALUSrc_in(ALUSrc_ctrl_from_idex),
        .ALUOp_ctrl_in(ALUOp_ctrl_from_idex),
        .funct3_in(funct3_from_idex),
        .funct7_in(funct7_from_idex),
        .is_ecall_in(isEcall_ctrl_from_idex),
        .ecall_type_in(ecall_type_from_idex),
        .alu_result_out(alu_result_internal),
        .branch_condition_met_out(branch_condition_met_internal)
    );

    // 2. �����֧/JALĿ���ַ (PC + imm)
    // ע�⣺JALR��Ŀ���ַ (rs1 + imm) ����alu_core_inst��ALUOp_ctrl_inΪ3'b000ʱ�����
    wire [31:0] calculated_branch_jal_target;
    assign calculated_branch_jal_target = pc_from_idex + imm32_from_idex;

    // ��ȡALU����ĸ�λ������Controller_EX_Logic
    assign alu_result_high_internal = alu_result_internal[31:10]; // ����ȡ��22λ

    // 3. ����Controller_EX_Logic (���ڴ�������ALU����Ŀ����ź�)
    Controller_EX_Logic controller_ex_inst (
        .isLoad_from_idex(isLoad_ctrl_from_idex),
        .isStore_from_idex(isStore_ctrl_from_idex),
        .isEcall_from_idex(isEcall_ctrl_from_idex),
        .ecall_type_from_idex(ecall_type_from_idex),
        .regWrite_from_idex(regWrite_ctrl_from_idex), // ID�׶ε�ԭʼregWrite
        .alu_result_high_from_ex(alu_result_high_internal),
        .MemRead_to_mem(MemRead_to_exmem),
        .MemWrite_to_mem(MemWrite_to_exmem),
        .IORead_to_mem(IORead_to_exmem),
        .IOWrite_to_mem(IOWrite_to_exmem),
        .final_RegWrite_to_wb(final_RegWrite_to_exmem), // ���ݵ�WB������RegWrite
        .MemToReg_to_wb(MemToReg_to_exmem)
    );

    // 4. ����߼���ʱ���߼����ڲ��źŸ������ (ͨ��������߼�����EX/MEM�Ĵ�������)
    always @(*) begin
        alu_result_to_exmem           = alu_result_internal;
        branch_condition_met_to_exmem = branch_condition_met_internal;
        // JALR��Ŀ���ַ��alu_result_internal (��ALUOpΪADD�Ҳ�����Ϊrs1��immʱ)
        // JAL��BRANCH��Ŀ���ַ��calculated_branch_jal_target
        // ��Ҫһ��ѡ������������PC�����߼��������ѡ��
        // �������Ǽ򵥵ؽ�PC+imm���ݳ�ȥ��PC�����߼�������Ƿ���JALR��ѡ��
        branch_target_addr_to_exmem   = calculated_branch_jal_target;
        rdata2_for_store_to_exmem     = rdata2_from_idex; // ͸��rs2�����ݣ�����store
        rd_addr_to_exmem              = rd_addr_from_idex;  // ͸��Ŀ��Ĵ�����ַ

        // MemRead_to_exmem, MemWrite_to_exmem���ź��Ѿ���controller_ex_inst�����ֱ�����ӡ�
        // final_RegWrite_to_exmem �� MemToReg_to_exmem Ҳ��controller_ex_inst�����ֱ�����ӡ�
    end
endmodule