module Controller (
    input [6:0] opcode,
    input [31:0] ALU_result,
    input [31:0] read_data1,     // 新增：用于分支条件判断
        input [31:0] read_data2,     // 新增：用于分支条件判断  
        input [2:0] funct3,          // 新增：用于分支类型判断
    output reg RegWrite, ALUSrc, branch, jump,
    output reg [1:0] ALUOp,
    output reg MemorIO_to_Reg, MemRead, MemWrite,
    output reg  IORead, IOWrite_led, IOWrite_seg,
    output reg jalr,
    output reg branch_taken,
    output reg is_jal_jalr
);

always @(*) begin
    // ??????
    RegWrite = 0;
    ALUSrc = 0;
    branch = 0;
    jump = 0;
    ALUOp = 2'b00;
    MemorIO_to_Reg = 0;
    MemRead = 0;
    MemWrite = 0;
    IORead = 0;
    IOWrite_led = 0;
    IOWrite_seg = 0;
    jalr = 0;
    is_jal_jalr = 0;
    case (opcode)
        7'b0110011: begin // R-type: add, sub, slt, sltu, and, or, xor, sll, srl, sra
            RegWrite = 1;
            ALUSrc = 0;
            ALUOp = 2'b10;
        end
        7'b0010011: begin // I-type: addi, slti, sltiu, andi, ori, xori, slli, srli, srai
            RegWrite = 1;
            ALUSrc = 1;
            ALUOp = 2'b00;
        end
        7'b0000011: begin // Load (e.g., lb, lbu, lw)
            RegWrite = 1;
            ALUSrc = 1;
            ALUOp = 2'b00;
            MemorIO_to_Reg = 1;
            if (ALU_result == 32'hFFFF_F010) begin
                IORead = 1;
                
            end else begin
                MemRead = 1;

            end
        end

        7'b0100011: begin // Store (e.g., sb)
            ALUSrc = 1;
            ALUOp = 2'b00;
            if (ALU_result == 32'hFFFF_F000)
                IOWrite_led = 1;
            else if (ALU_result == 32'hFFFF_F020)
                IOWrite_seg = 1;
            else
                MemWrite = 1;
        end
        7'b1100011: begin // Branch (e.g., beq, blt, bltu)
            branch = 1;
            ALUOp = 2'b01;
        end
        7'b1101111: begin // jal
            RegWrite = 1;
            jump = 1;
            ALUOp = 2'b00;
            is_jal_jalr = 1'b1;
        end
        7'b1100111: begin // jalr
            RegWrite = 1;
            jump = 1;
            ALUSrc = 1;
            ALUOp = 2'b00;
            jalr = 1;
            is_jal_jalr = 1'b1;
        end
        7'b0110111, 7'b0010111: begin // lui, auipc
            RegWrite = 1;
            ALUSrc = 1;
            ALUOp = 2'b11;
        end
    endcase
end

always @(*) begin
    if (branch) begin
        case (funct3)
            3'b000: branch_taken = (read_data1 == read_data2);                    // beq
            3'b001: branch_taken = (read_data1 != read_data2);                    // bne  
            3'b100: branch_taken = ($signed(read_data1) < $signed(read_data2));   // blt
            3'b101: branch_taken = ($signed(read_data1) >= $signed(read_data2));  // bge
            3'b110: branch_taken = (read_data1 < read_data2);                     // bltu
            3'b111: branch_taken = (read_data1 >= read_data2);                    // bgeu
            default: branch_taken = 1'b0;
        endcase
    end else begin
        branch_taken = 1'b0;
    end
end

endmodule