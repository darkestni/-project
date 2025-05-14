// File: Execute_ALU_Logic.v
module Execute_ALU_Logic (
    input  [31:0] operand_a_from_ex,    // ��һ�������� (�������� rs1 �� PC)
    input  [31:0] operand_b_from_ex,    // �ڶ��������� (�������� rs2 ��������������ALUSrcѡ��)
    input  [3:0]  alu_op_from_ex,       // ����Controller��4λALU������ (��ID/EX�Ĵ�������)
    output reg [31:0] alu_result_to_exmem, // ALU������
    output reg        zero_flag_to_ex      // ���־λ (�����Ϊ0ʱΪ1�����ڷ�֧�ж�)
);

    // ���� Controller_ID �� ALUOp ���� (�����ṩ��ƥ��)
    localparam ALUOP_ADD        = 4'b0000; // ��
    localparam ALUOP_SUB        = 4'b0001; // ��
    localparam ALUOP_SLL        = 4'b0010; // �߼�����
    localparam ALUOP_SLT        = 4'b0011; // �з���С����λ
    localparam ALUOP_SLTU       = 4'b0100; // �޷���С����λ
    localparam ALUOP_XOR        = 4'b0101; // ���
    localparam ALUOP_SRL        = 4'b0110; // �߼�����
    localparam ALUOP_SRA        = 4'b0111; // ��������
    localparam ALUOP_OR         = 4'b1000; // ��
    localparam ALUOP_AND        = 4'b1001; // ��
    // localparam ALUOP_LUI_PASS_B = 4'b1010; // ����ע�͵�
    localparam ALUOP_BRANCH_CMP = 4'b1011; // ��֧�Ƚ� (���·�˵��)
    localparam ALUOP_NOP        = 4'b1111; // �޲���

    // ��λ����ͨ��ʹ�� operand_b_from_ex �ĵ�5λ��Ϊ��λ��
    wire [4:0] shift_amount = operand_b_from_ex[4:0];

    always @(*) begin
        // Ĭ�����ֵ
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
                // ������� Controller_ID ������ ALUOP_BRANCH_CMP������ζ��ִ�м�����
                alu_result_to_exmem = operand_a_from_ex - operand_b_from_ex;
            end

            ALUOP_NOP: begin
                alu_result_to_exmem = 32'd0;
            end
            default: begin
                alu_result_to_exmem = 32'hDEADBEEF; // ���ڵ��ԵĴ���ָʾֵ
            end
        endcase

        if (alu_result_to_exmem == 32'd0) begin
            zero_flag_to_ex = 1'b1;
        end else begin
            zero_flag_to_ex = 1'b0;
        end
    end
endmodule
