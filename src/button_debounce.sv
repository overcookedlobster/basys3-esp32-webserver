module button_debounce(
    input logic clk,      // System clock
    input logic btn_in,   // Raw button input
    output logic btn_out  // Debounced output
);
    // Counter for debounce timing
    logic [19:0] counter;
    logic btn_sync_0, btn_sync_1;

    // Synchronize the button input to prevent metastability
    always_ff @(posedge clk) begin
        btn_sync_0 <= btn_in;
        btn_sync_1 <= btn_sync_0;
    end

    // Debounce logic
    always_ff @(posedge clk) begin
        if (btn_sync_1 != btn_out && counter == 0) begin
            btn_out <= btn_sync_1;
            counter <= 20'd1_000_000;  // 10ms at 100MHz
        end else if (counter > 0) begin
            counter <= counter - 1;
        end
    end

    // Optional: Initialize values (for simulation)
    initial begin
        counter = 20'd0;
        btn_out = 1'b0;
        btn_sync_0 = 1'b0;
        btn_sync_1 = 1'b0;
    end
endmodule
