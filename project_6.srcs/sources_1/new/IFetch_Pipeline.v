module IFetch (
    input clk,
    input reset,

    // --- 来自控制单元/冒险检测单元的控制信号 ---
    input        branch,      // PC来源选择信号: 0 = PC+4, 1 = 跳转
    input [31:0] target_pc_in_if,   // 跳转的目标PC地址
    input        stall_if,         


    input        debugMode,
    input [31:0] testScenario,      

    // --- to IF/ID Pipe Reg ---
    output reg [31:0] instruction_to_ifid, // 获取到的指令
    output reg [31:0] pc_current_to_ifid,  // 当前PC
    output reg [31:0] pc_plus_4_to_ifid    // 当前PC + 4
);

    parameter RESET_PC = 32'h00000000;


    reg [31:0] pc_reg;                  
    wire [31:0] pc_plus_4_calc;        
    wire [31:0] next_pc_for_pc_reg;     


    wire [31:0] bram_instruction_data; // read from Instruction Memory

    prgrom urom(
        .clka(clk),         
        .addra(pc_reg[15:2]),    
        .douta(bram_instruction_data) 
    );


    assign pc_plus_4_calc = pc_reg + 4;
    assign next_pc_for_pc_reg = branch ? target_pc_in_if : pc_plus_4_calc;

    // PC寄存器更新逻辑
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc_reg <= RESET_PC;
        end else if (!stall_if) begin // 如果IF阶段没有被暂停
            pc_reg <= next_pc_for_pc_reg;
        end
        //出现Data Hazard时，stall = 1, IF暂停
        //pc_reg 保持不变, 相当于重新获取当前指令
    end

    // Instruction and PC output
    always @(*) begin
        if (reset) begin 
            instruction_to_ifid = 32'h00000013; // NOP 
            pc_current_to_ifid  = RESET_PC;     
            pc_plus_4_to_ifid   = RESET_PC + 4;
        end
        //Debug Mode
        else begin
            if (debugMode && testScenario != 32'd0) begin
                instruction_to_ifid = testScenario; 
            end
            else begin
                instruction_to_ifid = bram_instruction_data;
            end
            pc_current_to_ifid  = pc_reg;           // 输出当前PC值
            pc_plus_4_to_ifid   = pc_plus_4_calc;   // 输出PC+4的值
        end
    end

endmodule