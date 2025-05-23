module clk_select (
    input  wire clk_auto,     // 自动时钟输入
    input  wire btn_step,     // 按钮，手动时钟源
    input  wire mode_select,  // 模式选择：0=自动，1=单步
    input  wire rst,
    output wire clk_sys       // 输出到系统的总时钟
);

    // 手动时钟生成：按钮去抖 + 打拍
    reg [2:0] btn_sync;
    always @(posedge clk_auto or posedge rst) begin
        if (rst)
            btn_sync <= 3'b000;
        else
            btn_sync <= {btn_sync[1:0], btn_step};
    end
    wire step_pulse = btn_sync[2] & ~btn_sync[1];  // 上升沿检测

    reg clk_manual = 0;
    always @(posedge clk_auto or posedge rst) begin
        if (rst)
            clk_manual <= 0;
        else if (step_pulse)
            clk_manual <= ~clk_manual;
    end

    // 使用 BUFGCTRL 实现安全的时钟切换
    wire clk0 = clk_auto;
    wire clk1 = clk_manual;

    (* LOC = "BUFGCTRL_X0Y31" *) BUFGCTRL clk_mux (
        .I0(clk0),
        .I1(clk1),
        .S0(~mode_select),
        .S1(mode_select),
        .CE0(1'b1),
        .CE1(1'b1),
        .IGNORE0(1'b0),
        .IGNORE1(1'b0),
        .O(clk_sys)
    );
endmodule
