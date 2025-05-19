module IFetch(clk, branch, zero, imm32, inst);
input clk, branch, zero;
input [31:0] imm32;
output [31:0] inst;

reg [31:0] pc;
prgrom urom(.clka(clk), .addra(pc[15:2]), .douta(inst));

always @(posedge clk) begin
    
    if (pc === 32'bx) 
        pc <= 32'h00000000;
    // ·ÖÖ§ÅÐ¶Ï
    else if (branch && zero)
        pc <= pc + imm32;
    // Ë³ÐòÖ´ÐÐ
    else 
        pc <= pc + 4;
end

endmodule