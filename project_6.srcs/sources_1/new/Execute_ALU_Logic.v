module Execute_ALU_Logic ( // �����Է�ӳ����ΪALU�ͷ�֧�߼�����
    // --- ����ID/EX��ˮ�߼Ĵ��������� ---
    input [31:0] rdata1_in,         // rs1������
    input [31:0] rdata2_in,         // rs2������
    input [31:0] imm32_in,          // ������ (�Ѿ���������չ������չ)
    input        ALUSrc_in,         // ALU�ڶ���������Դ (����Controller_ID)
    input [2:0]  ALUOp_ctrl_in,     // ALU�������� (����Controller_ID, ����Ϊ3λ)
    input [2:0]  funct3_in,         // ָ���funct3�ֶ�
    input [6:0]  funct7_in,         // ָ���funct7�ֶ�
    input        is_ecall_in,       // �Ƿ���ecallָ�� (����Controller_ID)
    input [1:0]  ecall_type_in,     // ecall�ľ�������

    // --- ��� ---
    output reg [31:0] alu_result_out,            // ALU�ļ�����
    output reg        branch_condition_met_out // ��֧�����Ƿ�����
);

    wire [31:0] operand_b; // ALU�ĵڶ���������
    wire [31:0] subtraction_result; // ���ڷ�֧�Ƚ�

    // ѡ��ALU�ĵڶ���������
    assign operand_b = ALUSrc_in ? imm32_in : rdata2_in;

    // Ԥ�ȼ�������������ָ֧����õ�
    assign subtraction_result = rdata1_in - rdata2_in;

    always @(*) begin
        // --- Ĭ�����ֵ ---
        alu_result_out           = 32'd0; // Ĭ��ALU���
        branch_condition_met_out = 1'b0;  // Ĭ�Ϸ�֧����������

        if (is_ecall_in) begin
            // Ecall ָ����ALU�׶εĴ��� (������ԭ�߼�)
            // ע�⣺Controller_ID�Ѿ�����ecall_type������ALUOp_ctrl_in
            // ���磬���ڶ�ȡ��ecall, Controller_ID���ܽ�ALUOp_ctrl_in��Ϊ������A��������
            // ������߼���Ҫ��Controller_ID�ж�ecall��ALUOp������Э��
            if (ecall_type_in == 2'b01) begin // ���� 2'b01 �Ƕ�ȡ��ecall����Ҫ��rdata1��Ϊ���
                                             // ����ԭ�߼��� ALUResult = rdata1
                alu_result_out = rdata1_in; // �������ҪALUOp_ctrl_inָʾ������rdata1��
                                            // ���ߣ����ecall���ض�����Դ��Ӧͨ��ALUOp_ctrl_inָʾ
            end else begin  // ����ecall���ͣ�����дLED��ALU�������0���ض�ֵ
                alu_result_out = 32'd0;
            end
        end else begin
            // ���� Controller_ID ���ɵ� ALUOp_ctrl_in ִ�в���
            case (ALUOp_ctrl_in)
                // ӳ����ԭController�� ALUOp=2'b00: �ӷ� (����addi, lw, sw��ַ����, jalrĿ���ַ����)
                3'b000: begin // ADD
                    alu_result_out = rdata1_in + operand_b;
                end

                // ӳ����ԭController�� ALUOp=2'b01: ��֧�Ƚ�
                3'b001: begin // BRANCH condition check (SUB for comparison)
                    alu_result_out = subtraction_result; // ALU��������ǲ�ֵ�����ڵ��Ի�ĳЩ����Ŀ��
                                                         // ��Ҫ����� branch_condition_met_out
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

                // ӳ����ԭController�� ALUOp=2'b10: R�Ͳ���
                3'b010: begin // R-TYPE operations
                    // operand_b ����R��ָ������rdata2_in (��ΪALUSrc_in����0)
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
                        default: alu_result_out = 32'd0; // δ�����funct3
                    endcase
                end

                // ΪAUIPC��LUI��ӵĲ��� (����Controller_ID��ALUOp����)
                // ����ID�׶ε�imm32_in�Ѿ�ΪAUIPC������(PC + U-imm)
                // ����ID�׶ε�imm32_in�Ѿ�ΪLUI׼����(U-imm)
                3'b101: begin // AUIPC (pass pre-calculated immediate)
                    alu_result_out = imm32_in; // ALUSrc_in Ӧ��Ϊ1
                end
                3'b110: begin // LUI (pass immediate)
                    alu_result_out = imm32_in; // ALUSrc_in Ӧ��Ϊ1
                end

                // JAL��Ŀ���ַ (PC + imm) Ҳ����ʹ����ADD��ͬ��ALUOp (3'b000)
                // ���Controller_IDΪJAL����ALUOp_ctrl_in = 3'b000, ��ALUSrc_in = 1 (imm��ΪB������)
                // ����rdata1_in���ӵ�PC������Լ���PC+imm��

                default: alu_result_out = 32'd0; // δ�����ALUOp_ctrl_in
            endcase
        end
    end
endmodule