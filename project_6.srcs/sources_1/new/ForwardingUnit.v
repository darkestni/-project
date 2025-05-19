module ForwardingUnit (
    input [4:0] id_ex_rs1,
    input [4:0] id_ex_rs2,
    input [4:0] ex_mem_rd,
    input ex_mem_regWrite,
    input [4:0] mem_wb_rd,
    input mem_wb_regWrite,
    output reg [1:0] forwardA, //控制操作数1 (OperandA) 的来源。
// 2'b00: 来自ID/EX寄存器的 RData1 (即从寄存器堆读出的值)。
// 2'b01: 来自EX/MEM寄存器的ALU结果 (前推自上一条指令的EX结果)。
// 2'b10: 来自MEM/WB寄存器的写回数据 (前推自上上一条指令的WB结果)。
    output reg [1:0] forwardB //控制EX阶段第二个ALU操作数 (OperandB，如果是来自寄存器的那个) 的来源。
);

    always @(*) begin
        // ForwardA
        if (ex_mem_regWrite && ex_mem_rd != 0 && ex_mem_rd == id_ex_rs1)
            forwardA = 2'b10;  // EX/MEM 转发
        else if (mem_wb_regWrite && mem_wb_rd != 0 && mem_wb_rd == id_ex_rs1)
            forwardA = 2'b01;  // MEM/WB 转发
        else
            forwardA = 2'b00;  // 无转发

        // ForwardB
        if (ex_mem_regWrite && ex_mem_rd != 0 && ex_mem_rd == id_ex_rs2)
            forwardB = 2'b10;
        else if (mem_wb_regWrite && mem_wb_rd != 0 && mem_wb_rd == id_ex_rs2)
            forwardB = 2'b01;
        else
            forwardB = 2'b00;
    end

endmodule