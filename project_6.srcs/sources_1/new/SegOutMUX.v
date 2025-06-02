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
    input [31:0] ex_operand_a,
    input [31:0] ex_operand_b,
    input flush_idex,
    output reg [31:0] segOut
);
always @(*) begin
    if (debugOn) begin
    case (debugMode)

        3'b000: segOut = x1_2;
        3'b001: segOut = x3_4;
        // 3'b001: segOut = 32'h12435678;
        3'b010: segOut = x5;
        3'b011: segOut = ifid_instruction;
        3'b100: segOut = datahazard_detect_stall_pc_ifid_idexnop; //数码管左1是stall_if 左2是ifid_stall 左3是idex_nop 4-5是forwardA 6-7 forwardB 8whether jump
        3'b101: segOut = clk_count; //时钟计数器
        3'b110: segOut = flush_idex; 
        3'b111: segOut = {ex_operand_a[15:0],ex_operand_b[15:0]}; //时钟计数器
        default: segOut = write_data_to_seg; //默认输出
    endcase
    end else begin
        segOut = write_data_to_seg;
    end

    end


endmodule