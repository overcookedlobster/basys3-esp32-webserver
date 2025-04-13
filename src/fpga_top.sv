`timescale 1ns / 1ps

module fpga_top(
    input logic clk,            // default 100MHz
    input logic [4:0] btn,      // 5 buttons (center, up, down, left, right)
    output logic uart_tx        // UART TX to ESP32
);
    localparam TIMEOUT_VALUE = 10;  // Timeout value in clock cycles

    // Internal signals
    logic baudrate_tick;
    logic baudrate_tick_16x;  // Not used for TX

    // Baud rate generator instantiation
    baudrate_gen #(
        .CLK_FREQ_HZ(100_000_000),  // 100MHz clock
        .BAUD_RATE(115200),         // 115200 baud
        .OVERSAMPLING(16)           // Standard oversampling
    ) baudgen_inst (
        .clk(clk),
        .rst_n(1'b1),               // No reset
        .enable(1'b1),              // Always enabled
        .tick(baudrate_tick),
        .tick_16x(baudrate_tick_16x)
    );

    // Simple input register to avoid metastability
    logic [4:0] btn_meta, btn_sync;

    always_ff @(posedge clk) begin
        btn_meta <= btn;
        btn_sync <= btn_meta;
    end

    // Define button state
    logic [4:0] btn_state;
    logic [4:0] btn_prev;
    logic btn_pressed;

    // Detect button press
    always_ff @(posedge clk) begin
        btn_prev <= btn_sync;
        btn_state <= btn_sync;

        // Detect if any button was pressed (transition from 0 to 1)
        btn_pressed <= |(btn_sync & ~btn_prev);
    end

    // State machine states
    typedef enum logic [1:0] {
        ST_IDLE,
        ST_SEND_BUTTON
    } tx_state_t;

    // Communication control signals
    tx_state_t tx_state;
    logic tx_start;
    logic tx_busy;
    logic tx_done;
    logic [7:0] tx_data;
    logic [26:0] send_counter;

    // Simplified state machine - only sends button data
    always_ff @(posedge clk) begin
        // Default values
        tx_start <= 1'b0;

        // Increment send counter
        if (send_counter < 100_000_000)  // About 1 second at 100MHz
            send_counter <= send_counter + 1;
        else
            send_counter <= 0;

        // State machine
        case (tx_state)
            ST_IDLE: begin
                // Send on button press or periodically
                if ((btn_pressed || send_counter == 0) && !tx_busy) begin
                    tx_data <= {3'b000, btn_state};
                    tx_start <= 1'b1;
                    tx_state <= ST_SEND_BUTTON;
                    $display("[FPGA] Sending button state: %b", btn_state);
                end
            end

            ST_SEND_BUTTON: begin
                // De-assert tx_start after one clock
                if (tx_start) begin
                    tx_start <= 1'b0;
                end

                // If tx_busy has gone high and then low again, we can consider the transmission done
                if (tx_done || (!tx_busy && send_counter > TIMEOUT_VALUE)) begin
                    tx_state <= ST_IDLE;
                    $display("[FPGA] Transmission complete");
                end
            end

            default: tx_state <= ST_IDLE;
        endcase
    end

    // UART TX instantiation
    uart_tx #(
        .DATA_BITS(8),
        .PARITY_EN(1'b0),       // No parity for simplicity
        .PARITY_TYPE(1'b0),     // Even parity (not used)
        .STOP_BITS(1)           // 1 stop bit
    ) uart_tx_inst (
        .clk(clk),
        .rst_n(1'b1),           // No reset
        .tick(baudrate_tick),   // Connect to baud rate generator
        .tx_start(tx_start),
        .cts(1'b1),             // No flow control, always clear to send
        .tx_data(tx_data),
        .tx_out(uart_tx),
        .tx_busy(tx_busy),
        .tx_done(tx_done)
    );

    // Initialize state
    initial begin
        tx_state = ST_IDLE;
        tx_start = 1'b0;
        tx_data = 8'h00;
        send_counter = 0;
        btn_state = 5'b00000;
        btn_prev = 5'b00000;
        btn_pressed = 1'b0;
    end

endmodule
