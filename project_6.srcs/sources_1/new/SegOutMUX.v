module SegOutMUX(
    input debugOn,
    input [31:0] write_data_to_seg,
    input [2:0] debugMode,
    input [31:0] x1_2,
    input [31:0] x3_4,
    input [31:0] x5,
    input [31:0] ifid_instruction,
    input [31:0] datahazard_detect_stall_pc_ifid_idexnop, 
    input [31:0] clk_count, //时钟计数器
    output reg [31:0] segOut
);
always @(*) begin
    if (debugOn) begin
    case (debugMode)
        // 4'b0000: segOut = x1;
        // 4'b0001: segOut = x2;
        // 4'b0010: segOut = x3;
        // 4'b0011: segOut = x4;
        // 4'b0100: segOut = x5;
        // 4'b0101: segOut = ifid_instruction;
        // // 4'b0110: segOut = if_pc;
        // 4'b0110: segOut = clk_count; //时钟计数器
        // 4'b0111: segOut = ex_operand_a;
        // 4'b1000: segOut = ex_operand_b;
        // 4'b1001: segOut = idex_rs1;
        // 4'b1010: segOut = idex_rs2;
        // 4'b1011: segOut = ex_whether_jump;
        // 4'b1100: segOut = idex_jump_target;
        // 4'b1101: segOut = forward_a_b_ex; //左1是forwardA 左2是forwardB
        // 4'b1110: segOut = datahazard_detect_stall_pc_ifid_idexnop; //数码管左1是stall_if 左2是ifid_stall 左3是idex_nop
        // 4'b1111: segOut = write_data_to_seg; //时钟计数器
        // default: segOut = write_data_to_seg; //默认输出
        3'b000: segOut = x1_2;
        // 3'b001: segOut = x3_4;
        3'b001: segOut = 32'h12435678;
        3'b010: segOut = x5;
        3'b011: segOut = ifid_instruction;
        3'b100: segOut = datahazard_detect_stall_pc_ifid_idexnop; //数码管左1是stall_if 左2是ifid_stall 左3是idex_nop 4-5是forwardA 6-7 forwardB 8whether jump
        3'b101: segOut = clk_count; //时钟计数器
        3'b110: segOut = write_data_to_seg; //空
        3'b111: segOut = write_data_to_seg; //时钟计数器
        default: segOut = write_data_to_seg; //默认输出
    endcase
    end else begin
        segOut = write_data_to_seg;
    end

    end


endmodule