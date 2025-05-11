module Execute_ALU_Logic ( // 更名以反映其作为ALU和分支逻辑核心
    // --- 来自ID/EX流水线寄存器的输入 ---
    input [31:0] rdata1_in,         // rs1的数据
    input [31:0] rdata2_in,         // rs2的数据
    input [31:0] imm32_in,          // 立即数 (已经过符号扩展或零扩展)
    input        ALUSrc_in,         // ALU第二操作数来源 (来自Controller_ID)
    input [2:0]  ALUOp_ctrl_in,     // ALU操作控制 (来自Controller_ID, 假设为3位)
    input [2:0]  funct3_in,         // 指令的funct3字段
    input [6:0]  funct7_in,         // 指令的funct7字段
    input        is_ecall_in,       // 是否是ecall指令 (来自Controller_ID)
    input [1:0]  ecall_type_in,     // ecall的具体类型

    // --- 输出 ---
    output reg [31:0] alu_result_out,            // ALU的计算结果
    output reg        branch_condition_met_out // 分支条件是否满足
);

    wire [31:0] operand_b; // ALU的第二个操作数
    wire [31:0] subtraction_result; // 用于分支比较

    // 选择ALU的第二个操作数
    assign operand_b = ALUSrc_in ? imm32_in : rdata2_in;

    // 预先计算减法结果，分支指令会用到
    assign subtraction_result = rdata1_in - rdata2_in;

    always @(*) begin
        // --- 默认输出值 ---
        alu_result_out           = 32'd0; // 默认ALU结果
        branch_condition_met_out = 1'b0;  // 默认分支条件不满足

        if (is_ecall_in) begin
            // Ecall 指令在ALU阶段的处理 (根据您原逻辑)
            // 注意：Controller_ID已经根据ecall_type设置了ALUOp_ctrl_in
            // 例如，对于读取型ecall, Controller_ID可能将ALUOp_ctrl_in设为“传递A操作数”
            // 这里的逻辑需要与Controller_ID中对ecall的ALUOp设置相协调
            if (ecall_type_in == 2'b01) begin // 假设 2'b01 是读取型ecall，需要将rdata1作为结果
                                             // 您的原逻辑是 ALUResult = rdata1
                alu_result_out = rdata1_in; // 这可能需要ALUOp_ctrl_in指示“传递rdata1”
                                            // 或者，如果ecall有特定数据源，应通过ALUOp_ctrl_in指示
            end else begin  // 其他ecall类型，例如写LED，ALU可能输出0或特定值
                alu_result_out = 32'd0;
            end
        end else begin
            // 根据 Controller_ID 生成的 ALUOp_ctrl_in 执行操作
            case (ALUOp_ctrl_in)
                // 映射您原Controller的 ALUOp=2'b00: 加法 (用于addi, lw, sw地址计算, jalr目标地址计算)
                3'b000: begin // ADD
                    alu_result_out = rdata1_in + operand_b;
                end

                // 映射您原Controller的 ALUOp=2'b01: 分支比较
                3'b001: begin // BRANCH condition check (SUB for comparison)
                    alu_result_out = subtraction_result; // ALU结果可以是差值，用于调试或某些特殊目的
                                                         // 主要输出是 branch_condition_met_out
                    case (funct3_in)
                        3'b000: branch_condition_met_out = (subtraction_result == 32'd0);       // beq (rs1 == rs2)
                        3'b001: branch_condition_met_out = (subtraction_result != 32'd0);       // bne (rs1 != rs2)
                        3'b100: branch_condition_met_out = ($signed(rdata1_in) < $signed(rdata2_in));  // blt
                        3'b101: branch_condition_met_out = ($signed(rdata1_in) >= $signed(rdata2_in)); // bge
                        3'b110: branch_condition_met_out = (rdata1_in < rdata2_in);             // bltu
                        3'b111: branch_condition_met_out = (rdata1_in >= rdata2_in);            // bgeu
                        default: branch_condition_met_out = 1'b0;
                    endcase
                end

                // 映射您原Controller的 ALUOp=2'b10: R型操作
                3'b010: begin // R-TYPE operations
                    // operand_b 对于R型指令总是rdata2_in (因为ALUSrc_in会是0)
                    case (funct3_in)
                        3'b000: begin // ADD or SUB
                            if (funct7_in == 7'b0100000) // SUB
                                alu_result_out = rdata1_in - operand_b;
                            else // ADD (funct7 == 7'b0000000 or other non-SUB R-type add)
                                alu_result_out = rdata1_in + operand_b;
                        end
                        3'b001: alu_result_out = rdata1_in << operand_b[4:0];        // SLL
                        3'b010: alu_result_out = ($signed(rdata1_in) < $signed(operand_b)) ? 32'd1 : 32'd0; // SLT
                        3'b011: alu_result_out = (rdata1_in < operand_b) ? 32'd1 : 32'd0; // SLTU
                        3'b100: alu_result_out = rdata1_in ^ operand_b;              // XOR
                        3'b101: begin // SRL or SRA
                            if (funct7_in == 7'b0100000) // SRA
                                alu_result_out = $signed(rdata1_in) >>> operand_b[4:0];
                            else // SRL (funct7 == 7'b0000000)
                                alu_result_out = rdata1_in >> operand_b[4:0];
                        end
                        3'b110: alu_result_out = rdata1_in | operand_b;              // OR
                        3'b111: alu_result_out = rdata1_in & operand_b;              // AND
                        default: alu_result_out = 32'd0; // 未定义的funct3
                    endcase
                end

                // 为AUIPC和LUI添加的操作 (根据Controller_ID的ALUOp设置)
                // 假设ID阶段的imm32_in已经为AUIPC计算了(PC + U-imm)
                // 假设ID阶段的imm32_in已经为LUI准备了(U-imm)
                3'b101: begin // AUIPC (pass pre-calculated immediate)
                    alu_result_out = imm32_in; // ALUSrc_in 应该为1
                end
                3'b110: begin // LUI (pass immediate)
                    alu_result_out = imm32_in; // ALUSrc_in 应该为1
                end

                // JAL的目标地址 (PC + imm) 也可能使用与ADD相同的ALUOp (3'b000)
                // 如果Controller_ID为JAL设置ALUOp_ctrl_in = 3'b000, 且ALUSrc_in = 1 (imm作为B操作数)
                // 并且rdata1_in连接到PC，则可以计算PC+imm。

                default: alu_result_out = 32'd0; // 未定义的ALUOp_ctrl_in
            endcase
        end
    end
endmodule