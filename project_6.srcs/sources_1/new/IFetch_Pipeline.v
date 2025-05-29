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
    output wire [31:0] bram_instruction_data, // 获取到的指令
    output reg [31:0] pc_current_to_ifid  // 与指令配对的当前PC
   
);

    // wire [31:0] bram_instruction_data; // 指令ROM输出的指令数据
    parameter RESET_PC = 32'h00000000;
    reg [31:0] pc; // 当前PC

    // 指令ROM实例化
    prgrom urom(
        .clka(!clk),
        .addra(pc[15:2]),    
        .douta(bram_instruction_data)
    );



    // always @(*) begin
    //         instruction_to_ifid = bram_instruction_data; //直接读取指令
    // end


    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= 32'h00000000;
            // instruction_to_ifid <= 32'h00000013;  // NOP = ADDI x0, x0, 0
            pc_current_to_ifid <= 32'h00000000;
        end else if (~stall_if) begin
            // 选择下一条PC：分支 or 顺序 +4
            if (branch) begin
                pc <= target_pc_in_if;
            end else begin
                if (pc >= 32'hFFFFFF00) begin
                    pc <= pc;
                end else begin
                    // pc <= pc + 4; // 直接加4
                    // pc <= pc + 4; // 直接加4
                    // instruction_to_ifid <= bram_instruction_data;
                pc <= pc + 4;
                end
            end

            // instruction_to_ifid <= bram_instruction_data;
            pc_current_to_ifid <= pc;
        end else begin
            // stall 时不更新 PC 和输出（保持输出不变）
            // instruction_to_ifid <= instruction_to_ifid;  //时钟上升沿时读取指令
            pc_current_to_ifid <= pc_current_to_ifid;

        end
    end



endmodule
