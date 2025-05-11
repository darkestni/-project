module Datapath (
    input clk,
    input reset,
    input debugMode,
    input step,
    input [7:0] dipSwitch,
    input button,
    input uart_rx,
    input [1:0] baud_select,
    output [7:0] led,
    output [6:0] seg,
    output [3:0] an,
    output [3:0] vga_r, vga_g, vga_b,
    output vga_hs, vga_vs
);

    // ������ˮ�߼Ĵ���
    reg [31:0] instruction_id;
    reg [31:0] pc_id;
    // ... ����ID/EX�Ĵ����ź�
    reg ALUSrc_idex_reg;
    reg [1:0] ALUOp_idex_reg;
    reg branch_idex_reg;
    reg jump_idex_reg;
    reg MemRead_idex_reg;
    reg MemWrite_idex_reg;
    reg MemOrIOtoReg_idex_reg;
    reg regWrite_idex_reg;
     reg [1:0] ecall_idex_reg;
    // ...

    // ʵ����ģ��
    InstructionDecode_ID_Stage id_stage (
        .clk(clk),
        .reset(reset),
        .instruction_ifid(instruction_if),
        .pc_ifid(pc_if),
        // ���ӵ�����ļĴ�����д���ź�
        .ALUSrc_idex(ALUSrc_idex_reg),
        .ALUOp_idex(ALUOp_idex_reg),
        .branch_idex(branch_idex_reg),
        .jump_idex(jump_idex_reg),
        .MemRead_idex(MemRead_idex_reg),
        .MemWrite_idex(MemWrite_idex_reg),
        .MemOrIOtoReg_idex(MemOrIOtoReg_idex_reg),
        .regWrite_idex(regWrite_idex_reg),
        .ecall_idex(ecall_idex_reg),
        // ...
    );

    RegisterFile regfile (
        .clk(clk),
        .reset(reset),
        // ... ���ӵ�ID�׶εĶ���ַ
        .reg_write_enable_wb(reg_write_enable_wb_top), // ���Զ��㣬��������WB
        .write_addr_wb(write_dest_addr_wb_top),    // ���Զ��㣬��������WB
        .write_data_wb(data_to_write_wb_top),      // ���Զ��㣬��������WB
        // ...
    );

    // ID/EX ��ˮ�߼Ĵ���
    always @(posedge clk) begin
        if (reset) begin
            instruction_id <= 32'd0;
            pc_id <= 32'd0;
            // ... ��ʼ�������Ĵ���
             ALUSrc_idex_reg <= 1'b0;
            ALUOp_idex_reg <= 2'b00;
            branch_idex_reg <= 1'b0;
            jump_idex_reg <= 1'b0;
            MemRead_idex_reg <= 1'b0;
            MemWrite_idex_reg <= 1'b0;
            MemOrIOtoReg_idex_reg <= 1'b0;
            regWrite_idex_reg <= 1'b0;
             ecall_idex_reg <= 2'b00;
            // ...
        end else begin
            instruction_id <= instruction_if;
            pc_id <= pc_if;
            // ... ����ID�׶ε����
             ALUSrc_idex_reg <= ALUSrc_idex;
            ALUOp_idex_reg <= ALUOp_idex;
            branch_idex_reg <= branch_idex;
            jump_idex_reg <= jump_idex;
            MemRead_idex_reg <= MemRead_idex;
            MemWrite_idex_reg <= MemWrite_idex;
            MemOrIOtoReg_idex_reg <= MemOrIOtoReg_idex;
            regWrite_idex_reg <= regWrite_idex;
            ecall_idex_reg <= ecall_idex;
            // ...
        end
    end

    // ... ������ˮ�߽׶ε�����

// --- ID�׶ε�ID/EX�Ĵ��������� ---
// ����InstructionDecode_ID_Stage�����
wire [31:0] rdata1_id_out;
wire [31:0] rdata2_id_out;
wire [31:0] imm32_id_out;
wire [4:0]  rd_addr_id_out;
wire [4:0]  rs1_addr_id_out;
wire [4:0]  rs2_addr_id_out;
wire [31:0] pc_id_out;
wire [1:0]  ecall_type_id_out;

wire        regWrite_ctrl_id_out;
wire        ALUSrc_ctrl_id_out;
wire [2:0]  ALUOp_ctrl_id_out;
wire        branch_ctrl_id_out;
wire        jump_ctrl_id_out;
wire        isLoad_ctrl_id_out;
wire        isStore_ctrl_id_out;
wire        isEcall_ctrl_id_out;

// --- ID/EX�Ĵ�����EX�׶ε����� ---
// IDEX_PipelineRegister�����
wire [31:0] rdata1_ex_in;
wire [31:0] rdata2_ex_in;
// ... (��������ID/EX�Ĵ���������ź�) ...
wire        isEcall_ctrl_ex_in;


InstructionDecode_ID_Stage id_stage_inst (
    .clk(clk),
    .reset(reset_signal), // ����ȫ�ָ�λ�ź�

    .instruction_ifid(instruction_from_ifid_reg), // ����IF/ID�Ĵ�����ָ��
    .pc_ifid(pc_from_ifid_reg),                   // ����IF/ID�Ĵ�����PC

    .reg_write_enable_from_wb(wb_reg_write_enable), // ����WB�׶ε�ʵ��дʹ��
    .write_addr_from_wb(wb_write_addr),           // ����WB�׶ε�ʵ��д��ַ
    .write_data_from_wb(wb_write_data),           // ����WB�׶ε�ʵ��д����

    .rdata1_to_ex(rdata1_id_out),
    .rdata2_to_ex(rdata2_id_out),
    .imm32_to_ex(imm32_id_out),
    .rd_addr_to_ex(rd_addr_id_out),
    .rs1_addr_to_ex(rs1_addr_id_out),
    .rs2_addr_to_ex(rs2_addr_id_out),
    .pc_to_ex(pc_id_out),
    .ecall_type_to_ex(ecall_type_id_out),

    .regWrite_ctrl_to_ex(regWrite_ctrl_id_out),
    .ALUSrc_ctrl_to_ex(ALUSrc_ctrl_id_out),
    .ALUOp_ctrl_to_ex(ALUOp_ctrl_id_out),
    .branch_ctrl_to_ex(branch_ctrl_id_out),
    .jump_ctrl_to_ex(jump_ctrl_id_out),
    .isLoad_ctrl_to_ex(isLoad_ctrl_id_out),
    .isStore_ctrl_to_ex(isStore_ctrl_id_out),
    .isEcall_ctrl_to_ex(isEcall_ctrl_id_out)
);

IDEX_PipelineRegister idex_reg_inst (
    .clk(clk),
    .reset(reset_signal),
    .enable_write(!stall_ex_stage_signal), // EX�׶�û����ͣʱ��д��
    .flush_idex(flush_idex_signal),       // ���Կ����߼��ĳ�ˢ�ź�

    .rdata1_from_id(rdata1_id_out),
    .rdata2_from_id(rdata2_id_out),
    .imm32_from_id(imm32_id_out),
    .rd_addr_from_id(rd_addr_id_out),
    .rs1_addr_from_id(rs1_addr_id_out),
    .rs2_addr_from_id(rs2_addr_id_out),
    .pc_from_id(pc_id_out),
    .ecall_type_from_id(ecall_type_id_out),

    .regWrite_ctrl_from_id(regWrite_ctrl_id_out),
    .ALUSrc_ctrl_from_id(ALUSrc_ctrl_id_out),
    .ALUOp_ctrl_from_id(ALUOp_ctrl_id_out),
    .branch_ctrl_from_id(branch_ctrl_id_out),
    .jump_ctrl_from_id(jump_ctrl_id_out),
    .isLoad_ctrl_from_id(isLoad_ctrl_id_out),
    .isStore_ctrl_from_id(isStore_ctrl_id_out),
    .isEcall_ctrl_from_id(isEcall_ctrl_id_out),

    .rdata1_to_ex(rdata1_ex_in),
    .rdata2_to_ex(rdata2_ex_in),
    // ... (�������������EX�׶ε��������һ������) ...
    .isEcall_ctrl_to_ex(isEcall_ctrl_ex_in)
);

// ... EX�׶�ģ�����������������ӵ� idex_reg_inst ����� ...
endmodule