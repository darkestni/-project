module Execute_Stage_Wrapper (
    input clk,
    input reset,

    // --- 来自 ID/EX 流水线寄存器的输入 ---
    // 数据通路
    input [31:0] rdata1_from_idex,
    input [31:0] rdata2_from_idex,
    input [31:0] imm32_from_idex,
    input [31:0] pc_from_idex,
    input [4:0]  rd_addr_from_idex,

    // 控制信号
    input        regWrite_ctrl_from_idex,   // 是否写寄存器 (来自Controller_ID)
    input        ALUSrc_ctrl_from_idex,
    input [3:0]  ALUOp_ctrl_from_idex,
    input        branch_ctrl_from_idex,     // 分支类型指令 (BEQ或JAL)
    input        jump_ctrl_from_idex,       // 跳转类型指令 (JALR)
    input        isLoad_ctrl_from_idex,
    input        isStore_ctrl_from_idex,
    // input        isEcall_ctrl_from_idex,    // 信号传递
    // input [1:0]  ecall_type_from_idex,      // 信号传递

    // --- 输出到 EX/MEM 流水线寄存器 ---
    // 数据通路
    output reg [31:0] alu_result_addr_to_exmem,  // PC+4,或者是ALU计算出的地址/结果 (传递给MEM级和Controller_EX) ALU 的直接输出
    output reg [31:0] rdata2_for_store_to_exmem,
    output reg [4:0]  rd_addr_to_exmem,

    // 控制信号 (由Controller_EX_Logic生成或透传)
    output            MemRead_ctrl_to_exmem,     // 由Controller_EX生成
    output            MemWrite_ctrl_to_exmem,    // 由Controller_EX生成
    output            IORead_ctrl_to_exmem,      // 由Controller_EX生成
    output            IOWrite_ctrl_to_exmem,     // 由Controller_EX生成
    output            RegWrite_ctrl_to_exmem,    // 由Controller_EX生成/修改
    output            MemToReg_ctrl_to_exmem,    // 由Controller_EX生成
    // output reg        isEcall_ctrl_to_exmem,
    // output reg [1:0]  ecall_type_to_exmem,

    // --- 输出到 IF阶段 (用于PC更新) / Hazard Unit ---
    output reg        branch_or_jump_to_if,
    output reg [31:0] target_pc_ex
);

    // 内部信号线
    wire [31:0] alu_operand_a;
    wire [31:0] alu_operand_b;
    wire [31:0] alu_arith_logic_result_internal; // ALU自身的算术逻辑运算结果
    wire        alu_zero_flag;

    // 1. ALU操作数选择
    assign alu_operand_a = rdata1_from_idex;
    assign alu_operand_b = ALUSrc_ctrl_from_idex ? imm32_from_idex : rdata2_from_idex;

    // 2. 实例化ALU核心逻辑
    Execute_ALU_Logic u_alu (
        .operand_a_from_ex(alu_operand_a),
        .operand_b_from_ex(alu_operand_b),
        .alu_op_from_ex(ALUOp_ctrl_from_idex),
        .alu_result_to_exmem(alu_arith_logic_result_internal), // ALU的直接算术/逻辑结果
        .zero_flag_to_ex(alu_zero_flag)
    );

    // 3. 计算 JAL/JALR 指令的返回地址 (Link Address = PC + 4)
    wire [31:0] link_address_calc = pc_from_idex + 32'd4;

    // 4. 确定最终写入目标寄存器 rd 的值 和 ALU结果/地址的输出
    always @(*) begin
        if ((branch_ctrl_from_idex || jump_ctrl_from_idex) && regWrite_ctrl_from_idex) begin
            //将pc+4写到rd
            alu_result_addr_to_exmem = link_address_calc;
        end else begin
            //ALU的直接输出
            alu_result_addr_to_exmem = alu_arith_logic_result_internal;
        end

    end

    // 假设 Controller_ID 在遇到 JAL 指令时，也会将 branch_ctrl_from_idex 置为 1'b1。
    // 同时，Controller_ID 会巧妙地设置 ALUOp_ctrl_from_idex (以及可能的 ALUSrc_ctrl_from_idex 来选择操作数)，
    // 使得 Execute_ALU_Logic 计算出的 alu_zero_flag 为 1'b1。这样，JAL 就可以复用 BEQ 的“条件满足则跳转”的逻辑，从而实现无条件跳转。

    // 对于 JALR: Controller_ID 必须将 ALUOp_ctrl_from_idex 设置为执行加法操作的码 (例如 ALUOP_ADD)，
    // 并且 ALUSrc_ctrl_from_idex 应为 1'b1 以选择 imm32_from_idex 作为ALU的第二个操作数。ALU的第一个操作数是 rdata1_from_idex (rs1的值)。
    // 这样，ALU的输出 (alu_arith_logic_result_internal) 就是 rs1 + imm。
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

    //发生BEQ,JAL,JALR时 branch_or_jump_to_if = 1
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

    // 6. 实例化 Controller_EX_Logic
    Controller_EX_Logic u_controller_ex (
        .isLoad_ctrl_from_wrapper(isLoad_ctrl_from_idex),
        .isStore_ctrl_from_wrapper(isStore_ctrl_from_idex),
        .regWrite_ctrl_from_wrapper(regWrite_ctrl_from_idex), // 来自ID的原始RegWrite
        .alu_result_addr_from_wrapper(alu_arith_logic_result_internal), // ALU计算的地址

        .MemRead_to_exmem(MemRead_ctrl_to_exmem),
        .MemWrite_to_exmem(MemWrite_ctrl_to_exmem),
        .IORead_to_exmem(IORead_ctrl_to_exmem),
        .IOWrite_to_exmem(IOWrite_ctrl_to_exmem),
        .RegWrite_to_exmem_final(RegWrite_ctrl_to_exmem), // 连接到包装器的RegWrite输出
        .MemToReg_to_exmem(MemToReg_ctrl_to_exmem)
    );

    // 7. 设置其他输出到EX/MEM流水线寄存器的信号
    always @(*) begin
        // 数据通路透传
        rdata2_for_store_to_exmem = rdata2_from_idex;
        rd_addr_to_exmem          = rd_addr_from_idex;

        // // 控制信号透传 (Ecall相关)
        // isEcall_ctrl_to_exmem     = isEcall_ctrl_from_idex;
        // ecall_type_to_exmem       = ecall_type_from_idex;
    end

endmodule
