module DataHazardDetect (
    // Inputs from ID/EX pipeline register (EX stage's current instruction info)
    input        ex_isLoad,    // Is the instruction currently in EX a Load?
    input [4:0]  ex_rd_addr,   // Destination register of the instruction in EX

    // Inputs from IF/ID pipeline register (ID stage's current instruction info)
    // More accurately, these should be the rs1/rs2 from the instruction *currently in ID*,
    // which are the outputs of the ID stage's decoder, *before* they get latched by ID/EX.
    // Your connections: .id_rs1_addr(rs1_addr_from_id), .id_rs2_addr(rs2_addr_from_id)
    // This is correct if rs1_addr_from_id and rs2_addr_from_id are the decoded source
    // register addresses of the instruction currently being processed in the ID stage.
    input [4:0]  id_rs1_addr,  // rs1 of the instruction currently in ID
    input [4:0]  id_rs2_addr,  // rs2 of the instruction currently in ID

    // Outputs to control pipeline
    output reg pc_stall,       // Stall the PC and IF stage
    output reg ifid_stall,     // Stall the IF/ID register (disable write)
    output reg idex_nop        // Insert NOP into ID/EX register (effectively flush ID's output)
);

    always @(*) begin
        pc_stall   = 1'b0;
        ifid_stall = 1'b0;
        idex_nop   = 1'b0;

        if (ex_isLoad && (ex_rd_addr != 5'd0) && // If instr in EX is a Load and its dest is not x0
            ( (ex_rd_addr == id_rs1_addr) ||   // And its dest is rs1 of instr in ID
              (ex_rd_addr == id_rs2_addr) )    // Or its dest is rs2 of instr in ID
           )
        begin
            // Load-Use Hazard detected!
            pc_stall   = 1'b1; // Freeze PC
            ifid_stall = 1'b1; // Prevent IF/ID from latching new (potentially wrong) instruction from IF
            idex_nop   = 1'b1; // Insert a NOP into ID/EX instead of the stalled ID instruction
        end
    end

endmodule
