`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/21 15:15:03
// Design Name: 
// Module Name: CPU
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module CPU(
input  clk,
input  rst,
input  [15:0] switch_in,    // ????????IO??
output reg [15:0] led_out,       // LED ?????IO??
output [7:0] seg_data,      // ????????
output [7:0] seg_data2,
output [7:0] seg_cs
//input start_pg,
//input rx,
//output tx

);
wire clk_out1;
wire clk_out2;
cpuclk u_cpu_clk(
            .clk_in1(clk),
            .clk_out1(clk_out1),
            .clk_out2(clk_out2)
        );

wire [31:0] inst;
wire [31:0] imm32;
wire [4:0]  rs1;
wire [4:0]  rs2;
wire [4:0]  rd;
wire [6:0]  opcode;
wire [2:0]  funct3;
wire [6:0]  funct7;
wire        RegWrite;      // ?????д???
wire        ALUSrc;        // ALU????
wire [1:0]  ALUOp;         // ALU??????
wire        branch;        // ??????
wire        jump;
wire        jalr;
wire        zero;          // ALU????
wire        MemRead;       // ????
wire        MemWrite;      // ???д
wire        ioRead;        // IO??
wire       IOWrite_led;
wire        IOWrite_seg;
wire        MemorIO_to_Reg;  // д?????????
wire [31:0] ALU_result;    // ALU??????
wire [31:0] read_data1;    // ???????????1
wire [31:0] read_data2;    // ???????????2
wire [31:0] mem_io_data;   // ????IO???????
wire [31:0] mem_out;       // ?????????
wire branch_taken;
wire [31:0] next_pc;
wire is_jal_jalr;     // 标识jal/jalr指令
wire [31:0] m_wdata;
wire led_ctrl,sw_ctrl,number_ctrl;
reg [31:0] registers[0:31];  
reg [31:0] seg_out;
//// UART Programmer Pinouts
////wire upg_clk, upg_clk_o;
//wire upg_wen_o; //Uart write out enable
//wire upg_done_o; //Uart rx data have done
////data to which memory unit of program_rom/dmemory32
//wire [14:0] upg_adr_o;
////data to program_rom or dmemory32
//wire [31:0] upg_dat_o;
//wire spg_bufg;
//BUFG U1(.I(start_pg), .O(spg_bufg)); // de-twitter
//// Generate UART Programmer reset signal
//reg upg_rst;
//always @ (posedge fpga_clk) begin
//    if (fpga_rst) upg_rst <= 1;
//    if (spg_bufg) upg_rst <= 0;
//end
////used for other modules which don't relate to UART
//wire rst;
//assign rst = fpga_rst | !upg_rst;
IFetch u_IF (
    .clk(clk_out1),
    .branch(branch),
    .zero(branch_taken),
    .jump(jump),
    .jalr(jalr),
    .rst(rst),
    .imm32(imm32),
    .reg_data(read_data1),
    .inst(inst),
    .next_pc(next_pc)
//    .upg_clk_i(clk_out2),
//    .upg_wen_i(upg_wen_i),
//    .upg_rst_i(upg_rst_i),
//    .upg_adr_i(upg_adr_i),
//    .upg_dat_i(upg_dat_i),
//    .upg_done_i(upg_done_i)
);

Decoder u_Decoder (
    .instruction(inst),
    .imm32(imm32),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .opcode(opcode),
    .funct3(funct3),
    .funct7(funct7)
);

Controller u_Controller (
    .opcode(opcode),
   // .ecall(2'b00),
   .read_data1(read_data1),
           .read_data2(read_data2),
           .funct3(funct3),
    .ALU_result(ALU_result),
    .RegWrite(RegWrite),
    .ALUSrc(ALUSrc),
    .ALUOp(ALUOp),
    .branch(branch),
    .jump(jump),
    .MemorIO_to_Reg(MemorIO_to_Reg),
    .MemRead(MemRead),
    .MemWrite(MemWrite),
    .IORead(ioRead),
  .IOWrite_led(IOWrite_led),
    .IOWrite_seg(IOWrite_seg),
    .jalr(jalr),
     .branch_taken(branch_taken),
    .is_jal_jalr(is_jal_jalr)
);

//??????????д??? 
wire [31:0] reg_write_data = 
    is_jal_jalr ? next_pc :  // 优先返回地址
    (MemorIO_to_Reg ? mem_io_data : ALU_result);
integer i;
always @(posedge clk_out1) begin
    if (!rst) begin
        // ??λ?????????м?????0??????x0??
        for ( i = 0; i < 32; i = i + 1) begin
            registers[i] <= 32'b0;
        end
    end else if (RegWrite && (rd != 0)) begin
        registers[rd] <= reg_write_data;
    end
end

assign read_data1 = (rs1 != 0) ? registers[rs1] : 32'b0;  
assign read_data2 = (rs2 != 0) ? registers[rs2] : 32'b0;


ALU u_ALU (
    .read_data1(read_data1),
    .read_data2(read_data2),
    .imm32(imm32),
    .ALUOp(ALUOp),
    .funct3(funct3),
    .funct7(funct7),
    .ALUSrc(ALUSrc),
    .ALU_result(ALU_result),
    .zero(zero)
);

DMem u_DMem (
    .clk(clk_out1),
    .MemRead(MemRead),
    .MemWrite(MemWrite),
    .mem_width(funct3[1:0]),
    .sign_ext(~funct3[2]),
    .addr(ALU_result),       
    .din(m_wdata), // ???MemOrIO???????д????
    .dout(mem_out)
//    .upg_clk_i(clk_out2),
//    .upg_wen_i(upg_wen_i),
//    .upg_rst_i(upg_rst_i),
//    .upg_adr_i(upg_adr_i),
//    .upg_dat_i(upg_dat_i),
//    .upg_done_i(upg_done_i)
);

MemOrIO u_MemOrIO (
    .mRead(MemRead),
    .mWrite(MemWrite),
    .ioRead(ioRead),
    .ioWrite(1'b0),
    .addr_in(ALU_result),
    .m_rdata(mem_out),
    .io_rdata(switch_in[12:0]),
    .r_wdata(mem_io_data),
    .r_rdata(read_data2),
    .m_wdata(m_wdata),
    .LEDCtrl(led_ctrl),
    .SwitchCtrl(sw_ctrl),
    .NumberCtrl(number_ctrl)
);

always @(negedge clk_out1) begin
    if (IOWrite_led ) begin
        led_out = read_data2[15:0]; 
    end
end

always @(negedge clk_out1) begin
    if (IOWrite_seg ) begin
        seg_out = read_data2[31:0]; 
    end
end

    
show_number show_inst (
    .clk(clk),
    .rst(rst),
    .data( seg_out[31:0] ),
    .seg_data(seg_data),
    .seg_data2(seg_data2),
    .seg_cs(seg_cs)
            );
// uart_bmpg_0 uart_prog (
//                   .upg_clk_i(clk_out2),
//                   .upg_rst_i(upg_rst),
//                   .upg_rx_i(rx),
//                   .upg_tx_o(tx),
//                   .upg_adr_o(upg_adr_o),
//                   .upg_dat_o(upg_dat_o),
//                   .upg_wen_o(upg_wen_o),
//                   .upg_done_o(upg_done_o)
//               );

endmodule