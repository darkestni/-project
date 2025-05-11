module IFID_PipelineRegister (
    input clk,
    input reset,
    input enable_write, // дʹ�ܣ�ͨ���� `!stall_id` (ID�׶ε���ͣ�źŷ���)
    input flush_ifid,   // ��ˢ�źţ���Ϊ1ʱ���Ĵ������ݱ���ΪNOP��λֵ

    // ��IF�׶���������
    input  [31:0] instruction_from_if,
    input  [31:0] pc_current_from_if,
    input  [31:0] pc_plus_4_from_if,

    // �����ID�׶�
    output reg [31:0] instruction_to_id,
    output reg [31:0] pc_current_to_id,
    output reg [31:0] pc_plus_4_to_id
);
    parameter NOP_INSTRUCTION = 32'h00000013; // ����һ��NOPָ�� (����: addi x0, x0, 0)
    parameter RESET_PC_VAL  = 32'h00000000; // ��λʱ��PCֵ

    always @(posedge clk or posedge reset) begin
        if (reset || flush_ifid) begin // �����λ����Ҫ��ˢ
            instruction_to_id <= NOP_INSTRUCTION;
            pc_current_to_id  <= RESET_PC_VAL; // ����һ���ض�����ЧPCֵ
            pc_plus_4_to_id   <= RESET_PC_VAL + 4;
        end else if (enable_write) begin // �������д��
            instruction_to_id <= instruction_from_if;
            pc_current_to_id  <= pc_current_from_if;
            pc_plus_4_to_id   <= pc_plus_4_from_if;
        end
        // ��� enable_write Ϊ0 (����ID�׶���ͣ), ��Ĵ�������ԭֵ
    end
endmodule