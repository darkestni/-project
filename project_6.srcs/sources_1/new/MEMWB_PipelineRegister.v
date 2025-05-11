`timescale 1ns / 1ps

module MEMWB_PipelineRegister (
    input clk,
    input reset,
    // input enable_write, // ͨ��WB�׶β���ͣ������������ˮ����ͣ
    // input flush_memwb,  // WB�׶�ͨ������ˢ�£���Ϊָ����ִ�е����

    // --- �����ź� (����MEM�׶ε����) ---
    // ����ͨ·
    input [31:0] alu_result_from_mem,
    input [31:0] data_read_from_mem, // ����MemOrIO��data_read_to_memwb
    input [4:0]  rd_addr_from_mem,

    // �����ź�
    input        final_RegWrite_ctrl_from_mem,
    input        MemToReg_ctrl_from_mem,
    // input [31:0] pc_plus_4_from_mem, // ���JAL/JALR�ķ��ص�ַ�����ﴦ��������
    // input        is_ecall_from_mem,    // ���ecall��Ҫ��WB�׶����⴦��ͨ������Ҫ��


    // --- ����ź� (����WB�׶�) ---
    // ����ͨ·
    output reg [31:0] alu_result_to_wb,
    output reg [31:0] data_read_from_mem_to_wb,
    output reg [4:0]  rd_addr_to_wb,

    // �����ź�
    output reg        final_RegWrite_ctrl_to_wb,
    output reg        MemToReg_ctrl_to_wb
    // output reg [31:0] pc_plus_4_to_wb,
    // output reg        is_ecall_to_wb
);

    // NOP/Flushʱ��Ĭ�Ͽ����ź�ֵ (ͨ��WB����flush����resetʱ��ҪĬ��ֵ)
    localparam CTL_NOP_REGWRITE  = 1'b0;
    localparam CTL_NOP_MEMTOREG  = 1'b0; // ����Ҫ����ΪRegWriteΪ0

    always @(posedge clk or posedge reset) begin
        if (reset) begin //  || flush_memwb
            // ����ͨ·ֵ��λ (������Ϊ0��ȷ��ֵ)
            alu_result_to_wb         <= 32'd0;
            data_read_from_mem_to_wb <= 32'd0;
            rd_addr_to_wb            <= 5'd0;
            // pc_plus_4_to_wb          <= 32'd0;

            // �����źŸ�λΪNOP״̬
            final_RegWrite_ctrl_to_wb  <= CTL_NOP_REGWRITE;
            MemToReg_ctrl_to_wb      <= CTL_NOP_MEMTOREG;
            // is_ecall_to_wb           <= 1'b0;

        // end else if (enable_write) begin // �����дʹ��
        end else begin // ����MEM/WB�Ĵ�������д�루����������ˮ����ͣ��
            // ��������MEM�׶ε����ݺͿ����ź�
            alu_result_to_wb         <= alu_result_from_mem;
            data_read_from_mem_to_wb <= data_read_from_mem;
            rd_addr_to_wb            <= rd_addr_from_mem;
            // pc_plus_4_to_wb          <= pc_plus_4_from_mem;

            final_RegWrite_ctrl_to_wb  <= final_RegWrite_ctrl_from_mem;
            MemToReg_ctrl_to_wb      <= MemToReg_ctrl_from_mem;
            // is_ecall_to_wb           <= is_ecall_from_mem;
        // end
        // ��� enable_write Ϊ0 (��ˮ����ͣ), �Ĵ�������ԭֵ
        end
    end
endmodule
