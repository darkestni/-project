module IFetch(clk, branch, zero, jump, jalr, imm32, reg_data, inst);
input clk, branch, zero, jump, jalr;
input [31:0] imm32;
input [31:0] reg_data;
output [31:0] inst;

reg [31:0] pc;
prgrom urom(.clka(clk), .addra(pc[15:2]), .douta(inst));

always @(posedge clk) begin
    if (pc === 32'bx)
        pc <= 32'h00000000;
    else if (jump)
        pc <= jalr ? (reg_data + imm32) : (pc + imm32);
    else if (branch && zero)
        pc <= pc + imm32;
    else
        pc <= pc + 4;
end

endmodule
