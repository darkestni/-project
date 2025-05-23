module DebugMode(
    // input debugMode,
    // output wire [31:0]segOut, 
    // input [2:0] segOutSel,
    // input debug_clk,
    input clk, 
    input reset, // pass to cpu
    input  [15:0] switch_in, // pass to cpu
    output [15:0] led, // pass to cpu
    input [4:0] button, //4 up 3 down 2 left 1 right 0 center
    output wire[7:0]seg1,
    output wire[7:0]seg2,
    output wire[7:0]tub_control
);
    wire [31:0] segOut;
    wire [7:0] seg_cs;
    wire clkin;
    assign clkin = clk;
    wire clkout;
    assign tub_control = seg_cs;
    // localparam SEG_X1 = 4'b0000;
    // localparam SEG_X2 = 4'b0001;
    // localparam SEG_X3 = 4'b0010;
    // localparam SEG_X4 = 4'b0011;
    // localparam SEG_X5 = 4'b0100;
    // localparam SEG_IFID_INSTRUCTION = 4'b0101;
    // localparam SEG_IF_PC = 4'b0110;
    // localparam SEG_EX_OPERATE1 = 4'b0111;
    // localparam SEG_EX_OPERATE2 = 4'b1000;
    // localparam SEG_IDEX_RS1_ADDR = 4'b1001;
    // localparam SEG_IDEX_RS2_ADDR = 4'b1010;
    // localparam SEG_EX_WHETHER_JUMP = 4'b1011;
    // localparam SEG_IDEX_JUMP_TARGET = 4'b1100;
    // localparam SEG_FORWARD_A_B_EX = 4'b1101; //左1是forwardA 左2是forwardB
    // localparam SEG_DATAHAZARD_DETECT_STALL_PC_IFID_IDEXNOP = 4'b1110;//数码管左1是stall_if 左2是ifid_stall 左3是idex_nop
    // localparam SEG_CLK_COUNT = 4'b1111; //时钟计数器
    // localparam SEG_CPU_OUT = 4'b1111;
    localparam SEG_X1_2 = 3'b000; //左4 x1 右4 x2
    localparam SEG_X3_4 = 3'b001; //左4 x3 右4 x4
    localparam SEG_X5 = 3'b010; //x5
    localparam SEG_IFID_INSTRUCTION = 3'b011;
    localparam SEG_DATAHAZARD_DETECT_STALL_PC_IFID_IDEXNOP = 3'b100;//数码管左1是stall_if 左2是ifid_stall 左3是idex_nop 4-5是forwardA 6-7 forwardB 8whether jump
    localparam SEG_CLK_COUNT = 3'b101; //时钟计数器
    //110 空
    localparam SEG_CPU_OUT = 3'b111;
    // wire [7:0] seg_data2;
    wire debugMode;
    wire [2:0] segOutSel;
    assign debugMode = switch_in[0];
    assign segOutSel = switch_in[3:1];

    wire debug_clk;
    wire clk_to_cpu;
    wire [31:0] x1;
    wire [31:0] x2;
    wire [31:0] x3;
    wire [31:0] x4;
    wire [31:0] x1_2;
    wire [31:0] x3_4;
    wire [31:0] x5;
    wire [31:0] dbg_ifid_instruction;
    wire [31:0] dbg_if_pc;
    wire [31:0] dbg_ex_operand_a;
    wire [31:0] dbg_ex_operand_b;
    wire [31:0] dbg_idex_rs1;
    wire [31:0] dbg_idex_rs2;
    wire [31:0] dbg_ex_whether_jump;
    wire [31:0] dbg_idex_jump_target;
    wire [31:0] dbg_forward_a_b_ex; //左1是forwardA 左2是forwardB
    wire [31:0] dbg_datahazard_detect_stall_pc_ifid_idexnop; //数码管左1是stall_if 左2是ifid_stall 左3是idex_nop
    wire [31:0] dbg_clk_count; //时钟计数器
    wire [31:0] write_data_to_seg;
    wire [31:0] control_signal;
    assign clk_to_cpu = debugMode ? debug_clk : clkout;
    assign x1_2 = {x1[15:0], x2[15:0]};
    assign x3_4 = {x3[15:0], x4[15:0]};
    assign control_signal = {dbg_datahazard_detect_stall_pc_ifid_idexnop[31:28],dbg_datahazard_detect_stall_pc_ifid_idexnop[27:24],
    dbg_datahazard_detect_stall_pc_ifid_idexnop[23:20],dbg_forward_a_b_ex[31:24],dbg_forward_a_b_ex[23:16],4'b0};
    //数码管左1是stall_if 左2是ifid_stall 左3是idex_nop 4-5是forwardA 6-7 forwardB 8whether jump
    PipelineCPU cpu (
        // .clk(clk_to_cpu),
        .clk(clkout),
        .reset(reset),
        //for test (existing)
        .x1(x1),
        .x2(x2),
        .x3(x3),
        .x4(x4),
        .x5(x5),
        .dbg_ifid_instruction(dbg_ifid_instruction),
        .dbg_if_pc(dbg_if_pc),
        .dbg_ex_operand_a(dbg_ex_operand_a),
        .dbg_ex_operand_b(dbg_ex_operand_b),
        .dbg_idex_rs1(dbg_idex_rs1),
        .dbg_idex_rs2(dbg_idex_rs2),
        .dbg_ex_whether_jump(dbg_ex_whether_jump),
        .dbg_idex_jump_target(dbg_idex_jump_target),
        .dbg_forward_a_b_ex(dbg_forward_a_b_ex), //左1是forwardA 左2是forwardB
        .dbg_datahazard_detect_stall_pc_ifid_idexnop(dbg_datahazard_detect_stall_pc_ifid_idexnop), //数码管左1是stall_if 左2是ifid_stall 左3是idex_nop
        .dbg_clk_count(dbg_clk_count), //时钟计数器
        // pass to cpu
        .debugMode(1'b0),
        .testScenario(32'b0),
        .switch_in(switch_in), 
        .led_out(led), 
        .seg_physical_out(write_data_to_seg)
    );

    SegOutMUX segOutMUX(
        .debugOn(debugMode),
        .write_data_to_seg(write_data_to_seg),
        .debugMode(segOutSel),
        .x1_2(x1_2),
        .x3_4(x3_4),
        .x5(x5),
        .ifid_instruction(dbg_ifid_instruction),
        .datahazard_detect_stall_pc_ifid_idexnop(control_signal), 
        .clk_count(dbg_clk_count), //时钟计数器
        .segOut(segOut)
    );
    // reg [31:0] test_show;
    // always @(*) begin
    //     test_show = 32'h12345678;
    // end
    show_number show_number(
        .clk(clk),
        .rst(reset),
        .data(segOut),
        // .data(test_show),
        .seg_data(seg1),
        .seg_data2(seg2),
        .seg_cs(seg_cs)
    );

    //button to switch state
    wire button0;
    wire button4;
//     debounce u1 (
//     .clk(clk),
//     .run_stop(reset),      // 复位信号控制模块运行
//     .key_in(button[0]),
//     .key_out(button0)
// );
//     reg debug_state;
//     always @(posedge clk or negedge reset) begin
//         if (!reset)
//             debug_state <= 1'b0;
//         else if (button0)   // 只在按键真正稳定按下时改变状态
//             debug_state <= ~debug_state;
//     end

//     assign debugMode = debug_state;

    debounce u2 (
    .clk(clk),
    .run_stop(reset),      // 复位信号控制模块运行
    .key_in(button[4]),
    .key_out(button4)
);
    reg debug_clk_state;
    always @(posedge clk or negedge reset) begin
        if (!reset)
            debug_clk_state <= 1'b0;
        else if (button4)   // 只在按键真正稳定按下时改变状态
            debug_clk_state <= ~debug_clk_state;
    end

    assign debug_clk = debug_clk_state;
    //button to switch state


    clk_div_25mhz clk_div_25mhz(
        .clk_in(clk),
        .rst(reset),
        .clk_out(clkout)
    );



        

endmodule