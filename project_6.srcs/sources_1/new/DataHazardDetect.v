module DataHazardDetect ( //处理Load-Use Hazard
    input idex_isLoad,
    input [4:0] idex_rd_addr,
    input [4:0] ifid_rs1_addr,
    input [4:0] ifid_rs2_addr,
    output reg pc_stall,
    output reg ifid_stall,
    output reg idex_nop
);
    // EX阶段是LW指令 且LW的目标寄存器是当前指令的rs1 或LW的目标寄存器是当前指令的rs2
//     if (IDEX_MemRead_ctrl == 1 && // EX阶段是LW指令
//     ( (IDEX_Rd_addr == IFID_Rs1_addr_current_instr && IFID_Rs1_addr_current_instr != 0) || // 且LW的目标寄存器是当前指令的rs1
//       (IDEX_Rd_addr == IFID_Rs2_addr_current_instr && IFID_Rs2_addr_current_instr != 0)    // 或LW的目标寄存器是当前指令的rs2
//     )
//    ) then
//     // Load-Use Hazard Detected!
//     PC_Stall = 1;
//     IFID_Stall = 1; // or IFID_Write_Disable = 1
    always @(*) begin
        if (idex_isLoad) begin
            if (idex_rd_addr == ifid_rs1_addr && ifid_rs1_addr != 5'd0) begin
                pc_stall   = 1;
                ifid_stall = 1;
                idex_nop   = 1;
            end else if (idex_rd_addr == ifid_rs2_addr && ifid_rs2_addr != 5'd0) begin
                pc_stall   = 1;
                ifid_stall = 1;
                idex_nop   = 1;
            end else begin
                pc_stall   = 0;
                ifid_stall = 0;
                idex_nop   = 0;
            end
        end else begin
            pc_stall   = 0;
            ifid_stall = 0;
            idex_nop   = 0;
        end
    end

    endmodule