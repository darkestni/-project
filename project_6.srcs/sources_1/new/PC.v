// File: PC_Register.v
module PC (
    input clk,
    input reset,

    // Control signals
    input        stall_pc,          // 暂停PC更新 (来自Hazard Unit或整体暂停)
    input        branch,   // 是否进行分支/跳转 (来自EX阶段)
    input [31:0] branch_target_pc,  // 分支/跳转的目标PC (来自EX阶段)

    output reg [31:0] current_pc_out // 当前PC值
);

    parameter RESET_PC = 32'h00000000;
    wire [31:0] pc_plus_4;
    wire [31:0] next_pc_selected;

    assign pc_plus_4 = current_pc_out + 4;
    assign next_pc_selected = branch ? branch_target_pc : pc_plus_4;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_pc_out <= RESET_PC;
        end else if (!stall_pc) begin
            current_pc_out <= next_pc_selected;
        end
        // If stall_pc is true, current_pc_out holds its value.
    end

endmodule
