//==============================================================================
// Description:
//     ��ģ����Ϊ��ˮ��MEM�׶εĺ����߼���������ô��I/O������·�ɵ�ַ�����ݡ�
//     ֧�ֶ����ݴ洢���Լ�����LED�Ϳ��ص�I/O�豸�Ķ�д��

//==============================================================================
module MemOrIO_Pipeline (
    // from EX/MEM pipe reg
    input        MemRead_ctrl_from_exmem,     // �ڴ��ʹ���ź�
    input        MemWrite_ctrl_from_exmem,    // �ڴ�дʹ���ź�
    input        IORead_ctrl_from_exmem,      // I/O��ʹ���ź� 
    input        IOWrite_ctrl_from_exmem,     // I/Oдʹ���ź� 
    input [31:0] alu_result_addr_from_exmem,  // ALU��������Ϊ��ַ (����EX��)
    input [31:0] rdata2_for_store_from_exmem, // Ҫд������� (����EX, ԭrs2����)

    input [31:0] data_read_from_dmem,         
    input [15:0] data_read_from_io,         

    // to mem/wb pipe reg
    output reg [31:0] data_read_to_memwb,     // ���ڴ��I/O��ȡ�����ݣ�����WB

    // to mem/io
    output [31:0] addr_to_dmem_io,           // ����ַ���ݸ�DMEM��IO��DMEM��IOҲҪ����ʹ���ź��жϵ�ַ�Ƿ������Լ�
    output reg [31:0] data_to_write_to_dmem_io, // Ҫд�������

    //to io
    output led_write_enable_to_io,           // LEDдʹ���ź�
    output switch_read_enable_to_io        // ���ض�ʹ���ź�
);

    localparam IO_LED_ADDR          = 32'hFFFFFC60; // LED��ַ
    localparam IO_SWITCH_ADDR_LOW   = 32'hFFFFFC70; // ���ص�ַ (16λ)

    assign addr_to_dmem_io = alu_result_addr_from_exmem;


    // �ж����ݴ�IO����DMEM��ȡ
    always @(*) begin
        if (IORead_ctrl_from_exmem) begin //unsigned extend
            data_read_to_memwb = {16'd0, data_read_from_io}; 
        end else if (MemRead_ctrl_from_exmem) begin
            data_read_to_memwb = data_read_from_dmem;
        end else begin
            data_read_to_memwb = 32'h00000000;
        end
    end


    // ����Ҫд���ڴ��I/O�豸������
    always @(*) begin
        if (MemWrite_ctrl_from_exmem || IOWrite_ctrl_from_exmem) begin
            data_to_write_to_dmem_io = rdata2_for_store_from_exmem;
        end else begin
            data_to_write_to_dmem_io = 32'h00000000;
        end
    end

    assign led_write_enable_to_io = (IOWrite_ctrl_from_exmem && (alu_result_addr_from_exmem == IO_LED_ADDR));
    assign switch_read_enable_to_io = (IORead_ctrl_from_exmem && (alu_result_addr_from_exmem == IO_SWITCH_ADDR_LOW));

endmodule
