
module DebugClkGenerator (
    input clk,       //system clock
    input reset,          
    input button, 
    output reg dbg_clk   // The simulated clock: rises on press, falls on release
);
    reg prev_stable_button_state;
    wire stable_button_state;
    initial begin
        dbg_clk = 1'b0; 
    end

    debounce debounce_inst (
        .clk(clk),
        .run_stop(1'b1), 
        .key_in(button),  
        .key_out(stable_button_state) 
    );

    // assign stable_button_state = button; // when simulate, no need to debounce

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            prev_stable_button_state <= 1'b0; 
            dbg_clk <= 1'b0;
        end else begin
            prev_stable_button_state <= stable_button_state;

            if (stable_button_state == 1'b1 && prev_stable_button_state == 1'b0) begin
                dbg_clk <= 1'b1; 
            end
            else if (stable_button_state == 1'b0 && prev_stable_button_state == 1'b1) begin
                dbg_clk <= 1'b0; 
            end

        end
    end

endmodule
