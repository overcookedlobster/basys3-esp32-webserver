/*
Filename: baudrate_gen.sv
Description: configurable baudrate generator for UART communicaton

Parameters:
  - CLK_FREQ_HZ: input clock frequency in HZ (default 50MHz)
  - BAUD_RATE: target baud rate (default 9600)
  - OVERSAMPLING: sample rate multiple (16x for standard RX)
*/

module baudrate_gen #(
  parameter int CLK_FREQ_HZ = 100_000_000,
  parameter int BAUD_RATE = 115200,
  parameter int OVERSAMPLING = 16
) (
  input  logic clk,
  input  logic rst_n,
  input  logic enable,
  output logic tick,
  output logic tick_16x
);

  // Calculation of divider counter
  // For simulation, use much smaller values to speed things up
  `ifdef SIMULATION
  localparam int BAUD_DIV = 5;         // Much smaller for simulation
  localparam int BAUD_DIV_16X = 0;     // Much smaller for simulation
  `else
  localparam int BAUD_DIV = CLK_FREQ_HZ / BAUD_RATE - 1;
  localparam int BAUD_DIV_16X = CLK_FREQ_HZ / (BAUD_RATE * OVERSAMPLING) - 1;
  `endif

  // Counter width calculation
  localparam int BAUD_CNT_WIDTH = $clog2(BAUD_DIV + 1);
  localparam int BAUD_CNT_16X_WIDTH = $clog2(BAUD_DIV_16X + 1);

  // Baud rate counters
  logic [BAUD_CNT_WIDTH-1:0] baud_counter;
  logic [BAUD_CNT_16X_WIDTH-1:0] baud_counter_16x;

  // 1x tick baudgen
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      baud_counter <= '0;
      tick <= 1'b0;
    end else if (enable) begin
      if (baud_counter == BAUD_DIV) begin
        baud_counter <= '0;
        tick <= 1'b1;
      end else begin
        baud_counter <= baud_counter + 1'b1;
        tick <= 1'b0;
      end
    end else begin
      // When disabled, reset counter and don't generate ticks
      baud_counter <= '0;
      tick <= 1'b0;
    end
  end

  // 16x tick baudgen for RX module
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      baud_counter_16x <= '0;
      tick_16x <= 1'b0;
    end else if (enable) begin
      if (baud_counter_16x == BAUD_DIV_16X) begin
        baud_counter_16x <= '0;
        tick_16x <= 1'b1;
      end else begin
        baud_counter_16x <= baud_counter_16x + 1'b1;
        tick_16x <= 1'b0;
      end
    end else begin
      // When disabled, reset counter and don't generate ticks
      baud_counter_16x <= '0;
      tick_16x <= 1'b0;
    end
  end

  // Debug display only at the start of simulation
  initial begin
    $display("Baud Rate Generator Configuration:");
    $display("  CLK_FREQ_HZ = %0d", CLK_FREQ_HZ);
    $display("  BAUD_RATE = %0d", BAUD_RATE);
    $display("  OVERSAMPLING = %0d", OVERSAMPLING);
    `ifdef SIMULATION
    $display("  SIMULATION mode enabled");
    `endif
    $display("  BAUD_DIV = %0d", BAUD_DIV);
    $display("  BAUD_DIV_16X = %0d", BAUD_DIV_16X);
  end
endmodule

/*
Filename: uart_tx.sv
Description: UART transmitter with fixed debugging
*/

module uart_tx #(
  parameter int DATA_BITS = 8,
  parameter bit PARITY_EN = 1'b1,
  parameter bit PARITY_TYPE = 1'b0,  // 0=even, 1=odd
  parameter int STOP_BITS = 1
) (
  input  logic                  clk,
  input  logic                  rst_n,
  input  logic                  tick,        // Baud rate tick
  input  logic                  tx_start,    // Start transmission
  input  logic                  cts,         // Clear to Send (flow control)
  input  logic [DATA_BITS-1:0]  tx_data,     // Parallel data input
  output logic                  tx_out,      // Serial data output
  output logic                  tx_busy,     // Transmitter busy
  output logic                  tx_done      // Transmission complete
);

  // States - renamed to avoid conflicts
  typedef enum logic [2:0] {
    S_IDLE,
    S_START_BIT,
    S_DATA_BITS,
    S_PARITY_BIT,
    S_STOP_BIT1,
    S_STOP_BIT2
  } state_t;

  // Internal signals
  state_t current_state;
  logic [3:0] bit_count;
  logic [DATA_BITS-1:0] tx_shift_reg;
  logic [DATA_BITS-1:0] tx_data_latch;  // Latch for tx_data
  logic parity_value;
  logic flow_paused;
  logic tx_start_pending;  // Latch for tx_start signal

  // Debug counter for diagnosing issues (only in simulation)
  `ifdef SIMULATION
  int tick_debug_counter;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tick_debug_counter <= 0;
    end else begin
      if (tick)
        tick_debug_counter <= tick_debug_counter + 1;
    end
  end

  // Selective debug output for state transitions only
  always @(posedge clk) begin
    if (tx_start)
      $display("[UART TX] tx_start asserted with data: 0x%h at time %0t", tx_data, $time);
    if (current_state != S_IDLE && tx_done)
      $display("[UART TX] Transmission complete at time %0t", $time);
  end
  `endif

  // State machine
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      current_state <= S_IDLE;
      tx_out <= 1'b1;  // Idle high
      tx_busy <= 1'b0;
      tx_done <= 1'b0;
      bit_count <= 0;
      tx_shift_reg <= '0;
      tx_data_latch <= '0;
      parity_value <= 1'b0;
      flow_paused <= 1'b0;
      tx_start_pending <= 1'b0;
    end else begin
      // Default assignments
      tx_done <= 1'b0;

      // Latch tx_start signal on rising edge
      if (tx_start && !tx_busy && cts) begin
        tx_start_pending <= 1'b1;
        tx_data_latch <= tx_data;  // Latch the data immediately
      end

      // Check flow control
      if (!cts && !flow_paused && current_state != S_IDLE) begin
        flow_paused <= 1'b1;
      end
      else if (cts && flow_paused) begin
        flow_paused <= 1'b0;
      end

      // Only proceed with state machine if not paused by flow control
      if (!flow_paused) begin
        case (current_state)
          S_IDLE: begin
            tx_out <= 1'b1;  // Line idles high
            tx_busy <= 1'b0;

            // Start transmission on tick if we have a pending request
            if (tick && tx_start_pending) begin
              tx_start_pending <= 1'b0;
              tx_shift_reg <= tx_data_latch;  // Load latched data
              parity_value <= PARITY_TYPE ? ~(^tx_data_latch) : ^tx_data_latch; // Calculate parity
              current_state <= S_START_BIT;
              tx_busy <= 1'b1;
            end
          end

          S_START_BIT: begin
            // Output start bit (always low)
            tx_out <= 1'b0;

            // Wait for tick to move to data state
            if (tick) begin
              current_state <= S_DATA_BITS;
              bit_count <= 0;
            end
          end

          S_DATA_BITS: begin
            // Output current data bit (LSB first)
            tx_out <= tx_shift_reg[0];

            // Handle tick
            if (tick) begin
              // Shift data for next bit
              tx_shift_reg <= tx_shift_reg >> 1;

              // Check if we've sent all data bits
              if (bit_count == DATA_BITS-1) begin
                // Move to next state
                current_state <= PARITY_EN ? S_PARITY_BIT : S_STOP_BIT1;
                bit_count <= 0; // Reset for next transmission
              end else begin
                // Increment counter
                bit_count <= bit_count + 1'b1;
              end
            end
          end

          S_PARITY_BIT: begin
            // Output parity bit
            tx_out <= parity_value;

            if (tick) begin
              current_state <= S_STOP_BIT1;
            end
          end

          S_STOP_BIT1: begin
            // Output stop bit (always high)
            tx_out <= 1'b1;

            if (tick) begin
              if (STOP_BITS == 1) begin
                current_state <= S_IDLE;
                tx_done <= 1'b1;
              end else begin
                current_state <= S_STOP_BIT2;
              end
            end
          end

          S_STOP_BIT2: begin
            // Output second stop bit (always high)
            tx_out <= 1'b1;

            if (tick) begin
              current_state <= S_IDLE;
              tx_done <= 1'b1;
            end
          end

          default: current_state <= S_IDLE;
        endcase
      end
    end
  end

endmodule
