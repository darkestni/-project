module PipelineCPU (
    input clk,
    input reset,
    input debugMode,
    input step,
    input [7:0] dipSwitch,
    input button,
    input uart_rx,
    input [1:0] baud_select,
    output [7:0] led,
    output [6:0] seg,
    output [3:0] an,
    output [3:0] vga_r, vga_g, vga_b,
    output vga_hs, vga_vs
);

    // ·ÖÆµÆ÷£º100 MHz -> 50 MHz
    reg clk_div;
    reg counter;
    initial begin
        counter = 0;
        clk_div = 0;
    end
    always @(posedge clk) begin
        counter <= counter + 1;
        if (counter == 1) begin
            counter <= 0;
            clk_div <= ~clk_div;
        end
    end

    // VGA Ê±ÖÓ£º100 MHz -> 25 MHz
    reg vga_clk;
    reg [1:0] vga_counter;
    initial begin
        vga_counter = 0;
        vga_clk = 0;
    end
    always @(posedge clk) begin
        vga_counter <= vga_counter + 1;
        if (vga_counter == 2) begin
            vga_counter <= 0;
            vga_clk <= ~vga_clk;
        end
    end

    // Á÷Ë®Ïß¼Ä´æÆ÷ÐÅºÅ
    wire [31:0] if_id_instruction, if_id_pc;
    wire [31:0] id_ex_rdata1, id_ex_rdata2, id_ex_imm32, id_ex_pc;
    wire [2:0] id_ex_funct3;
    wire [6:0] id_ex_funct7;
    wire [4:0] id_ex_rd, id_ex_rs1, id_ex_rs2;
    wire [1:0] id_ex_ecall;
    wire id_ex_regWrite, id_ex_ALUSrc, id_ex_branch, id_ex_jump, id_ex_memRead, id_ex_memWrite, id_ex_memToReg;
    wire [1:0] id_ex_ALUOp;
    wire [31:0] ex_mem_ALUResult, ex_mem_rdata2, ex_mem_imm32;
    wire ex_mem_zero, ex_mem_regWrite, ex_mem_branch, ex_mem_jump, ex_mem_memRead, ex_mem_memWrite, ex_mem_memToReg;
    wire [4:0] ex_mem_rd;
    wire [31:0] mem_wb_readData, mem_wb_ALUResult;
    wire mem_wb_regWrite, mem_wb_memToReg;
    wire [4:0] mem_wb_rd;

    // IF ½×¶Î
    wire [31:0] instruction, pc;
    wire [31:0] test_scenario;
    IFetch ifetch (
        .clk(clk_div),
        .reset(reset),
        .debugMode(debugMode),
        .step(step),
        .branch(ex_mem_branch && ex_mem_zero),
        .jump(ex_mem_jump),
        .zero(ex_mem_zero),
        .imm32(ex_mem_imm32),
        .jalr_target(ex_mem_ALUResult),
        .test_scenario(test_scenario),
        .instruction(instruction),
        .pc(pc)
    );
    wire flush = (ex_mem_branch && ex_mem_zero) || ex_mem_jump;
    PipelineReg #(.WIDTH(32)) if_id_inst_reg (.clk(clk_div), .reset(reset), .flush(flush), .in(instruction), .out(if_id_instruction));
    PipelineReg #(.WIDTH(32)) if_id_pc_reg (.clk(clk_div), .reset(reset), .flush(flush), .in(pc), .out(if_id_pc));

    // ID ½×¶Î
    wire [31:0] rdata1, rdata2, imm32;
    wire [2:0] funct3;
    wire [6:0] funct7;
    wire [4:0] rd, rs1, rs2;
    wire [1:0] ecall;
    wire regWrite, ALUSrc, branch, jump, memRead, memWrite, memToReg;
    wire [1:0] ALUOp;
    wire [31:0] writeData;
    Decoder decoder (
        .clk(clk_div),
        .reset(reset),
        .regWrite(mem_wb_regWrite),
        .instruction(if_id_instruction),
        .writeAddress(mem_wb_rd),
        .writeData(writeData),
        .pc(if_id_pc),
        .rdata1(rdata1),
        .rdata2(rdata2),
        .imm32(imm32),
        .funct3(funct3),
        .funct7(funct7),
        .rd(rd),
        .ecall(ecall)
    );
    assign rs1 = if_id_instruction[19:15];
    assign rs2 = if_id_instruction[24:20];
    Controller controller (
        .opcode(if_id_instruction[6:0]),
        .ecall(ecall),
        .regWrite(regWrite),
        .ALUSrc(ALUSrc),
        .ALUOp(ALUOp),
        .branch(branch),
        .jump(jump),
        .memRead(memRead),
        .memWrite(memWrite),
        .memToReg(memToReg)
    );
    PipelineReg #(.WIDTH(32)) id_ex_r1_reg (.clk(clk_div), .reset(reset), .flush(flush), .in(rdata1), .out(id_ex_rdata1));
    PipelineReg #(.WIDTH(32)) id_ex_r2_reg (.clk(clk_div), .reset(reset), .flush(flush), .in(rdata2), .out(id_ex_rdata2));
    PipelineReg #(.WIDTH(32)) id_ex_imm_reg (.clk(clk_div), .reset(reset), .flush(flush), .in(imm32), .out(id_ex_imm32));
    PipelineReg #(.WIDTH(32)) id_ex_pc_reg_inst (.clk(clk_div), .reset(reset), .flush(flush), .in(if_id_pc), .out(id_ex_pc));
    PipelineReg #(.WIDTH(3)) id_ex_f3_reg (.clk(clk_div), .reset(reset), .flush(flush), .in(funct3), .out(id_ex_funct3));
    PipelineReg #(.WIDTH(7)) id_ex_f7_reg (.clk(clk_div), .reset(reset), .flush(flush), .in(funct7), .out(id_ex_funct7));
    PipelineReg #(.WIDTH(5)) id_ex_rd_reg (.clk(clk_div), .reset(reset), .flush(flush), .in(rd), .out(id_ex_rd));
    PipelineReg #(.WIDTH(5)) id_ex_rs1_reg (.clk(clk_div), .reset(reset), .flush(flush), .in(rs1), .out(id_ex_rs1));
    PipelineReg #(.WIDTH(5)) id_ex_rs2_reg (.clk(clk_div), .reset(reset), .flush(flush), .in(rs2), .out(id_ex_rs2));
    PipelineReg #(.WIDTH(2)) id_ex_ec_reg (.clk(clk_div), .reset(reset), .flush(flush), .in(ecall), .out(id_ex_ecall));
    PipelineReg #(.WIDTH(1)) id_ex_rw_reg (.clk(clk_div), .reset(reset), .flush(flush), .in(regWrite), .out(id_ex_regWrite));
    PipelineReg #(.WIDTH(1)) id_ex_as_reg (.clk(clk_div), .reset(reset), .flush(flush), .in(ALUSrc), .out(id_ex_ALUSrc));
    PipelineReg #(.WIDTH(1)) id_ex_br_reg (.clk(clk_div), .reset(reset), .flush(flush), .in(branch), .out(id_ex_branch));
    PipelineReg #(.WIDTH(1)) id_ex_jp_reg (.clk(clk_div), .reset(reset), .flush(flush), .in(jump), .out(id_ex_jump));
    PipelineReg #(.WIDTH(1)) id_ex_mr_reg (.clk(clk_div), .reset(reset), .flush(flush), .in(memRead), .out(id_ex_memRead));
    PipelineReg #(.WIDTH(1)) id_ex_mw_reg (.clk(clk_div), .reset(reset), .flush(flush), .in(memWrite), .out(id_ex_memWrite));
    PipelineReg #(.WIDTH(1)) id_ex_mt_reg (.clk(clk_div), .reset(reset), .flush(flush), .in(memToReg), .out(id_ex_memToReg));
    PipelineReg #(.WIDTH(2)) id_ex_ao_reg (.clk(clk_div), .reset(reset), .flush(flush), .in(ALUOp), .out(id_ex_ALUOp));

    // EX ½×¶Î
    wire [31:0] ALUResult;
    wire zero;
    wire [1:0] forwardA, forwardB;
    wire [31:0] forwarded_rdata1, forwarded_rdata2;
    ForwardingUnit forwarding (
        .id_ex_rs1(id_ex_rs1),
        .id_ex_rs2(id_ex_rs2),
        .ex_mem_rd(ex_mem_rd),
        .ex_mem_regWrite(ex_mem_regWrite),
        .mem_wb_rd(mem_wb_rd),
        .mem_wb_regWrite(mem_wb_regWrite),
        .forwardA(forwardA),
        .forwardB(forwardB)
    );
    assign forwarded_rdata1 = (forwardA == 2'b10) ? ex_mem_ALUResult :
                              (forwardA == 2'b01) ? writeData : id_ex_rdata1;
    assign forwarded_rdata2 = (forwardB == 2'b10) ? ex_mem_ALUResult :
                              (forwardB == 2'b01) ? writeData : id_ex_rdata2;
    Execute execute (
        .ReadData1(forwarded_rdata1),
        .ReadData2(forwarded_rdata2),
        .imm32(id_ex_imm32),
        .ALUSrc(id_ex_ALUSrc),
        .ALUOp(id_ex_ALUOp),
        .funct3(id_ex_funct3),
        .funct7(id_ex_funct7),
        .ecall(id_ex_ecall),
        .ALUResult(ALUResult),
        .zero(zero)
    );
    PipelineReg #(.WIDTH(32)) ex_mem_alu_reg (.clk(clk_div), .reset(reset), .flush(1'b0), .in(ALUResult), .out(ex_mem_ALUResult));
    PipelineReg #(.WIDTH(32)) ex_mem_r2_reg (.clk(clk_div), .reset(reset), .flush(1'b0), .in(forwarded_rdata2), .out(ex_mem_rdata2));
    PipelineReg #(.WIDTH(32)) ex_mem_imm_reg (.clk(clk_div), .reset(reset), .flush(1'b0), .in(id_ex_imm32), .out(ex_mem_imm32));
    PipelineReg #(.WIDTH(1)) ex_mem_z_reg (.clk(clk_div), .reset(reset), .flush(1'b0), .in(zero), .out(ex_mem_zero));
    PipelineReg #(.WIDTH(1)) ex_mem_rw_reg (.clk(clk_div), .reset(reset), .flush(1'b0), .in(id_ex_regWrite), .out(ex_mem_regWrite));
    PipelineReg #(.WIDTH(1)) ex_mem_br_reg (.clk(clk_div), .reset(reset), .flush(1'b0), .in(id_ex_branch), .out(ex_mem_branch));
    PipelineReg #(.WIDTH(1)) ex_mem_jp_reg (.clk(clk_div), .reset(reset), .flush(1'b0), .in(id_ex_jump), .out(ex_mem_jump));
    PipelineReg #(.WIDTH(1)) ex_mem_mr_reg (.clk(clk_div), .reset(reset), .flush(1'b0), .in(id_ex_memRead), .out(ex_mem_memRead));
    PipelineReg #(.WIDTH(1)) ex_mem_mw_reg (.clk(clk_div), .reset(reset), .flush(1'b0), .in(id_ex_memWrite), .out(ex_mem_memWrite));
    PipelineReg #(.WIDTH(1)) ex_mem_mt_reg (.clk(clk_div), .reset(reset), .flush(1'b0), .in(id_ex_memToReg), .out(ex_mem_memToReg));
    PipelineReg #(.WIDTH(5)) ex_mem_rd_reg (.clk(clk_div), .reset(reset), .flush(1'b0), .in(id_ex_rd), .out(ex_mem_rd));

    // MEM ½×¶Î
    wire [31:0] memData, ioData;
    wire isDMem = (ex_mem_ALUResult < 32'h00001000);
    wire isIO = (ex_mem_ALUResult >= 32'hFFFF0000 && ex_mem_ALUResult < 32'hFFFF1000);
    wire isVGA = (ex_mem_ALUResult >= 32'hFFFF1000);
    wire memReadDMem = ex_mem_memRead && isDMem;
    wire memWriteDMem = ex_mem_memWrite && isDMem;
    wire memReadIO = ex_mem_memRead && isIO;
    wire memWriteIO = ex_mem_memWrite && isIO;
    wire memWriteVGA = ex_mem_memWrite && isVGA;

    DMem dmem (
        .clk(clk_div),
        .reset(reset),
        .funct3(id_ex_funct3),
        .memRead(memReadDMem),
        .memWrite(memWriteDMem),
        .address(ex_mem_ALUResult),
        .writeData(ex_mem_rdata2),
        .readData(memData)
    );

    IOModule iomodule (
        .clk(clk_div),
        .reset(reset),
        .memRead(memReadIO),
        .memWrite(memWriteIO || (id_ex_ecall == 2'b10)),
        .address(ex_mem_ALUResult),
        .writeData(id_ex_ecall == 2'b10 ? forwarded_rdata1 : ex_mem_rdata2),
        .readData(ioData),
        .dipSwitch(dipSwitch),
        .button(button),
        .led(led),
        .seg(seg),
        .an(an)
    );

    VGAModule vgamodule (
        .clk(vga_clk),
        .reset(reset),
        .address(ex_mem_ALUResult),
        .writeData(ex_mem_rdata2),
        .memWrite(memWriteVGA),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b),
        .vga_hs(vga_hs),
        .vga_vs(vga_vs)
    );

    wire [31:0] readData = isIO ? ioData : (isDMem ? memData : 32'd0);
    PipelineReg #(.WIDTH(32)) mem_wb_rd_reg (.clk(clk_div), .reset(reset), .flush(1'b0), .in(readData), .out(mem_wb_readData));
    PipelineReg #(.WIDTH(32)) mem_wb_alu_reg (.clk(clk_div), .reset(reset), .flush(1'b0), .in(ex_mem_ALUResult), .out(mem_wb_ALUResult));
    PipelineReg #(.WIDTH(1)) mem_wb_rw_reg (.clk(clk_div), .reset(reset), .flush(1'b0), .in(ex_mem_regWrite), .out(mem_wb_regWrite));
    PipelineReg #(.WIDTH(1)) mem_wb_mt_reg (.clk(clk_div), .reset(reset), .flush(1'b0), .in(ex_mem_memToReg), .out(mem_wb_memToReg));
    PipelineReg #(.WIDTH(5)) mem_wb_rd_reg_inst (.clk(clk_div), .reset(reset), .flush(1'b0), .in(ex_mem_rd), .out(mem_wb_rd));

    // WB ½×¶Î
    assign writeData = (mem_wb_memToReg == 1) ? mem_wb_readData : mem_wb_ALUResult;

    // UART Ä£¿é
    UARTModule uartmodule (
        .clk(clk_div),
        .reset(reset),
        .uart_rx(uart_rx),
        .baud_select(baud_select),
        .test_scenario(test_scenario)
    );

endmodule