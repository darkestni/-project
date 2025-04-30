
`timescale 1ns / 1ps

module UARTModule (
    input clk,
    input uart_rx,
    input [1:0] baud_select,
    output reg [31:0] test_scenario
);

    localparam BAUD_9600 = 5208;
    localparam BAUD_19200 = 2604;
    localparam BAUD_38400 = 1302;
    reg [12:0] baud_div;
    always @(*) begin
        case (baud_select)
            2'b00: baud_div = BAUD_9600;
            2'b01: baud_div = BAUD_19200;
            2'b10: baud_div = BAUD_38400;
            default: baud_div = BAUD_9600;
        endcase
    end

    reg [7:0] rx_data;
    reg [12:0] clk_count;
    reg [3:0] bit_count;
    reg rx_state;

    always @(posedge clk) begin
        case (rx_state)
            0: begin
                if (!uart_rx) begin
                    rx_state <= 1;
                    clk_count <= 0;
                    bit_count <= 0;
                end
            end
            1: begin
                if (clk_count == baud_div) begin
                    clk_count <= 0;
                    if (bit_count < 8) begin
                        rx_data[bit_count] <= uart_rx;
                        bit_count <= bit_count + 1;
                    end else begin
                        test_scenario <= rx_data;
                        rx_state <= 0;
                    end
                end else begin
                    clk_count <= clk_count + 1;
                end
            end
        endcase
    end

endmodule