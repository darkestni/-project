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


    //处理Data Hazard
    input [1:0] forwardA_from_idex, // 来自转发单元的信号 (Forwarding Unit)
    input [1:0] forwardB_from_idex, // 来自转发单元的信号 (Forwarding Unit)
    input [31:0] memwb_write_to_reg, // 来自WB阶段的写回数据
    input [31:0] exmem_alu_result, // 来自EX/MEM阶段的ALU结果
    
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
    reg  [31:0] alu_operand_a;
    reg  [31:0] alu_operand_b;
    wire [31:0] alu_arith_logic_result_internal; // ALU自身的算术逻辑运算结果
    wire        alu_zero_flag;
    wire [31:0] rs2_value; //从rdata2_from_idex和forwardB给回的数据中选择

    assign rs2_value = forwardB_from_idex == 2'b10 ? exmem_alu_result :
                      forwardB_from_idex == 2'b01 ? memwb_write_to_reg :
                      rdata2_from_idex; // 默认值 (2'b00)

    // 1. ALU操作数选择 处理Data Hazard
    always @(*) begin
        // Operand A selection
        case (forwardA_from_idex)
            2'b10: alu_operand_a = exmem_alu_result; // 来自EX/MEM
            2'b01: alu_operand_a = memwb_write_to_reg; // 来自MEM/WB
            default: alu_operand_a = rdata1_from_idex; // 默认值 (2'b00)
        endcase

        // Operand B selection
        if (ALUSrc_ctrl_from_idex) begin // If Operand B is an immediate
            alu_operand_b = imm32_from_idex;
        end else begin // If Operand B is from a register
            alu_operand_b = rs2_value;
        end
    end


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
        if ((jump_ctrl_from_idex) && regWrite_ctrl_from_idex) begin
            //将pc+4写到rd
            alu_result_addr_to_exmem = link_address_calc;
        end else begin
            //ALU的直接输出
            alu_result_addr_to_exmem = alu_arith_logic_result_internal;
        end

    end


    wire [31:0] branch_jal_target_addr_calc;
    wire [31:0] jalr_target_addr_calc;




    //ALUSrc = 1: JALR     0: JAL
    assign branch_jal_target_addr_calc = pc_from_idex + imm32_from_idex;
    assign jalr_target_addr_calc = alu_arith_logic_result_internal & ~32'h1;

    //发生BEQ,JAL,JALR时 branch_or_jump_to_if = 1
    always @(*) begin
        if (branch_ctrl_from_idex 
        && alu_zero_flag
        // && condition_met_for_branch
        ) begin
            branch_or_jump_to_if = 1'b1;
            target_pc_ex            = branch_jal_target_addr_calc;
        end else if (jump_ctrl_from_idex && ALUSrc_ctrl_from_idex) begin
            //ALUSrc = 1: JALR
            branch_or_jump_to_if = 1'b1;
            target_pc_ex            = jalr_target_addr_calc;
        end else if (jump_ctrl_from_idex) begin
            //JAL
            branch_or_jump_to_if = 1'b1;
            target_pc_ex            = pc_from_idex + imm32_from_idex;
        end 
        else begin
            branch_or_jump_to_if = 1'b0;
            target_pc_ex            = pc_from_idex + 32'd4;
        end
    end

    // 6. 实例化 Controller_EX_Logic
    Controller_EX_Logic u_controller_ex (
        .isLoad_from_idex(isLoad_ctrl_from_idex),
        .isStore_from_idex(isStore_ctrl_from_idex),
        // .isEcall_from_idex(isEcall_ctrl_from_idex),
        // .ecall_type_from_idex(ecall_type_from_idex),
        .regWrite_from_idex(regWrite_ctrl_from_idex), // generated by Controller_ID
        .alu_result_high_from_ex(alu_result_addr_to_exmem[21:0]), // ALU计算出的地址高位
        .MemRead_to_mem(MemRead_ctrl_to_exmem),
        .MemWrite_to_mem(MemWrite_ctrl_to_exmem),
        .IORead_to_mem(IORead_ctrl_to_exmem),
        .IOWrite_to_mem(IOWrite_ctrl_to_exmem),
        .RegWrite_to_wb(RegWrite_ctrl_to_exmem),
        .MemToReg_to_wb(MemToReg_ctrl_to_exmem)
    );


    // 7. 设置其他输出到EX/MEM流水线寄存器的信号
    always @(*) begin
        // 数据通路透传
        rdata2_for_store_to_exmem = rs2_value;
        rd_addr_to_exmem          = rd_addr_from_idex;

        // // 控制信号透传 (Ecall相关)
        // isEcall_ctrl_to_exmem     = isEcall_ctrl_from_idex;
        // ecall_type_to_exmem       = ecall_type_from_idex;
    end



endmodule
