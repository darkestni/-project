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
wire kickOff = upg_rst_i | (~upg_rst_i & upg_done_i );

reg [31:0] last_pc;
reg [31:0] pc;
assign next_pc = last_pc+4; 
prgrom urom(.clka(kickOff? clk: upg_clk_i), .addra(kickOff? pc[15:2] : upg_adr_i), .douta(inst),.wea(kickOff ? 1'b0 : upg_wen_i),.dina(kickOff ? 32'h00000000 : upg_dat_i));
// prgrom instmem (
//  .clka (kickOff ? rom_clk_i : upg_clk_i ),
//  .wea (kickOff ? 1'b0
//  : upg_wen_i ),
//  .addra (kickOff ? rom_adr_i
//  : upg_adr_i ),
//  .dina (kickOff ? 32'h00000000 : upg_dat_i ),
//  .douta (Instruction_o)
//  );


// prgrom urom(.clka(clk), .addra(pc[15:2]), .douta(inst));


// prgrom your_instance_name (
//   .clka(clka),    // input wire clka
//   .wea(wea),      // input wire [0 : 0] wea
//   .addra(addra),  // input wire [13 : 0] addra
//   .dina(dina),    // input wire [31 : 0] dina
//   .douta(douta)  // output wire [31 : 0] douta
// );
always @(negedge clk ,posedge rst) begin
    last_pc<=pc;
    if(!rst)
            pc <= 32'h00000000;
    else if (jump)
        pc <= jalr ? (reg_data + imm32) : (pc + imm32);
    else if (branch && zero)
        pc <= pc + imm32;
    else
        pc <= pc+4;
end

endmodule