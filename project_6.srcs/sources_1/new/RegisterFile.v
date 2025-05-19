module RegisterFile (
    input clk,
    input reset,
    input [4:0] read_addr1,
    input [4:0] read_addr2,
    input reg_write_enable_wb, 
    input [4:0] write_addr_wb, 
    input [31:0] write_data_wb, 
    output [31:0] read_data1_id,

    output [31:0] x1,
    output [31:0] x2,
    output [31:0] x3,
    output [31:0] x4,


    output [31:0] read_data2_id
);
    reg [31:0] registers [31:0];
    integer i;

    always @(negedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'd0;
            end
        end else if (reg_write_enable_wb && write_addr_wb != 5'd0) begin
            registers[write_addr_wb] <= write_data_wb;
        end
    end

    assign read_data1_id = (read_addr1 == 5'd0) ? 32'd0 : registers[read_addr1];
    assign read_data2_id = (read_addr2 == 5'd0) ? 32'd0 : registers[read_addr2];

    
    assign x1 = registers[1];
    assign x2 = registers[2];
    assign x3 = registers[3];
    assign x4 = registers[4];

endmodule