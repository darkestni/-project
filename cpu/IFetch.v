module IFetch(clk, branch, zero, jump, jalr,rst, imm32, reg_data, inst, next_pc);
input clk, branch, zero, jump, jalr;
input rst;
input [31:0] imm32;
input [31:0] reg_data;
output [31:0] inst;
output [31:0] next_pc;
reg [31:0] last_pc;
reg [31:0] pc;
assign next_pc = last_pc+4; 
prgrom urom(.clka(clk), .addra(pc[15:2]), .douta(inst));

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