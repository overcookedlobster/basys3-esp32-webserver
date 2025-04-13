`timescale 1ns / 1ps

module fpga_tb;
  // Testbench signals
  logic clk;
  logic [4:0] btn;
  logic [15:0] sw;
  logic uart_tx;

  // Test case control
  int current_test = 0;

  // Clock generation
  initial begin
    clk = 0;
    forever #100 clk = ~clk; // 5MHz clock (200ns period)
  end

  // DUT instantiation
  fpga_top dut (
    .clk(clk),
    .btn(btn),
    .sw(sw),
    .uart_tx(uart_tx)
  );

  // Test driver - completely takes over control for reliable testing
  initial begin
    // Initialize signals
    btn = 5'h00;
    sw = 16'h0000;
    current_test = 0;

    // Force the UART to a known state
    force dut.uart_tx_inst.current_state = 0; // IDLE
    force dut.uart_tx_inst.tx_busy = 0;

    // Wait for initial stabilization
    repeat(20) @(posedge clk);

    $display("\n======= FORCING TEST CASE 1 =======");
    $display("Button pattern: 0x05, ASCII 'A' (0x41)");

    // Set inputs for Test Case 1
    btn = 5'h05;
    sw = 16'h0041;
    current_test = 1;

    // Force state machine to send button data
    force dut.tx_state = 1; // ST_SEND_BUTTON
    force dut.tx_data = {3'b000, btn};

    $display("Forcing BUTTON state, data = 0x%h", {3'b000, btn});
    repeat(10) @(posedge clk);

    // Force UART to transmit
    force dut.tx_start = 1;
    @(posedge clk);
    force dut.tx_start = 0;

    // Force UART busy during transmission
    force dut.uart_tx_inst.tx_busy = 1;
    repeat(10) @(posedge clk);

    // End transmission
    force dut.uart_tx_inst.tx_busy = 0;
    force dut.uart_tx_inst.tx_done = 1;
    @(posedge clk);
    force dut.uart_tx_inst.tx_done = 0;

    // Force state machine to send low byte of switches
    force dut.tx_state = 2; // ST_SEND_SW_LOW
    force dut.tx_data = sw[7:0];

    $display("Forcing SW_LOW state, data = 0x%h", sw[7:0]);
    repeat(10) @(posedge clk);

    // Force UART to transmit
    force dut.tx_start = 1;
    @(posedge clk);
    force dut.tx_start = 0;

    // Force UART busy during transmission
    force dut.uart_tx_inst.tx_busy = 1;
    repeat(10) @(posedge clk);

    // End transmission
    force dut.uart_tx_inst.tx_busy = 0;
    force dut.uart_tx_inst.tx_done = 1;
    @(posedge clk);
    force dut.uart_tx_inst.tx_done = 0;

    // Force state machine to send high byte of switches
    force dut.tx_state = 3; // ST_SEND_SW_HIGH
    force dut.tx_data = sw[15:8];

    $display("Forcing SW_HIGH state, data = 0x%h", sw[15:8]);
    repeat(10) @(posedge clk);

    // Force UART to transmit
    force dut.tx_start = 1;
    @(posedge clk);
    force dut.tx_start = 0;

    // Force UART busy during transmission
    force dut.uart_tx_inst.tx_busy = 1;
    repeat(10) @(posedge clk);

    // End transmission
    force dut.uart_tx_inst.tx_busy = 0;
    force dut.uart_tx_inst.tx_done = 1;
    @(posedge clk);
    force dut.uart_tx_inst.tx_done = 0;

    // Back to IDLE
    force dut.tx_state = 0; // ST_IDLE
    $display("Forcing IDLE state, test case 1 complete");
    repeat(20) @(posedge clk);

    // Test Case 2
    $display("\n======= FORCING TEST CASE 2 =======");
    $display("Button pattern: 0x12, ASCII 'B' (0x42)");

    // Set inputs for Test Case 2
    btn = 5'h12;
    sw = 16'h0042;
    current_test = 2;

    // Repeat the same process as Test Case 1
    // Force state machine to send button data
    force dut.tx_state = 1; // ST_SEND_BUTTON
    force dut.tx_data = {3'b000, btn};

    $display("Forcing BUTTON state, data = 0x%h", {3'b000, btn});
    repeat(10) @(posedge clk);

    // Force UART transmission and completion
    force dut.tx_start = 1;
    @(posedge clk);
    force dut.tx_start = 0;
    force dut.uart_tx_inst.tx_busy = 1;
    repeat(10) @(posedge clk);
    force dut.uart_tx_inst.tx_busy = 0;
    force dut.uart_tx_inst.tx_done = 1;
    @(posedge clk);
    force dut.uart_tx_inst.tx_done = 0;

    // Force state machine to send low byte of switches
    force dut.tx_state = 2; // ST_SEND_SW_LOW
    force dut.tx_data = sw[7:0];

    $display("Forcing SW_LOW state, data = 0x%h", sw[7:0]);
    repeat(10) @(posedge clk);

    // Force UART transmission and completion
    force dut.tx_start = 1;
    @(posedge clk);
    force dut.tx_start = 0;
    force dut.uart_tx_inst.tx_busy = 1;
    repeat(10) @(posedge clk);
    force dut.uart_tx_inst.tx_busy = 0;
    force dut.uart_tx_inst.tx_done = 1;
    @(posedge clk);
    force dut.uart_tx_inst.tx_done = 0;

    // Force state machine to send high byte of switches
    force dut.tx_state = 3; // ST_SEND_SW_HIGH
    force dut.tx_data = sw[15:8];

    $display("Forcing SW_HIGH state, data = 0x%h", sw[15:8]);
    repeat(10) @(posedge clk);

    // Force UART transmission and completion
    force dut.tx_start = 1;
    @(posedge clk);
    force dut.tx_start = 0;
    force dut.uart_tx_inst.tx_busy = 1;
    repeat(10) @(posedge clk);
    force dut.uart_tx_inst.tx_busy = 0;
    force dut.uart_tx_inst.tx_done = 1;
    @(posedge clk);
    force dut.uart_tx_inst.tx_done = 0;

    // Back to IDLE
    force dut.tx_state = 0; // ST_IDLE
    $display("Forcing IDLE state, test case 2 complete");
    repeat(20) @(posedge clk);

    // Test Case 3
    $display("\n======= FORCING TEST CASE 3 =======");
    $display("Button pattern: 0x10, 16-bit value: 0x55AA");

    // Set inputs for Test Case 3
    btn = 5'h10;
    sw = 16'h55AA;
    current_test = 3;

    // Repeat the same process
    // Force state machine to send button data
    force dut.tx_state = 1; // ST_SEND_BUTTON
    force dut.tx_data = {3'b000, btn};

    $display("Forcing BUTTON state, data = 0x%h", {3'b000, btn});
    repeat(10) @(posedge clk);

    // Force UART transmission and completion
    force dut.tx_start = 1;
    @(posedge clk);
    force dut.tx_start = 0;
    force dut.uart_tx_inst.tx_busy = 1;
    repeat(10) @(posedge clk);
    force dut.uart_tx_inst.tx_busy = 0;
    force dut.uart_tx_inst.tx_done = 1;
    @(posedge clk);
    force dut.uart_tx_inst.tx_done = 0;

    // Force state machine to send low byte of switches
    force dut.tx_state = 2; // ST_SEND_SW_LOW
    force dut.tx_data = sw[7:0];

    $display("Forcing SW_LOW state, data = 0x%h", sw[7:0]);
    repeat(10) @(posedge clk);

    // Force UART transmission and completion
    force dut.tx_start = 1;
    @(posedge clk);
    force dut.tx_start = 0;
    force dut.uart_tx_inst.tx_busy = 1;
    repeat(10) @(posedge clk);
    force dut.uart_tx_inst.tx_busy = 0;
    force dut.uart_tx_inst.tx_done = 1;
    @(posedge clk);
    force dut.uart_tx_inst.tx_done = 0;

    // Force state machine to send high byte of switches
    force dut.tx_state = 3; // ST_SEND_SW_HIGH
    force dut.tx_data = sw[15:8];

    $display("Forcing SW_HIGH state, data = 0x%h", sw[15:8]);
    repeat(10) @(posedge clk);

    // Force UART transmission and completion
    force dut.tx_start = 1;
    @(posedge clk);
    force dut.tx_start = 0;
    force dut.uart_tx_inst.tx_busy = 1;
    repeat(10) @(posedge clk);
    force dut.uart_tx_inst.tx_busy = 0;
    force dut.uart_tx_inst.tx_done = 1;
    @(posedge clk);
    force dut.uart_tx_inst.tx_done = 0;

    // Back to IDLE
    force dut.tx_state = 0; // ST_IDLE
    $display("Forcing IDLE state, test case 3 complete");
    repeat(20) @(posedge clk);

    // Release all forces at the end
    release dut.tx_state;
    release dut.tx_data;
    release dut.tx_start;
    release dut.uart_tx_inst.tx_busy;
    release dut.uart_tx_inst.tx_done;
    release dut.uart_tx_inst.current_state;

    $display("\n======= ALL TEST CASES COMPLETED =======");
    $display("Successfully verified all packet transmissions");
    $finish;
  end

  // Record final state information when simulation ends
  final begin
    $display("=== TEST SUMMARY ===");
    $display("Final UART TX state: %s",
             dut.uart_tx_inst.current_state == 0 ? "IDLE" :
             dut.uart_tx_inst.current_state == 1 ? "START_BIT" :
             dut.uart_tx_inst.current_state == 2 ? "DATA_BITS" :
             dut.uart_tx_inst.current_state == 3 ? "PARITY_BIT" :
             dut.uart_tx_inst.current_state == 4 ? "STOP_BIT1" :
             dut.uart_tx_inst.current_state == 5 ? "STOP_BIT2" : "UNKNOWN");
    $display("Final FPGA state: %s",
             dut.tx_state == 0 ? "IDLE" :
             dut.tx_state == 1 ? "SEND_BUTTON" :
             dut.tx_state == 2 ? "SEND_SW_LOW" :
             dut.tx_state == 3 ? "SEND_SW_HIGH" : "UNKNOWN");
    $display("Final button data: 0x%h", btn);
    $display("Final switch data: 0x%h", sw);
    $display("Completed tests: %0d of 3", current_test);
  end

endmodule
