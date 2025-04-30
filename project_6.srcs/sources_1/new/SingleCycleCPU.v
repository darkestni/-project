`timescale 1ns / 1ps

module SingleCycleCPU (
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

    // IF ½×¶Î
    wire [31:0] instruction, pc;
    wire [31:0] test_scenario;
    
    
    wire   branch,  jump,  zero;
    
    wire [31:0]  imm32,ALUResult;
    
    IFetch ifetch (
        .clk(clk),
        .reset(reset),
        .debugMode(debugMode),
        .step(step),
        .branch(branch && zero),
        .jump(jump),
        .zero(zero),
        .imm32(imm32),
        .jalr_target(ALUResult),
        .test_scenario(test_scenario),
        .instruction(instruction),
        .pc(pc)
    );

    // ID ½×¶Î
    wire [31:0] rdata1, rdata2, imm32;
    wire [2:0] funct3;
    wire [6:0] funct7;
    wire [4:0] rd, rs1, rs2;
    wire [1:0] ecall;
    wire RegWrite, ALUSrc, branch, jump, MemorIOtoReg, MemRead, MemWrite, IORead, IOWrite;
    wire [1:0] ALUOp;
    wire [31:0] writeData;
    Decoder decoder (
        .clk(clk),
        .reset(reset),
        .regWrite(RegWrite),
        .instruction(instruction),
        .writeAddress(rd),
        .writeData(writeData),
        .pc(pc),
        .rdata1(rdata1),
        .rdata2(rdata2),
        .imm32(imm32),
        .funct3(funct3),
        .funct7(funct7),
        .rd(rd),
        .ecall(ecall)
    );
    assign rs1 = instruction[19:15];
    assign rs2 = instruction[24:20];
    Controller controller (
        .opcode(instruction[6:0]),
        .ecall(ecall),
        .Alu_resultHigh(ALUResult[31:10]),
        .RegWrite(RegWrite),
        .ALUSrc(ALUSrc),
        .ALUOp(ALUOp),
        .branch(branch),
        .jump(jump),
        .MemorIOtoReg(MemorIOtoReg),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .IORead(IORead),
        .IOWrite(IOWrite)
    );

    // EX ½×¶Î
    wire [31:0] ALUResult;
    wire zero;
    Execute execute (
        .ReadData1(rdata1),
        .ReadData2(rdata2),
        .imm32(imm32),
        .ALUSrc(ALUSrc),
        .ALUOp(ALUOp),
        .funct3(funct3),
        .funct7(funct7),
        .ecall(ecall),
        .ALUResult(ALUResult),
        .zero(zero)
    );

    // MEM ½×¶Î
    wire [31:0] memData, ioData;
    wire [31:0] addr_out, write_data, r_wdata;
    wire LEDCtrl, SwitchCtrl;
    MemOrIO memorio (
        .mRead(MemRead),
        .mWrite(MemWrite),
        .ioRead(IORead),
        .ioWrite(IOWrite),
        .addr_in(ALUResult),
        .addr_out(addr_out),
        .m_rdata(memData),
        .io_rdata(ioData[15:0]),
        .r_wdata(r_wdata),
        .r_rdata(rdata2),
        .write_data(write_data),
        .LEDCtrl(LEDCtrl),
        .SwitchCtrl(SwitchCtrl)
    );

    // Êý¾Ý´æ´¢Æ÷
    DMem dmem (
        .clk(clk),
        .reset(reset),
        .funct3(funct3),
        .memRead(MemRead),
        .memWrite(MemWrite),
        .address(addr_out),
        .writeData(write_data),
        .readData(memData)
    );

    // IO Ä£¿é
    IOModule iomodule (
        .clk(clk),
        .reset(reset),
        .memRead(SwitchCtrl),
        .memWrite(LEDCtrl),
        .address(addr_out),
        .writeData(ecall == 2'b10 ? rdata1 : write_data),
        .readData(ioData),
        .dipSwitch(dipSwitch),
        .button(button),
        .led(led),
        .seg(seg),
        .an(an)
    );

    // VGA Ä£¿é
    wire isVGA = (addr_out >= 32'hFFFF1000);
    wire memWriteVGA = MemWrite && isVGA;
    VGAModule vgamodule (
        .clk(vga_clk),
        .reset(reset),
        .address(addr_out),
        .writeData(write_data),
        .memWrite(memWriteVGA),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b),
        .vga_hs(vga_hs),
        .vga_vs(vga_vs)
    );

    // WB ½×¶Î
    assign writeData = MemorIOtoReg ? r_wdata : ALUResult;

    // UART Ä£¿é
    UARTModule uartmodule (
        .clk(clk),
        .reset(reset),
        .uart_rx(uart_rx),
        .baud_select(baud_select),
        .test_scenario(test_scenario)
    );

endmodule