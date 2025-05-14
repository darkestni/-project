module Controller_ID (
    input [6:0] opcode,
    input [2:0] funct3,
    input [6:0] funct7,
    // input [1:0] ecall_type_in,

    // to id/ex pipeline register
    output reg regWrite_o,
    output reg ALUSrc_o, //0: rs2, 1: imm
    output reg [3:0] ALUOp_o, 
    output reg branch_o,
    output reg jump_o,
    output reg isLoad_o,
    // output reg isEcall_o ,
    output reg isStore_o

);

    // RISC-V Opcodes
    localparam OPCODE_RTYPE   = 7'b0110011;
    localparam OPCODE_ITYPE   = 7'b0010011; // Arith/Logic Immediate
    localparam OPCODE_LOAD    = 7'b0000011;
    localparam OPCODE_STORE   = 7'b0100011;
    localparam OPCODE_BRANCH  = 7'b1100011;
    localparam OPCODE_JALR    = 7'b1100111;
    localparam OPCODE_JAL     = 7'b1101111;
    localparam OPCODE_AUIPC   = 7'b0010111;
    // localparam OPCODE_LUI     = 7'b0110111; // LUI removed
    // localparam OPCODE_ECALL   = 7'b1110011; // ECALL removed

    localparam ALUOP_ADD      = 4'b0000; // Add
    localparam ALUOP_SUB      = 4'b0001; // Subtract
    localparam ALUOP_SLL      = 4'b0010; // Shift Left Logical
    localparam ALUOP_SLT      = 4'b0011; // Set Less Than (Signed)
    localparam ALUOP_SLTU     = 4'b0100; // Set Less Than (Unsigned)
    localparam ALUOP_XOR      = 4'b0101; // XOR
    localparam ALUOP_SRL      = 4'b0110; // Shift Right Logical
    localparam ALUOP_SRA      = 4'b0111; // Shift Right Arithmetic
    localparam ALUOP_OR       = 4'b1000; // OR
    localparam ALUOP_AND      = 4'b1001; // AND
    // localparam ALUOP_LUI_PASS_B = 4'b1010; 
    localparam ALUOP_BRANCH_CMP = 4'b1011; // Branch: Perform comparison
    localparam ALUOP_NOP      = 4'b1111; // No operation / Invalid

    localparam F7_SUB_SRA = 7'b0100000; // for SUB, SRA, SRAI
    localparam F7_ADD_SRL = 7'b0000000; // for ADD, SRL, SLLI, SRLI

    always @(*) begin
        regWrite_o = 1'b0;
        ALUSrc_o   = 1'b0;
        ALUOp_o    = ALUOP_NOP; // Default to NOP for safety
        branch_o   = 1'b0;
        jump_o     = 1'b0;
        isLoad_o   = 1'b0;
        isStore_o  = 1'b0;
        // isEcall_o  = 1'b0;

        case (opcode)
            OPCODE_RTYPE: begin
                regWrite_o = 1'b1;
                ALUSrc_o   = 1'b0; 
                case (funct3)
                    3'b000: ALUOp_o = (funct7 == F7_SUB_SRA) ? ALUOP_SUB : ALUOP_ADD;
                    3'b001: ALUOp_o = ALUOP_SLL;
                    3'b010: ALUOp_o = ALUOP_SLT;
                    3'b011: ALUOp_o = ALUOP_SLTU;
                    3'b100: ALUOp_o = ALUOP_XOR;
                    3'b101: ALUOp_o = (funct7 == F7_SUB_SRA) ? ALUOP_SRA : ALUOP_SRL;
                    3'b110: ALUOp_o = ALUOP_OR;
                    3'b111: ALUOp_o = ALUOP_AND;
                    default: ALUOp_o = ALUOP_NOP;
                endcase
            end
            OPCODE_ITYPE: begin 
                regWrite_o = 1'b1;
                ALUSrc_o   = 1'b1; 
                case (funct3)
                    3'b000: ALUOp_o = ALUOP_ADD;  
                    3'b001: ALUOp_o = ALUOP_SLL;  
                    3'b010: ALUOp_o = ALUOP_SLT;  // SLTI
                    3'b011: ALUOp_o = ALUOP_SLTU; // SLTIU
                    3'b100: ALUOp_o = ALUOP_XOR;  // XORI
                    3'b101: begin                // SRLI / SRAI
                        if (funct7 == F7_SUB_SRA) // instruction[31:25] for SRAI
                            ALUOp_o = ALUOP_SRA;
                        else // instruction[31:25] for SRLI is F7_ADD_SRL
                            ALUOp_o = ALUOP_SRL;
                    end
                    3'b110: ALUOp_o = ALUOP_OR;   // ORI
                    3'b111: ALUOp_o = ALUOP_AND;  // ANDI
                    default: ALUOp_o = ALUOP_NOP;
                endcase
            end
            OPCODE_LOAD: begin
                regWrite_o = 1'b1;
                ALUSrc_o   = 1'b1;
                ALUOp_o    = ALUOP_ADD;
                isLoad_o   = 1'b1;
            end
            OPCODE_STORE: begin
                ALUSrc_o   = 1'b1;
                ALUOp_o    = ALUOP_ADD; 
                isStore_o  = 1'b1;
            end
            OPCODE_BRANCH: begin
                ALUSrc_o   = 1'b0;
                branch_o   = 1'b1;
                ALUOp_o    = ALUOP_BRANCH_CMP;
            end
            OPCODE_JALR: begin
                regWrite_o = 1'b1;
                ALUSrc_o   = 1'b1;
                jump_o     = 1'b1;
                ALUOp_o    = ALUOP_ADD; 
            end
            OPCODE_JAL: begin
                regWrite_o = 1'b1;
                jump_o     = 1'b1;
                ALUSrc_o   = 1'b0; 
                ALUOp_o    = ALUOP_ADD; 
            end
            OPCODE_AUIPC: begin // rd = PC + U_imm
                regWrite_o = 1'b1;
                ALUSrc_o   = 1'b1; // PC is rs1_data, U_imm is imm_data
                ALUOp_o    = ALUOP_ADD;
            end

            default: begin // LUI, ECALL, and other opcodes
                regWrite_o = 1'b0;
                ALUSrc_o   = 1'b0;
                ALUOp_o    = ALUOP_NOP;
                branch_o   = 1'b0;
                jump_o     = 1'b0;
                isLoad_o   = 1'b0;
                isStore_o  = 1'b0;
                // isEcall_o  = 1'b0; 
            end
        endcase
    end
endmodule
