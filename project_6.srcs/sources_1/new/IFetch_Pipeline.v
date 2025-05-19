module IFetch (
    input clk,
    input reset,

    // --- 来自控制单元/冒险检测单元的控制信号 ---
    input        branch,              // PC来源选择信号: 1 = 跳转/分支发生
    input [31:0] target_pc_in_if,     // 跳转/分支的目标PC地址
    input        stall_if,            // IF阶段暂停信号 (暂停所有PC更新)

    input        debugMode,
    input [31:0] testScenario,

    // --- to IF/ID Pipe Reg ---
    output reg [31:0] instruction_to_ifid, // 获取到的指令
    output reg [31:0] pc_current_to_ifid,  // 与指令配对的当前PC
    output reg [31:0] pc_plus_4_to_ifid    // 与指令配对的PC + 4
);

    parameter RESET_PC = 32'h00000000;

    reg [31:0] pc_counter_reg;          // 常规情况下每周期+4的PC计数器
    reg [31:0] pc_for_instruction_reg;  // 用于与从ROM读出的指令配对的PC

    wire [31:0] pc_output_if;           // IF阶段实际用于取指的PC (组合逻辑)
    wire [31:0] pc_counter_plus_4;
    wire [31:0] next_pc_counter;

    wire [31:0] bram_instruction_data; // 从指令ROM读取的数据

    // 指令ROM实例化
    prgrom urom(
        .clka(clk),
        .addra(pc_output_if[15:2]),    // ROM使用组合逻辑产生的 pc_output_if 进行寻址
        .douta(bram_instruction_data)
    );

    // 组合逻辑决定IF阶段实际使用的PC
    // 如果发生分支，使用目标PC；否则使用常规计数器的PC
    assign pc_output_if = branch ? target_pc_in_if : pc_counter_reg;

    // pc_counter_reg 的下一个值的计算逻辑
    assign pc_counter_plus_4 = pc_counter_reg + 4;
    // 如果发生分支，pc_counter_reg 需要被校正到 target_pc_in_if + 4
    // 否则，它就是简单地 +4
    assign next_pc_counter = branch ? (target_pc_in_if + 4) : pc_counter_plus_4;

    // pc_counter_reg 和 pc_for_instruction_reg 的更新逻辑
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc_counter_reg         <= RESET_PC;
            pc_for_instruction_reg <= RESET_PC;
        end else if (!stall_if) begin // 只有在不暂停时才更新
            pc_counter_reg         <= next_pc_counter;
            // pc_for_instruction_reg 锁存上一个周期实际用于取指的PC (pc_output_if)
            // 由于 pc_output_if 是组合逻辑，它在当前周期就已经反映了 branch 的影响
            // 所以，如果当前周期 branch=1, pc_output_if = target_pc_in_if
            // 那么 pc_for_instruction_reg 应该锁存这个 target_pc_in_if
            pc_for_instruction_reg <= pc_output_if;
        end
        // 如果 stall_if 为1, 所有寄存器保持不变
    end

    // 输出逻辑
    always @(*) begin
        if (reset) begin
            instruction_to_ifid = 32'h00000013; // NOP
            pc_current_to_ifid  = RESET_PC;
            pc_plus_4_to_ifid   = RESET_PC + 4;
        end else begin
            if (debugMode && testScenario != 32'd0) begin
                instruction_to_ifid = testScenario;
                // 在debug模式下，pc_current_to_ifid 应该与 testScenario 对应的PC是什么？
                // 如果 testScenario 是为了覆盖特定PC的指令，那么这个PC也需要一种方式传入或固定。
                // 为了简单，我们仍然让它基于 pc_for_instruction_reg，但要注意这可能不完全符合debug意图。
                // 或者，debugMode下，pc_output_if 也应该被testScenario的某种PC覆盖。
                // 暂时保持与非debug模式一致的PC来源，但指令被覆盖。
                pc_current_to_ifid  = pc_for_instruction_reg; // 或者是一个固定的debug PC
                pc_plus_4_to_ifid   = pc_for_instruction_reg + 4;
            end else begin
                instruction_to_ifid = bram_instruction_data; // 来自ROM，对应上一个周期的 pc_output_if
                pc_current_to_ifid  = pc_for_instruction_reg;  // 与 bram_instruction_data 配对的PC
                pc_plus_4_to_ifid   = pc_for_instruction_reg + 4;
            end
        end
    end

endmodule
