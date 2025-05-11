//==============================================================================
// Module: EXMEM_PipelineRegister
// Author: [Your Name]
// Date: [Current Date]
// Description:
//     EX/MEM ��ˮ�߼Ĵ�����
//     ��ִ��(EX)�׶κͷô�(MEM)�׶�֮���������ݺͿ����źš�
//     ֧�ָ�λ����ˢ��дʹ�ܿ��ơ�
//==============================================================================
module EXMEM_PipelineRegister (
    input clk,
    input reset,
    input enable_write, // дʹ���ź� (ͨ���� !stall_mem_stage)
    input flush_exmem,  // ��ˢ�ź� (���磬��֧Ԥ�������쳣����ʱ)

    // --- �����ź� (����EX�׶ε����) ---
    // ����ͨ·ֵ
    input [31:0] alu_result_from_ex,            // ALU������
    input [31:0] branch_target_addr_from_ex,    // ��֧/��תĿ���ַ (EX������õ�)
    input [31:0] rdata2_for_store_from_ex,      // ����Storeָ���Դ������2������
    input [4:0]  rd_addr_from_ex,               // Ŀ��Ĵ�����ַ
    input [31:0] pc_from_ex,                    // ��ǰָ���PCֵ (����EX��)
    input [31:0] pc_plus_4_from_ex,             // ��ǰָ���PC+4ֵ (����EX��, ����JAL/JALRд��)

    // �����ź� (����EX�׶ε�Controller_EX_Logic��͸��)
    input        final_RegWrite_ctrl_from_ex, // ���յļĴ���дʹ���ź�
    input        MemRead_ctrl_from_ex,        // �ڴ��ʹ��
    input        MemWrite_ctrl_from_ex,       // �ڴ�дʹ��
    input        IORead_ctrl_from_ex,         // I/O��ʹ��
    input        IOWrite_ctrl_from_ex,        // I/Oдʹ��
    input        MemToReg_ctrl_from_ex,       // ѡ��д�ؼĴ�����������Դ (ALU��� vs �ڴ�/IO����)


    // --- ����ź� (����MEM�׶�) ---
    // ����ͨ·ֵ
    output reg [31:0] alu_result_to_mem,
    output reg [31:0] branch_target_addr_to_mem,
    output reg [31:0] rdata2_for_store_to_mem,
    output reg [4:0]  rd_addr_to_mem,
    output reg [31:0] pc_to_mem,
    output reg [31:0] pc_plus_4_to_mem,

    // �����ź�
    output reg        final_RegWrite_ctrl_to_mem,
    output reg        MemRead_ctrl_to_mem,
    output reg        MemWrite_ctrl_to_mem,
    output reg        IORead_ctrl_to_mem,
    output reg        IOWrite_ctrl_to_mem,
    output reg        MemToReg_ctrl_to_mem
);

    // �������ڳ�ˢ��λʱ��NOP���޲����������ź�ֵ
    localparam CTL_NOP_REGWRITE  = 1'b0;
    localparam CTL_NOP_MEMREAD   = 1'b0;
    localparam CTL_NOP_MEMWRITE  = 1'b0;
    localparam CTL_NOP_IOREAD    = 1'b0;
    localparam CTL_NOP_IOWRITE   = 1'b0;
    localparam CTL_NOP_MEMTOREG  = 1'b0; // ��RegWriteΪ0����ֵ����Ҫ

    // �������ڳ�ˢ��λʱ������ͨ·Ĭ��ֵ
    localparam DATA_NOP_DEFAULT  = 32'd0;
    localparam ADDR_NOP_DEFAULT  = 5'd0;


    always @(posedge clk or posedge reset) begin
        if (reset || flush_exmem) begin
            // ��λ���ˢʱ�������������ΪNOP��Ĭ��ֵ
            // ����ͨ·ֵ
            alu_result_to_mem         <= DATA_NOP_DEFAULT;
            branch_target_addr_to_mem <= DATA_NOP_DEFAULT; // Ŀ���ַ��Ϊ0
            rdata2_for_store_to_mem   <= DATA_NOP_DEFAULT;
            rd_addr_to_mem            <= ADDR_NOP_DEFAULT; // Ŀ��Ĵ�����ַ��Ϊx0
            pc_to_mem                 <= DATA_NOP_DEFAULT; // PCֵ��Ϊ0
            pc_plus_4_to_mem          <= DATA_NOP_DEFAULT; // PC+4ֵ��Ϊ0 (��4)

            // �����ź�
            final_RegWrite_ctrl_to_mem <= CTL_NOP_REGWRITE;
            MemRead_ctrl_to_mem        <= CTL_NOP_MEMREAD;
            MemWrite_ctrl_to_mem       <= CTL_NOP_MEMWRITE;
            IORead_ctrl_to_mem         <= CTL_NOP_IOREAD;
            IOWrite_ctrl_to_mem        <= CTL_NOP_IOWRITE;
            MemToReg_ctrl_to_mem       <= CTL_NOP_MEMTOREG;

        end else if (enable_write) begin
            // �������д�� (MEM�׶�û����ͣ)������������EX�׶ε��ź�
            // ����ͨ·ֵ
            alu_result_to_mem         <= alu_result_from_ex;
            branch_target_addr_to_mem <= branch_target_addr_from_ex;
            rdata2_for_store_to_mem   <= rdata2_for_store_from_ex;
            rd_addr_to_mem            <= rd_addr_from_ex;
            pc_to_mem                 <= pc_from_ex;
            pc_plus_4_to_mem          <= pc_plus_4_from_ex;

            // �����ź�
            final_RegWrite_ctrl_to_mem <= final_RegWrite_ctrl_from_ex;
            MemRead_ctrl_to_mem        <= MemRead_ctrl_from_ex;
            MemWrite_ctrl_to_mem       <= MemWrite_ctrl_from_ex;
            IORead_ctrl_to_mem         <= IORead_ctrl_from_ex;
            IOWrite_ctrl_to_mem        <= IOWrite_ctrl_from_ex;
            MemToReg_ctrl_to_mem       <= MemToReg_ctrl_from_ex;
        end
        // else if (!enable_write), �Ĵ������ֲ��� (stall)
    end

endmodule
