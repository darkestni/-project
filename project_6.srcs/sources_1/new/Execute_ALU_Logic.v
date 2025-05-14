// File: Execute_ALU_Logic.v
module Execute_ALU_Logic (
    input  [31:0] operand_a_from_ex,    // 第一个操作数 (例如来自 rs1 或 PC)
    input  [31:0] operand_b_from_ex,    // 第二个操作数 (例如来自 rs2 或立即数，已由ALUSrc选择)
    input  [3:0]  alu_op_from_ex,       // 来自Controller的4位ALU操作码 (经ID/EX寄存器传递)
    output reg [31:0] alu_result_to_exmem, // ALU计算结果
    output reg        zero_flag_to_ex      // 零标志位 (当结果为0时为1，用于分支判断)
);

    // 来自 Controller_ID 的 ALUOp 定义 (与你提供的匹配)
    localparam ALUOP_ADD        = 4'b0000; // 加
    localparam ALUOP_SUB        = 4'b0001; // 减
    localparam ALUOP_SLL        = 4'b0010; // 逻辑左移
    localparam ALUOP_SLT        = 4'b0011; // 有符号小于置位
    localparam ALUOP_SLTU       = 4'b0100; // 无符号小于置位
    localparam ALUOP_XOR        = 4'b0101; // 异或
    localparam ALUOP_SRL        = 4'b0110; // 逻辑右移
    localparam ALUOP_SRA        = 4'b0111; // 算术右移
    localparam ALUOP_OR         = 4'b1000; // 或
    localparam ALUOP_AND        = 4'b1001; // 与
    // localparam ALUOP_LUI_PASS_B = 4'b1010; // 你已注释掉
    localparam ALUOP_BRANCH_CMP = 4'b1011; // 分支比较 (见下方说明)
    localparam ALUOP_NOP        = 4'b1111; // 无操作

    // 移位操作通常使用 operand_b_from_ex 的低5位作为移位量
    wire [4:0] shift_amount = operand_b_from_ex[4:0];

    always @(*) begin
        // 默认输出值
        alu_result_to_exmem = 32'd0;
        zero_flag_to_ex     = 1'b0;

        case (alu_op_from_ex)
            ALUOP_ADD:  alu_result_to_exmem = operand_a_from_ex + operand_b_from_ex;
            ALUOP_SUB:  alu_result_to_exmem = operand_a_from_ex - operand_b_from_ex;
            ALUOP_SLL:  alu_result_to_exmem = operand_a_from_ex << shift_amount;
            ALUOP_SLT:  alu_result_to_exmem = ($signed(operand_a_from_ex) < $signed(operand_b_from_ex)) ? 32'd1 : 32'd0;
            ALUOP_SLTU: alu_result_to_exmem = (operand_a_from_ex < operand_b_from_ex) ? 32'd1 : 32'd0;
            ALUOP_XOR:  alu_result_to_exmem = operand_a_from_ex ^ operand_b_from_ex;
            ALUOP_SRL:  alu_result_to_exmem = operand_a_from_ex >> shift_amount;
            ALUOP_SRA:  alu_result_to_exmem = $signed(operand_a_from_ex) >>> shift_amount;
            ALUOP_OR:   alu_result_to_exmem = operand_a_from_ex | operand_b_from_ex;
            ALUOP_AND:  alu_result_to_exmem = operand_a_from_ex & operand_b_from_ex;

            ALUOP_BRANCH_CMP: begin
                // 假设如果 Controller_ID 发出了 ALUOP_BRANCH_CMP，它意味着执行减法。
                alu_result_to_exmem = operand_a_from_ex - operand_b_from_ex;
            end

            ALUOP_NOP: begin
                alu_result_to_exmem = 32'd0;
            end
            default: begin
                alu_result_to_exmem = 32'hDEADBEEF; // 用于调试的错误指示值
            end
        endcase

        if (alu_result_to_exmem == 32'd0) begin
            zero_flag_to_ex = 1'b1;
        end else begin
            zero_flag_to_ex = 1'b0;
        end
    end
endmodule
