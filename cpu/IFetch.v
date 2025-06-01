module IFetch(
input clk, branch, zero, jump, jalr,
input rst,
input [31:0] imm32,
input [31:0] reg_data,
output [31:0] inst,
output [31:0] next_pc,
// UART Programmer Pinouts
input upg_rst_i, // UPG reset (Active High)
input upg_clk_i, // UPG clock (10MHz)
input upg_wen_i, // UPG write enable
input[13:0] upg_adr_i, // UPG write address
input[31:0] upg_dat_i, // UPG write data
input upg_done_i // 1 if program finished
);

reg [31:0] last_pc;
reg [31:0] pc;
assign next_pc = last_pc+4; 
//prgrom urom(.clka(clk), .addra(pc[15:2]), .douta(inst));
wire kickOff = upg_rst_i | (~upg_rst_i & upg_done_i );
prgrom instmem (
    .clka (kickOff ? clk : upg_clk_i ),
    .wea (kickOff ? 1'b0 : upg_wen_i ),
    .addra (kickOff ? pc[15:2] : upg_adr_i ),
    .dina (kickOff ? 32'h00000000 : upg_dat_i ),
    .douta (inst)
);

always @(negedge clk ,posedge rst) begin
    last_pc<=pc;
    if(rst)
            pc <= 32'h00000000;
    else if (jump)
        pc <= jalr ? (reg_data + imm32) : (pc + imm32);
    else if (branch && zero)
        pc <= pc + imm32;
    else
        pc <= pc+4;
end

endmodule