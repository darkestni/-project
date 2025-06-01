module DMem(
    input clk,
    input MemRead, MemWrite,
    input [1:0]  mem_width,    // 00:byte, 01:halfword, 10:word
    input sign_ext, // 1:sign  0:0
    input [31:0] addr,
    input [31:0] din, 
    output reg [31:0] dout,
    
    input upg_clk_i,         // UART编程时钟
    input upg_wen_i,       // UART写使能
    input upg_rst_i,
    input [14:0] upg_adr_i, // UART编程地址
    input [31:0] upg_dat_i,  // UART编程数据
    input upg_done_i
);
    wire [3:0]  byte_sel;
    wire [31:0] ram_dout; 
    wire kickOff = upg_rst_i | (~upg_rst_i & upg_done_i);
    RAM udram(
        .clka(kickOff? (!clk) :upg_clk_i),
        .wea(kickOff ? (MemWrite ? byte_sel : 4'b0) : (upg_wen_i ? 4'b1111 : 4'b0)), 
        .addra(kickOff? addr[15:2]:upg_adr_i),
        .dina(kickOff? din : upg_dat_i), 
        .douta(ram_dout)
     );
    
    assign byte_sel = 
        (mem_width == 2'b10) ? 4'b1111 :
        (mem_width == 2'b01) ? 
            (addr[1] ? 4'b1100 : 4'b0011) : 
        (mem_width == 2'b00) ? 
            (4'b0001 << addr[1:0]) : 
        4'b0000;
        
    // 组合逻辑块
    always @(*) begin
        if (MemRead) begin
            case (mem_width)
                2'b00: begin // 字节加载（lb/lbu）
                    case (addr[1:0])
                        2'b00: dout = sign_ext ? {{24{ram_dout[7]}},  ram_dout[7:0]}   : {24'b0, ram_dout[7:0]};
                        2'b01: dout = sign_ext ? {{24{ram_dout[15]}}, ram_dout[15:8]}  : {24'b0, ram_dout[15:8]};
                        2'b10: dout = sign_ext ? {{24{ram_dout[23]}}, ram_dout[23:16]} : {24'b0, ram_dout[23:16]};
                        2'b11: dout = sign_ext ? {{24{ram_dout[31]}}, ram_dout[31:24]} : {24'b0, ram_dout[31:24]};
                    endcase
                end
                2'b01: begin // 半字加载（lh/lhu）
                    case (addr[1])
                        1'b0: dout = sign_ext ? {{16{ram_dout[15]}}, ram_dout[15:0]}  : {16'b0, ram_dout[15:0]};
                        1'b1: dout = sign_ext ? {{16{ram_dout[31]}}, ram_dout[31:16]} : {16'b0, ram_dout[31:16]};
                    endcase
                end
                2'b10: dout = ram_dout; // 字加载（lw）
                default: dout = 32'b0;
            endcase
        end else begin
            dout = 32'b0; // MemRead无效时输出0，避免锁存器
        end
    end
endmodule