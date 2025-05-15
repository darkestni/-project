`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/06 13:56:33
// Design Name: 
// Module Name: DMem
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


module DMem(
    input clk,
    input MemRead,MemWrite,
    input  [1:0]  mem_width,    // 00:byte, 01:halfword, 10:word
    input sign_ext, // 1:sign  0:0
    input [31:0] addr,
    input [31:0] din, 
    output reg [31:0] dout
);
    wire [3:0]  byte_sel;               // �ֽ�ѡ�����루���ݵ�ַ��2λ�Ͳ���������ɣ�
    wire [31:0] ram_dout; 
    RAM udram(.clka(clk), .wea(MemWrite ? byte_sel : 4'b0), .addra(addr[15:2]), .dina(din), .douta(ram_dout));
    
    assign byte_sel =  //ai���������߼�
        (mem_width == 2'b10) ? 4'b1111 :  // �ֲ�����sw����дȫ��4�ֽ�
        (mem_width == 2'b01) ?            // ���ֲ�����sh����д2�ֽ�
            (addr[1] ? 4'b1100 : 4'b0011) : 
        (mem_width == 2'b00) ?            // �ֽڲ�����sb����д1�ֽ�
            (4'b0001 << addr[1:0]) : 
        4'b0000;
        
    always @(posedge clk) begin
            if (MemRead) begin
                case (mem_width)
                    // �ֽڼ��أ�lb/lbu��
                    2'b00: begin
                        case (addr[1:0])
                            2'b00: dout <= sign_ext ? {{24{ram_dout[7]}},  ram_dout[7:0]}   : {24'b0, ram_dout[7:0]};
                            2'b01: dout <= sign_ext ? {{24{ram_dout[15]}}, ram_dout[15:8]}  : {24'b0, ram_dout[15:8]};
                            2'b10: dout <= sign_ext ? {{24{ram_dout[23]}}, ram_dout[23:16]} : {24'b0, ram_dout[23:16]};
                            2'b11: dout <= sign_ext ? {{24{ram_dout[31]}}, ram_dout[31:24]} : {24'b0, ram_dout[31:24]};
                        endcase
                    end
                    // ���ּ��أ�lh/lhu��
                    2'b01: begin
                        case (addr[1])
                            1'b0: dout <= sign_ext ? {{16{ram_dout[15]}}, ram_dout[15:0]}  : {16'b0, ram_dout[15:0]};
                            1'b1: dout <= sign_ext ? {{16{ram_dout[31]}}, ram_dout[31:16]} : {16'b0, ram_dout[31:16]};
                        endcase
                    end
                    // �ּ��أ�lw��
                    2'b10: dout <= ram_dout;  // ֱ�����
                    default: dout <= 32'b0;
                endcase
            end
        end
endmodule
