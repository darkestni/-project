module Execute_Stage_Wrapper (
    // --- 来自ID/EX流水线寄存器的输入 ---
    input clk, // 虽然ALU本身是组合逻辑，但EX级整体受时钟控制
    input reset,

    // 数据通路值
    input [31:0] pc_from_idex,
    input [31:0] rdata1_from_idex,
    input [31:0] rdata2_from_idex,
    input [31:0] imm32_from_idex,
    input [4:0]  rd_addr_from_idex,
    input [4:0]  rs1_addr_from_idex, // 用于转发
    input [4:0]  rs2_addr_from_idex, // 用于转发

    // 控制信号 (来自Controller_ID)
    input        regWrite_ctrl_from_idex,
    input        ALUSrc_ctrl_from_idex,
    input [2:0]  ALUOp_ctrl_from_idex,
    input        branch_ctrl_from_idex, // Controller_ID 输出的 branch_o
    input        jump_ctrl_from_idex,   // Controller_ID 输出的 jump_o
    input        isLoad_ctrl_from_idex,
    input        isStore_ctrl_from_idex,
    input        isEcall_ctrl_from_idex,
    input [1:0]  ecall_type_from_idex,
    input [2:0]  funct3_from_idex,      // 指令的funct3
    input [6:0]  funct7_from_idex,      // 指令的funct7


    // --- 输出到EX/MEM流水线寄存器 ---
    // 数据通路值
    output reg [31:0] alu_result_to_exmem,
    output reg        branch_condition_met_to_exmem,
    output reg [31:0] branch_target_addr_to_exmem, // 计算出的分支/JAL目标地址
    output reg [31:0] rdata2_for_store_to_exmem, // 用于sw指令的数据
    output reg [4:0]  rd_addr_to_exmem,          // 目标寄存器地址

    // 控制信号 (部分来自Controller_EX_Logic, 部分透传)
    output reg        final_RegWrite_to_exmem, // 最终的写使能 (经Controller_EX确认)
    output reg        MemRead_to_exmem,
    output reg        MemWrite_to_exmem,
    output reg        IORead_to_exmem,
    output reg        IOWrite_to_exmem,
    output reg        MemToReg_to_exmem // 或更通用的DataSourceForWB
);

    wire [31:0] alu_result_internal;
    wire        branch_condition_met_internal;
    wire [21:0] alu_result_high_internal; // ALU结果高位给Controller_EX

    // 1. 例化ALU核心逻辑
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

    // 2. 计算分支/JAL目标地址 (PC + imm)
    // 注意：JALR的目标地址 (rs1 + imm) 是由alu_core_inst在ALUOp_ctrl_in为3'b000时计算的
    wire [31:0] calculated_branch_jal_target;
    assign calculated_branch_jal_target = pc_from_idex + imm32_from_idex;

    // 提取ALU结果的高位，用于Controller_EX_Logic
    assign alu_result_high_internal = alu_result_internal[31:10]; // 假设取高22位

    // 3. 例化Controller_EX_Logic (用于处理依赖ALU结果的控制信号)
    Controller_EX_Logic controller_ex_inst (
        .isLoad_from_idex(isLoad_ctrl_from_idex),
        .isStore_from_idex(isStore_ctrl_from_idex),
        .isEcall_from_idex(isEcall_ctrl_from_idex),
        .ecall_type_from_idex(ecall_type_from_idex),
        .regWrite_from_idex(regWrite_ctrl_from_idex), // ID阶段的原始regWrite
        .alu_result_high_from_ex(alu_result_high_internal),
        .MemRead_to_mem(MemRead_to_exmem),
        .MemWrite_to_mem(MemWrite_to_exmem),
        .IORead_to_mem(IORead_to_exmem),
        .IOWrite_to_mem(IOWrite_to_exmem),
        .final_RegWrite_to_wb(final_RegWrite_to_exmem), // 传递到WB的最终RegWrite
        .MemToReg_to_wb(MemToReg_to_exmem)
    );

    // 4. 组合逻辑或时序逻辑将内部信号赋给输出 (通常是组合逻辑，由EX/MEM寄存器锁存)
    always @(*) begin
        alu_result_to_exmem           = alu_result_internal;
        branch_condition_met_to_exmem = branch_condition_met_internal;
        // JALR的目标地址是alu_result_internal (当ALUOp为ADD且操作数为rs1和imm时)
        // JAL和BRANCH的目标地址是calculated_branch_jal_target
        // 需要一个选择器，或者让PC更新逻辑处理这个选择。
        // 这里我们简单地将PC+imm传递出去，PC更新逻辑会根据是否是JALR来选择。
        branch_target_addr_to_exmem   = calculated_branch_jal_target;
        rdata2_for_store_to_exmem     = rdata2_from_idex; // 透传rs2的数据，用于store
        rd_addr_to_exmem              = rd_addr_from_idex;  // 透传目标寄存器地址

        // MemRead_to_exmem, MemWrite_to_exmem等信号已经由controller_ex_inst的输出直接连接。
        // final_RegWrite_to_exmem 和 MemToReg_to_exmem 也由controller_ex_inst的输出直接连接。
    end
endmodule