module DebugMode(
    input debugMode,
    output wire [31:0]segOut,
    input [3:0] segOutSel,
    input debug_clk,
    input clk, // pass to cpu
    input reset, // pass to cpu
    input  [15:0] switch_in, // pass to cpu
    output [15:0] led_out // pass to cpu
);
    localparam SEG_X1 = 4'b0000;
    localparam SEG_X2 = 4'b0001;
    localparam SEG_X3 = 4'b0010;
    localparam SEG_X4 = 4'b0011;
    localparam SEG_X5 = 4'b0100;
    localparam SEG_IFID_INSTRUCTION = 4'b0101;
    localparam SEG_IF_PC = 4'b0110;
    localparam SEG_EX_OPERATE1 = 4'b0111;
    localparam SEG_EX_OPERATE2 = 4'b1000;
    localparam SEG_IDEX_RS1_ADDR = 4'b1001;
    localparam SEG_IDEX_RS2_ADDR = 4'b1010;
    localparam SEG_EX_WHETHER_JUMP = 4'b1011;
    localparam SEG_IDEX_JUMP_TARGET = 4'b1100;
    localparam SEG_FORWARD_A_B_EX = 4'b1101; //左1是forwardA 左2是forwardB
    localparam SEG_DATAHAZARD_DETECT_STALL_PC_IFID_IDEXNOP = 4'b1110;//数码管左1是stall_if 左2是ifid_stall 左3是idex_nop
    localparam SEG_CLK_COUNT = 4'b1111; //时钟计数器
    // localparam SEG_CPU_OUT = 4'b1111;

    wire clk_to_cpu;
    assign clk_to_cpu = debugMode ? debug_clk : clk;
    PipelineCPU_Test u_pipeline_cpu_test(
        .clk(clk_to_cpu),
        .reset(reset),
        .switch_in(switch_in),
        .led_out(led_out),
        //other signals
    );

        assign segOut = debugMode ? 
            (segOutSel == SEG_X1 ? u_pipeline_cpu_test.x1 : //这里填入CPU信号
            segOutSel == SEG_X2 ? u_pipeline_cpu_test.x2 :
            segOutSel == SEG_X3 ? u_pipeline_cpu_test.x3 :
            segOutSel == SEG_X4 ? u_pipeline_cpu_test.x4 :
            segOutSel == SEG_X5 ? u_pipeline_cpu_test.x5 :
            segOutSel == SEG_IFID_INSTRUCTION ? u_pipeline_cpu_test.ifid_instruction :
            segOutSel == SEG_IF_PC ? u_pipeline_cpu_test.pc_current_to_ifid :
            segOutSel == SEG_EX_OPERATE1 ? u_pipeline_cpu_test.rdata1_from_idex :
            segOutSel == SEG_EX_OPERATE2 ? u_pipeline_cpu_test.rdata2_from_idex :
            segOutSel == SEG_IDEX_RS1_ADDR ? u_pipeline_cpu_test.rs1_addr_from_idex :
            segOutSel == SEG_IDEX_RS2_ADDR ? u_pipeline_cpu_test.rs2_addr_from_idex :
            segOutSel == SEG_EX_WHETHER_JUMP ? u_pipeline_cpu_test.branch_or_jump_to_if :
            segOutSel == SEG_IDEX_JUMP_TARGET ? u_pipeline_cpu_test.target_pc_ex :
            segOutSel == SEG_FORWARD_A_B_EX ? {u_pipeline_cpu_test.forwardA_from_idex, u_pipeline_cpu_test.forwardB_from_idex}:
            segOutSel == SEG_DATAHAZARD_DETECT_STALL_PC_IFID_IDEXNOP? {u_pipeline_cpu_test.pc_stall, u_pipeline_cpu_test.ifid_stall, u_pipeline_cpu_test.idex_nop}:
            32'b0) : cpu_seg_out; //这里填入CPU信号
        

endmodule