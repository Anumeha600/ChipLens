module traffic_light_fsm (
  input  wire       clk,
  input  wire       rst,
  input  wire       sensor,
  output reg  [1:0] state
);
  localparam RED    = 2'b00;
  localparam GREEN  = 2'b01;
  localparam YELLOW = 2'b10;

  always @(posedge clk) begin
    if (rst)
      state <= RED;
    else begin
      case (state)
        RED:     state <= sensor ? GREEN : RED;
        GREEN:   state <= YELLOW;
        YELLOW:  state <= RED;
        default: state <= RED;
      endcase
    end
  end
endmodule
