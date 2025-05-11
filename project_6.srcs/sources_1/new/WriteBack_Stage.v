`timescale 1ns / 1ps

//==============================================================================
// Module: WriteBack_Stage
// Description:
//     ��ģ��ʵ��CPU�弶��ˮ�ߵ�д�� (Write Back - WB) �׶��߼���
//     �������MEM/WB��ˮ�߼Ĵ����������ݺͿ����źţ�
//     ���ݿ����ź�ѡ����ȷ������Դ��ALU������ڴ�/IO��ȡ�����ݣ���
//     �������ݺ���Ӧ�Ŀ����źŴ��ݸ��Ĵ����ѽ���д�ز�����
//==============================================================================
module WriteBack_Stage (
    // --- �����ź� (����MEM/WB��ˮ�߼Ĵ���) ---
    input [31:0] alu_result_from_memwb,          // ����ALU�ļ�����
    input [31:0] data_read_from_mem_from_memwb,  // ���ڴ��I/O��ȡ������
    input [4:0]  rd_addr_from_memwb,             // Ŀ��Ĵ����ĵ�ַ (rd)
    input        final_RegWrite_ctrl_from_memwb, // ���յļĴ���дʹ�ܿ����ź�
    input        MemToReg_ctrl_from_memwb,       // ѡ��д��������Դ�Ŀ����ź�
                                                 //   0: ��������ALU���
                                                 //   1: ���������ڴ�/IO��ȡ���

    // --- ����ź� (����RegisterFile��д�˿�) ---
    output reg [31:0] write_data_to_regfile,     // ����Ҫд��Ĵ����ѵ�����
    output reg [4:0]  write_addr_to_regfile,     // ����Ҫд��Ĵ����ѵ�Ŀ���ַ
    output reg        reg_write_enable_to_regfile // ���յļĴ���дʹ���ź�
);

    // д������ѡ���߼�
    // ���� MemToReg_ctrl_from_memwb �ź�ѡ������Դ
    always @(*) begin
        if (MemToReg_ctrl_from_memwb) begin
            // MemToReg = 1: ���������ڴ��I/O�Ķ�ȡ��� (����LWָ��)
            write_data_to_regfile = data_read_from_mem_from_memwb;
        end else begin
            // MemToReg = 0: ��������ALU�ļ����� (����R-type, I-type ALUָ��)
            write_data_to_regfile = alu_result_from_memwb;
        end
    end

    // Ŀ��Ĵ�����ַ��дʹ���ź�ֱ��͸��
    // (����ˮ������У���Щ�ź���MEM/WB�Ĵ������Ѿ�������ȷ����ֵ)
    always @(*) begin
        write_addr_to_regfile       = rd_addr_from_memwb;
        reg_write_enable_to_regfile = final_RegWrite_ctrl_from_memwb;
    end

    // ��ѡ����ӵ�����Ϣ���
    // always @(*) begin
    //     $display("WB_STAGE: Time=%0t, RegWrite=%b, MemToReg=%b, RdAddr=%h, ALURes=%h, MemData=%h, WriteData=%h",
    //              $time, final_RegWrite_ctrl_from_memwb, MemToReg_ctrl_from_memwb, rd_addr_from_memwb,
    //              alu_result_from_memwb, data_read_from_mem_from_memwb, write_data_to_regfile);
    // end

endmodule
