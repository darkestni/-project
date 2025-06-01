module InstructionDecode_ID_Stage (
    input clk,
    input reset,

    // --- 来自 IF/ID 流水线寄存器的输入 ---
    input [31:0] instruction_ifid,
    input [31:0] pc_ifid,
    // input [31:0] pc_plus_4_ifid, // 如果JAL/JALR的返回地址从这里获取

    // --- (用于连接到内部RegisterFile实例) 来自WB阶段的写回信号 ---
    input        reg_write_enable_from_wb,
    input [4:0]  write_addr_from_wb,
    input [31:0] write_data_from_wb,

    // --- 输出到 ID/EX 流水线寄存器 (数据通路部分) ---
    output [31:0] rdata1_to_ex,
    output [31:0] rdata2_to_ex,
    output reg [31:0] imm32_to_ex,
    output [4:0]  rd_addr_to_ex,
    output [4:0]  rs1_addr_to_ex,
    output [4:0]  rs2_addr_to_ex,
    output [31:0] pc_to_ex,
    // output [31:0] pc_plus_4_to_ex, // 如果需要传递



    //for test
    output [31:0] x0,
    output [31:0] x1,
    output [31:0] x2,
    output [31:0] x3,
    output [31:0] x4,
    output [31:0] x5,
    output [31:0] x6,
    output [31:0] x9,
    output [31:0] x18,

    output wire [2:0] funct3_w, // funct3可能被Controller_ID使用
    output wire [6:0] funct7_w, // funct7可能被Controller_ID使用

    // --- 输出到 ID/EX 流水线寄存器 (来自Controller_ID的控制信号) ---
    output regWrite_ctrl_to_ex,
    output ALUSrc_ctrl_to_ex,
    output [3:0] ALUOp_ctrl_to_ex, // 与Controller_ID的ALUOp_o宽度一致
    output branch_ctrl_to_ex,
    output jump_ctrl_to_ex,
    output isLoad_ctrl_to_ex,
    output isStore_ctrl_to_ex,
    // output isEcall_ctrl_to_ex,
    // output [1:0] ecall_type_to_ex // 将ecall类型传递给EX，用于后续精确控制

    //control hazard
    output reg pc_write_enable_from_id,
    output reg [31:0] pc_jump_target,
    input [1:0] forwardA_id,
    input [1:0] forwardB_id,
    input [31:0] memwb_write_to_reg, // 来自WB阶段的写回数据
    input [31:0] exmem_alu_result // 来自EX/MEM阶段的ALU结果

);

    // 内部连线
    wire [6:0] opcode_w;
    wire [4:0] rs1_w;
    wire [4:0] rs2_w;
    wire [4:0] rd_w;
    // wire [2:0] funct3_w; // funct3可能被Controller_ID使用
    // wire [6:0] funct7_w; // funct7可能被Controller_ID使用
    wire [1:0] ecall_type_w;

    // --- 1. 指令字段提取 ---
    assign opcode_w = instruction_ifid[6:0];
    assign rs1_w    = instruction_ifid[19:15];
    assign rs2_w    = instruction_ifid[24:20];
    assign rd_w     = instruction_ifid[11:7];
    assign funct3_w = instruction_ifid[14:12];
    assign funct7_w = instruction_ifid[31:25];
    assign pc_to_ex = pc_ifid;
    // assign pc_plus_4_to_ex = pc_plus_4_ifid;

    assign rs1_addr_to_ex = rs1_w;
    assign rs2_addr_to_ex = rs2_w;
    assign rd_addr_to_ex  = rd_w;

    // Ecall类型提取 (与您原Decoder中ecall输出逻辑类似)
    localparam OPCODE_ECALL_ID_STAGE  = 7'b1110011;
    localparam ECALL_TYPE_NONE_ID     = 2'b00;
    localparam ECALL_TYPE_READ_ID     = 2'b01; // 对应您原Controller的 ecall == 2'b01
    localparam ECALL_TYPE_WRITE_ID    = 2'b10; // 对应您原Controller的 ecall == 2'b10

    // assign ecall_type_w = (opcode_w == OPCODE_ECALL_ID_STAGE && funct3_w == 3'b000) ?
    //                         ((instruction_ifid[31:20] == 12'd0) ? ECALL_TYPE_READ_ID :
    //                          (instruction_ifid[31:20] == 12'd1) ? ECALL_TYPE_WRITE_ID :
    //                                                               ECALL_TYPE_NONE_ID) :
    //                                                               ECALL_TYPE_NONE_ID;
    // assign ecall_type_to_ex = ecall_type_w; // 将此类型传递到EX级
    // --- 2. 例化寄存器堆 ---
    RegisterFile reg_file_inst (
        .clk(clk),
        .reset(reset),
        .read_addr1(rs1_w),
        .read_addr2(rs2_w),
        .reg_write_enable_wb(reg_write_enable_from_wb),
        .write_addr_wb(write_addr_from_wb),
        .write_data_wb(write_data_from_wb),
        .read_data1_id(rdata1_to_ex),
        //for test
        .x0(x0),
        .x1(x1),
        .x2(x2),
        .x3(x3),
        .x4(x4),
        .x5(x5),
        .x6(x6),
        .x9(x9),
        .x18(x18),
        .read_data2_id(rdata2_to_ex)
    );

    // --- 3. 立即数生成 ---
    always @(*) begin
        imm32_to_ex = 32'd0; // 默认值
        case (opcode_w)
            7'b0110011: imm32_to_ex = 32'd0; // R-type
            7'b0010011: imm32_to_ex = {{20{instruction_ifid[31]}}, instruction_ifid[31:20]}; // I-type Arith
            7'b0000011: imm32_to_ex = {{20{instruction_ifid[31]}}, instruction_ifid[31:20]}; // I-type Load
            7'b1100111: imm32_to_ex = {{20{instruction_ifid[31]}}, instruction_ifid[31:20]}; // I-type jalr
            7'b0100011: imm32_to_ex = {{20{instruction_ifid[31]}}, instruction_ifid[31:25], instruction_ifid[11:7]}; // S-type
            7'b1100011: imm32_to_ex = {{19{instruction_ifid[31]}}, instruction_ifid[31], instruction_ifid[7], instruction_ifid[30:25], instruction_ifid[11:8], 1'b0}; // SB-type
            7'b0110111: imm32_to_ex = {instruction_ifid[31:12], 12'b0}; // U-type (lui)
            7'b0010111: imm32_to_ex = {instruction_ifid[31:12], 12'b0} + pc_ifid; // U-type (auipc)
            7'b1101111: imm32_to_ex = {{11{instruction_ifid[31]}}, instruction_ifid[31], instruction_ifid[19:12], instruction_ifid[20], instruction_ifid[30:21], 1'b0}; // UJ-type
            7'b1110011: imm32_to_ex = 32'd0; // ECALL
            default:    imm32_to_ex = 32'd0;
        endcase
    end

    wire jump_from_control;
    wire branch_from_control;
    // --- 4. 例化 Controller_ID 模块 ---
    Controller_ID controller_id_inst (
        .opcode(opcode_w),
        .funct3(funct3_w),         // 传递funct3
        .funct7(funct7_w),         // 传递funct7
        // .ecall_type_in(ecall_type_w), // 使用提取出的ecall类型
        // 连接Controller_ID的输出到本模块的输出端口
        .regWrite_o(regWrite_ctrl_to_ex),
        .ALUSrc_o(ALUSrc_ctrl_to_ex),
        .ALUOp_o(ALUOp_ctrl_to_ex),
        .branch_o(branch_from_control),
        .jump_o(jump_from_control),
        .isLoad_o(isLoad_ctrl_to_ex),
        // .isEcall_o(isEcall_ctrl_to_ex),
        .isStore_o(isStore_ctrl_to_ex)
    );

    assign branch_ctrl_to_ex = branch_from_control;
    assign jump_ctrl_to_ex = jump_from_control;


    // assign branch_ctrl_to_ex = 0;
    // assign jump_ctrl_to_ex = 0;
    //handle control hazard
    wire [31:0] rdata1;
    wire [31:0] rdata2;
    assign rdata1 = (forwardA_id == 2'b01) ? exmem_alu_result : 
                    (forwardA_id == 2'b10) ? memwb_write_to_reg : rdata1_to_ex;
    assign rdata2 = (forwardB_id == 2'b01) ? exmem_alu_result :
                    (forwardB_id == 2'b10) ? memwb_write_to_reg : rdata2_to_ex;
    always @(*) begin
         pc_write_enable_from_id = (branch_from_control && (rdata1_to_ex == rdata2_to_ex)) || jump_from_control;
        pc_jump_target = (branch_from_control && (rdata1 == rdata2)) ? (pc_ifid + imm32_to_ex) :
                            (jump_from_control ? pc_ifid + imm32_to_ex : 32'd0);
    end
    // assign pc_write_enable_from_id = (branch_from_control && (rdata1_to_ex == rdata2_to_ex)) || jump_from_control;
    // assign pc_jump_target = (branch_from_control && (rdata1_to_ex == rdata2_to_ex)) ? (pc_ifid + imm32_to_ex) :
    //                         (jump_from_control ? pc_ifid + imm32_to_ex : 32'd0);


endmodule