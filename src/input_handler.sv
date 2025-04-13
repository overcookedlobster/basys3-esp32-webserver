module input_handler(
    input logic clk,            // System clock
    input logic [4:0] btn,      // 5 buttons
    output logic [4:0] debounced_btn  // Debounced button outputs
);
    // Instantiate button debouncers
    generate
        genvar i;
        for (i = 0; i < 5; i = i + 1) begin : btn_debouncers
            button_debounce debounce_inst (
                .clk(clk),
                .btn_in(btn[i]),
                .btn_out(debounced_btn[i])
            );
        end
    endgenerate
endmodule
