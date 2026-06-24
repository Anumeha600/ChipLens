module uart_tx #(
  parameter CLK_FREQ  = 50_000_000,
  parameter BAUD_RATE = 115_200
)(
  input  wire       clk,
  input  wire       rst_n,
  input  wire [7:0] tx_data,
  input  wire       tx_start,
  output reg        tx_out,
  output reg        tx_busy
);
  localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
  localparam IDLE  = 2'b00;
  localparam START = 2'b01;
  localparam DATA  = 2'b10;
  localparam STOP  = 2'b11;

  reg [1:0]  state;
  reg [15:0] clk_count;
  reg [2:0]  bit_index;
  reg [7:0]  tx_shift;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state     <= IDLE;
      tx_out    <= 1'b1;
      tx_busy   <= 1'b0;
      clk_count <= 0;
      bit_index <= 0;
      tx_shift  <= 0;
    end else begin
      case (state)
        IDLE: begin
          tx_out <= 1'b1;
          if (tx_start) begin
            tx_busy  <= 1'b1;
            tx_shift <= tx_data;
            state    <= START;
          end
        end
        START: begin
          tx_out <= 1'b0;
          if (clk_count < CLKS_PER_BIT - 1)
            clk_count <= clk_count + 1;
          else begin
            clk_count <= 0;
            state     <= DATA;
          end
        end
        DATA: begin
          tx_out <= tx_shift[bit_index];
          if (clk_count < CLKS_PER_BIT - 1) begin
            clk_count <= clk_count + 1;
          end else begin
            clk_count <= 0;
            if (bit_index < 7)
              bit_index <= bit_index + 1;
            else begin
              bit_index <= 0;
              state     <= STOP;
            end
          end
        end
        STOP: begin
          tx_out <= 1'b1;
          if (clk_count < CLKS_PER_BIT - 1)
            clk_count <= clk_count + 1;
          else begin
            clk_count <= 0;
            tx_busy   <= 1'b0;
            state     <= IDLE;
          end
        end
        default: state <= IDLE;
      endcase
    end
  end
endmodule
