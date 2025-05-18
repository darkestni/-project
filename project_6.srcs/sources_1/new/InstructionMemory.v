// File: InstructionMemory.v
module InstructionMemory (
    input clk, // For synchronous ROM if prgrom needs it
    input reset, // For NOP output on reset

    input [31:0] pc_address_in,     // 当前PC值 (来自PC_Register)
    input [31:0] Instruction_prgrom,
    // Debug control
    input        debugMode_in,
    input [31:0] testScenario_in,

    output reg [31:0] instruction_out_final // 获取到的指令
);

    parameter NOP_INSTRUCTION = 32'h00000013;
    parameter RESET_PC_FOR_IMEM_RESET_NOP = 32'h00000000; // Not strictly needed here but good for consistency

    wire [31:0] rom_instruction_data;

    // Instantiate your program ROM
    // Ensure the address width for prgrom matches pc_address_in[15:2] or similar
    // For example, if prgrom expects a 14-bit word address for a 64KB ROM (16K words)
    // prgrom u_instr_rom (
    //     .clka(clk),                 // Assuming prgrom is synchronous
    //     .addra(pc_address_in[15:2]), // Example: Use bits 15 down to 2 for word addressing
    //                                 // Adjust this based on your prgrom's address input width
    //                                 // and how your PC maps to ROM addresses.
    //     .douta(rom_instruction_data)
    // );

    always @(*) begin
        if (reset) begin
            instruction_out_final = NOP_INSTRUCTION;
        end else if (debugMode_in && testScenario_in != 32'd0) begin // testScenario has priority in debug mode if non-zero
            instruction_out_final = testScenario_in;
        end else begin
            instruction_out_final = Instruction_prgrom;
        end
    end

endmodule
