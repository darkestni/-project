module IDEX_PipelineRegister (
    input clk,
    input reset,
    input enable_write, // 写使能信号 (通常是 !stall_ex_stage)
    input flush_idex,   // 冲刷信号 (例如，分支预测错误时)

    // --- 来自ID阶段的输入 ---
    // 数据通路值
    input [31:0] rdata1_from_id,
    input [31:0] rdata2_from_id,
    input [31:0] imm32_from_id,
    input [4:0]  rd_addr_from_id,
    input [4:0]  rs1_addr_from_id,
    input [4:0]  rs2_addr_from_id,
    input [31:0] pc_from_id,
    input [1:0]  ecall_type_from_id,

    // 控制信号
    input        regWrite_ctrl_from_id,
    input        ALUSrc_ctrl_from_id,
    input [3:0]  ALUOp_ctrl_from_id,
    input        branch_ctrl_from_id,
    input        jump_ctrl_from_id,
    input        isLoad_ctrl_from_id,
    input        isStore_ctrl_from_id,
    input        isEcall_ctrl_from_id,

    // --- 输出到EX阶段 ---
    // 数据通路值
    output reg [31:0] rdata1_to_ex,
    output reg [31:0] rdata2_to_ex,
    output reg [31:0] imm32_to_ex,
    output reg [4:0]  rd_addr_to_ex,
    output reg [4:0]  rs1_addr_to_ex,
    output reg [4:0]  rs2_addr_to_ex,
    output reg [31:0] pc_to_ex,
    output reg [1:0]  ecall_type_to_ex,

    // 控制信号
    output reg        regWrite_ctrl_to_ex,
    output reg        ALUSrc_ctrl_to_ex,
    output reg [4:0]  ALUOp_ctrl_to_ex,
    output reg        branch_ctrl_to_ex,
    output reg        jump_ctrl_to_ex,
    output reg        isLoad_ctrl_to_ex,
    output reg        isStore_ctrl_to_ex,
    output reg        isEcall_ctrl_to_ex
);

    // 定义NOP（空操作）时的控制信号值
    localparam CTL_NOP_REGWRITE  = 1'b0;
    localparam CTL_NOP_ALUSRC    = 1'b0; // 对于NOP，ALUSrc的值不重要
    localparam CTL_NOP_ALUOP     = 4'b0000; // 例如，设为ADD，但结果不会被使用
    localparam CTL_NOP_BRANCH    = 1'b0;
    localparam CTL_NOP_JUMP      = 1'b0;
    localparam CTL_NOP_ISLOAD    = 1'b0;
    localparam CTL_NOP_ISSTORE   = 1'b0;
    localparam CTL_NOP_ISECALL   = 1'b0;
    localparam CTL_NOP_ECALLTYPE = 2'b00;


    always @(posedge clk or posedge reset) begin
        if (reset || flush_idex) begin // 复位或冲刷时，载入NOP的默认值
            // 数据通路值清零或设为安全值
            rdata1_to_ex         <= 32'd0;
            rdata2_to_ex         <= 32'd0;
            imm32_to_ex          <= 32'd0;
            rd_addr_to_ex        <= 5'd0;
            rs1_addr_to_ex       <= 5'd0;
            rs2_addr_to_ex       <= 5'd0;
            pc_to_ex             <= 32'd0; // 或者一个特定的“无效PC”标记
            ecall_type_to_ex     <= CTL_NOP_ECALLTYPE;

            // 控制信号设为NOP状态
            regWrite_ctrl_to_ex  <= CTL_NOP_REGWRITE;
            ALUSrc_ctrl_to_ex    <= CTL_NOP_ALUSRC;
            ALUOp_ctrl_to_ex     <= CTL_NOP_ALUOP;
            branch_ctrl_to_ex    <= CTL_NOP_BRANCH;
            jump_ctrl_to_ex      <= CTL_NOP_JUMP;
            isLoad_ctrl_to_ex    <= CTL_NOP_ISLOAD;
            isStore_ctrl_to_ex   <= CTL_NOP_ISSTORE;
            isEcall_ctrl_to_ex   <= CTL_NOP_ISECALL;

        end else if (enable_write) begin // 如果允许写入（EX阶段没有暂停）
            // 锁存从ID阶段传来的数据和控制信号
            rdata1_to_ex         <= rdata1_from_id;
            rdata2_to_ex         <= rdata2_from_id;
            imm32_to_ex          <= imm32_from_id;
            rd_addr_to_ex        <= rd_addr_from_id;
            rs1_addr_to_ex       <= rs1_addr_from_id;
            rs2_addr_to_ex       <= rs2_addr_from_id;
            pc_to_ex             <= pc_from_id;
            ecall_type_to_ex     <= ecall_type_from_id;

            regWrite_ctrl_to_ex  <= regWrite_ctrl_from_id;
            ALUSrc_ctrl_to_ex    <= ALUSrc_ctrl_from_id;
            ALUOp_ctrl_to_ex     <= ALUOp_ctrl_from_id;
            branch_ctrl_to_ex    <= branch_ctrl_from_id;
            jump_ctrl_to_ex      <= jump_ctrl_from_id;
            isLoad_ctrl_to_ex    <= isLoad_ctrl_from_id;
            isStore_ctrl_to_ex   <= isStore_ctrl_from_id;
            isEcall_ctrl_to_ex   <= isEcall_ctrl_from_id;
        end
        // 如果 enable_write 为0 (EX阶段暂停), 则寄存器保持原值
    end

endmodule