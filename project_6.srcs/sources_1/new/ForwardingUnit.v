module ForwardingUnit (
    input [4:0] id_ex_rs1,
    input [4:0] id_ex_rs2,
    input [4:0] ex_mem_rd,
    input ex_mem_regWrite,
    input [4:0] mem_wb_rd,
    input mem_wb_regWrite,
    output reg [1:0] forwardA,
    output reg [1:0] forwardB
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