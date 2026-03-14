module decoder
(
   input             clk,
   input             rst,
   input             enable,
   input [1:0]       d_in,
   output logic      d_out);

// ─── BMC signals: 8 pairs (path_0 and path_1 branch metrics, 2-bit each) ──
   wire [1:0] bmc0_p0, bmc0_p1;
   wire [1:0] bmc1_p0, bmc1_p1;
   wire [1:0] bmc2_p0, bmc2_p1;
   wire [1:0] bmc3_p0, bmc3_p1;
   wire [1:0] bmc4_p0, bmc4_p1;
   wire [1:0] bmc5_p0, bmc5_p1;
   wire [1:0] bmc6_p0, bmc6_p1;
   wire [1:0] bmc7_p0, bmc7_p1;

// ─── ACS output signals (8 instances × 3 outputs each) ───────────────────
   wire        ACS0_sel, ACS0_val;  wire [7:0] ACS0_pc;
   wire        ACS1_sel, ACS1_val;  wire [7:0] ACS1_pc;
   wire        ACS2_sel, ACS2_val;  wire [7:0] ACS2_pc;
   wire        ACS3_sel, ACS3_val;  wire [7:0] ACS3_pc;
   wire        ACS4_sel, ACS4_val;  wire [7:0] ACS4_pc;
   wire        ACS5_sel, ACS5_val;  wire [7:0] ACS5_pc;
   wire        ACS6_sel, ACS6_val;  wire [7:0] ACS6_pc;
   wire        ACS7_sel, ACS7_val;  wire [7:0] ACS7_pc;

// ─── ACS state registers ──────────────────────────────────────────────────
   logic   [7:0]       validity;          // which states are reachable
   logic   [7:0]       selection;         // ACS selection bits (stored)
   logic   [7:0]       path_cost   [8];   // accumulated path metrics
   wire    [7:0]       validity_nets;     // combinational from ACS valid_o
   wire    [7:0]       selection_nets;    // combinational from ACS selection

// ─── Trellis memory pipeline control ─────────────────────────────────────
   logic   [1:0]       mem_bank;
   logic   [1:0]       mem_bank_Q;
   logic   [1:0]       mem_bank_Q2;
   logic               mem_bank_Q3;
   logic               mem_bank_Q4;
   logic               mem_bank_Q5;
   logic   [9:0]       wr_mem_counter;
   logic   [9:0]       rd_mem_counter;

// ─── Trellis memory banks A/B/C/D ────────────────────────────────────────
   logic   [9:0]       addr_mem_A, addr_mem_B, addr_mem_C, addr_mem_D;
   logic               wr_mem_A,   wr_mem_B,   wr_mem_C,   wr_mem_D;
   logic   [7:0]       d_in_mem_A, d_in_mem_B, d_in_mem_C, d_in_mem_D;
   wire    [7:0]       d_o_mem_A,  d_o_mem_B,  d_o_mem_C,  d_o_mem_D;

// ─── Trace-back signals ───────────────────────────────────────────────────
   logic               selection_tbu_0, selection_tbu_1;
   logic   [7:0]       d_in_0_tbu_0, d_in_1_tbu_0;
   logic   [7:0]       d_in_0_tbu_1, d_in_1_tbu_1;
   wire                d_o_tbu_0, d_o_tbu_1;
   logic               enable_tbu_0, enable_tbu_1;

// ─── Display memory signals ───────────────────────────────────────────────
   wire                wr_disp_mem_0, wr_disp_mem_1;
   wire                d_in_disp_mem_0, d_in_disp_mem_1;
   wire                d_o_disp_mem_0, d_o_disp_mem_1;
   logic   [9:0]       wr_mem_counter_disp;
   logic   [9:0]       rd_mem_counter_disp;
   logic   [9:0]       addr_disp_mem_0, addr_disp_mem_1;

// ─── BMC instances ────────────────────────────────────────────────────────
// states 0,3,4,7: encoder outputs 00/11 (no inversion)
// states 1,2,5,6: encoder outputs 10/01 (invert rx_pair[1])
   bmc     bmc0_inst (.rx_pair(d_in), .path_0_bmc(bmc0_p0), .path_1_bmc(bmc0_p1));
   bmc_inv bmc1_inst (.rx_pair(d_in), .path_0_bmc(bmc1_p0), .path_1_bmc(bmc1_p1));
   bmc_inv bmc2_inst (.rx_pair(d_in), .path_0_bmc(bmc2_p0), .path_1_bmc(bmc2_p1));
   bmc     bmc3_inst (.rx_pair(d_in), .path_0_bmc(bmc3_p0), .path_1_bmc(bmc3_p1));
   bmc     bmc4_inst (.rx_pair(d_in), .path_0_bmc(bmc4_p0), .path_1_bmc(bmc4_p1));
   bmc_inv bmc5_inst (.rx_pair(d_in), .path_0_bmc(bmc5_p0), .path_1_bmc(bmc5_p1));
   bmc_inv bmc6_inst (.rx_pair(d_in), .path_0_bmc(bmc6_p0), .path_1_bmc(bmc6_p1));
   bmc     bmc7_inst (.rx_pair(d_in), .path_0_bmc(bmc7_p0), .path_1_bmc(bmc7_p1));

// ─── ACS instances ────────────────────────────────────────────────────────
// Butterfly pattern: i=0..7, j=0,3,4,7,1,2,5,6, k=1,2,5,6,0,3,4,7
// ACS_i computes path metric for nstate=i, using predecessor states j (path_0) and k (path_1)
   ACS ACS0 (.path_0_valid(validity[0]), .path_1_valid(validity[1]),
             .path_0_bmc(bmc0_p0),       .path_1_bmc(bmc0_p1),
             .path_0_pmc(path_cost[0]),  .path_1_pmc(path_cost[1]),
             .selection(ACS0_sel), .valid_o(ACS0_val), .path_cost(ACS0_pc));

   ACS ACS1 (.path_0_valid(validity[3]), .path_1_valid(validity[2]),
             .path_0_bmc(bmc1_p0),       .path_1_bmc(bmc1_p1),
             .path_0_pmc(path_cost[3]),  .path_1_pmc(path_cost[2]),
             .selection(ACS1_sel), .valid_o(ACS1_val), .path_cost(ACS1_pc));

   ACS ACS2 (.path_0_valid(validity[4]), .path_1_valid(validity[5]),
             .path_0_bmc(bmc2_p0),       .path_1_bmc(bmc2_p1),
             .path_0_pmc(path_cost[4]),  .path_1_pmc(path_cost[5]),
             .selection(ACS2_sel), .valid_o(ACS2_val), .path_cost(ACS2_pc));

   ACS ACS3 (.path_0_valid(validity[7]), .path_1_valid(validity[6]),
             .path_0_bmc(bmc3_p0),       .path_1_bmc(bmc3_p1),
             .path_0_pmc(path_cost[7]),  .path_1_pmc(path_cost[6]),
             .selection(ACS3_sel), .valid_o(ACS3_val), .path_cost(ACS3_pc));

   ACS ACS4 (.path_0_valid(validity[1]), .path_1_valid(validity[0]),
             .path_0_bmc(bmc4_p0),       .path_1_bmc(bmc4_p1),
             .path_0_pmc(path_cost[1]),  .path_1_pmc(path_cost[0]),
             .selection(ACS4_sel), .valid_o(ACS4_val), .path_cost(ACS4_pc));

   ACS ACS5 (.path_0_valid(validity[2]), .path_1_valid(validity[3]),
             .path_0_bmc(bmc5_p0),       .path_1_bmc(bmc5_p1),
             .path_0_pmc(path_cost[2]),  .path_1_pmc(path_cost[3]),
             .selection(ACS5_sel), .valid_o(ACS5_val), .path_cost(ACS5_pc));

   ACS ACS6 (.path_0_valid(validity[5]), .path_1_valid(validity[4]),
             .path_0_bmc(bmc6_p0),       .path_1_bmc(bmc6_p1),
             .path_0_pmc(path_cost[5]),  .path_1_pmc(path_cost[4]),
             .selection(ACS6_sel), .valid_o(ACS6_val), .path_cost(ACS6_pc));

   ACS ACS7 (.path_0_valid(validity[6]), .path_1_valid(validity[7]),
             .path_0_bmc(bmc7_p0),       .path_1_bmc(bmc7_p1),
             .path_0_pmc(path_cost[6]),  .path_1_pmc(path_cost[7]),
             .selection(ACS7_sel), .valid_o(ACS7_val), .path_cost(ACS7_pc));

   assign selection_nets = {ACS7_sel, ACS6_sel, ACS5_sel, ACS4_sel,
                            ACS3_sel, ACS2_sel, ACS1_sel, ACS0_sel};
   assign validity_nets  = {ACS7_val, ACS6_val, ACS5_val, ACS4_val,
                            ACS3_val, ACS2_val, ACS1_val, ACS0_val};

// ─── ACS state update ─────────────────────────────────────────────────────
   always @ (posedge clk, negedge rst) begin
      if (!rst) begin
         validity     <= 8'b00000001;   // only state 0 valid at start
         selection    <= 8'b0;
         path_cost[0] <= 8'd0;  path_cost[1] <= 8'd0;
         path_cost[2] <= 8'd0;  path_cost[3] <= 8'd0;
         path_cost[4] <= 8'd0;  path_cost[5] <= 8'd0;
         path_cost[6] <= 8'd0;  path_cost[7] <= 8'd0;
      end
      else if (!enable) begin
         validity     <= 8'b00000001;
         selection    <= 8'b0;
         path_cost[0] <= 8'd0;  path_cost[1] <= 8'd0;
         path_cost[2] <= 8'd0;  path_cost[3] <= 8'd0;
         path_cost[4] <= 8'd0;  path_cost[5] <= 8'd0;
         path_cost[6] <= 8'd0;  path_cost[7] <= 8'd0;
      end
      // overflow normalization: when all new path costs have MSB=1, mask off bit 7
      else if (ACS0_pc[7] & ACS1_pc[7] & ACS2_pc[7] & ACS3_pc[7] &
               ACS4_pc[7] & ACS5_pc[7] & ACS6_pc[7] & ACS7_pc[7]) begin
         validity     <= validity_nets;
         selection    <= selection_nets;
         path_cost[0] <= 8'h7F & ACS0_pc;  path_cost[1] <= 8'h7F & ACS1_pc;
         path_cost[2] <= 8'h7F & ACS2_pc;  path_cost[3] <= 8'h7F & ACS3_pc;
         path_cost[4] <= 8'h7F & ACS4_pc;  path_cost[5] <= 8'h7F & ACS5_pc;
         path_cost[6] <= 8'h7F & ACS6_pc;  path_cost[7] <= 8'h7F & ACS7_pc;
      end
      else begin
         validity     <= validity_nets;
         selection    <= selection_nets;
         path_cost[0] <= ACS0_pc;  path_cost[1] <= ACS1_pc;
         path_cost[2] <= ACS2_pc;  path_cost[3] <= ACS3_pc;
         path_cost[4] <= ACS4_pc;  path_cost[5] <= ACS5_pc;
         path_cost[6] <= ACS6_pc;  path_cost[7] <= ACS7_pc;
      end
   end

// ─── Write counter: counts 0..1023, resets on !rst or !enable ─────────────
   always @ (posedge clk, negedge rst) begin
      if (!rst || !enable)
         wr_mem_counter <= 10'd0;
      else
         wr_mem_counter <= wr_mem_counter + 10'd1;
   end

// ─── Read counter: starts at 1023, counts down (traceback direction) ──────
   always @ (posedge clk, negedge rst) begin
      if (!rst)
         rd_mem_counter <= 10'h3FF;
      else if (enable)
         rd_mem_counter <= rd_mem_counter - 10'd1;
   end

// ─── Memory bank: advances every 1024 cycles ──────────────────────────────
   always @ (posedge clk, negedge rst)
      if (!rst)
         mem_bank <= 2'b0;
      else if (wr_mem_counter == 10'h3FF)
         mem_bank <= mem_bank + 2'b1;

// ─── Data to trellis memories: all banks receive same selection vector ─────
   always @ (posedge clk) begin
      d_in_mem_A <= selection;
      d_in_mem_B <= selection;
      d_in_mem_C <= selection;
      d_in_mem_D <= selection;
   end

// ─── Memory bank management ───────────────────────────────────────────────
// Write to one bank, read from two others, keep fourth at wr_counter (clear/idle)
   always @ (posedge clk)
      case (mem_bank)
         2'b00: begin   // write A, clear C, read B+D
            wr_mem_A <= enable;      addr_mem_A <= wr_mem_counter;
            wr_mem_B <= 1'b0;        addr_mem_B <= rd_mem_counter;
            wr_mem_C <= 1'b0;        addr_mem_C <= wr_mem_counter;
            wr_mem_D <= 1'b0;        addr_mem_D <= rd_mem_counter;
         end
         2'b01: begin   // write B, clear D, read A+C
            wr_mem_A <= 1'b0;        addr_mem_A <= rd_mem_counter;
            wr_mem_B <= enable;      addr_mem_B <= wr_mem_counter;
            wr_mem_C <= 1'b0;        addr_mem_C <= rd_mem_counter;
            wr_mem_D <= 1'b0;        addr_mem_D <= wr_mem_counter;
         end
         2'b10: begin   // write C, clear A, read B+D
            wr_mem_A <= 1'b0;        addr_mem_A <= wr_mem_counter;
            wr_mem_B <= 1'b0;        addr_mem_B <= rd_mem_counter;
            wr_mem_C <= enable;      addr_mem_C <= wr_mem_counter;
            wr_mem_D <= 1'b0;        addr_mem_D <= rd_mem_counter;
         end
         2'b11: begin   // write D, clear B, read A+C
            wr_mem_A <= 1'b0;        addr_mem_A <= rd_mem_counter;
            wr_mem_B <= 1'b0;        addr_mem_B <= wr_mem_counter;
            wr_mem_C <= 1'b0;        addr_mem_C <= rd_mem_counter;
            wr_mem_D <= enable;      addr_mem_D <= wr_mem_counter;
         end
         default: begin
            wr_mem_A <= 1'b0;  wr_mem_B <= 1'b0;
            wr_mem_C <= 1'b0;  wr_mem_D <= 1'b0;
            addr_mem_A <= 10'd0;  addr_mem_B <= 10'd0;
            addr_mem_C <= 10'd0;  addr_mem_D <= 10'd0;
         end
      endcase

// ─── Trellis memory instances ─────────────────────────────────────────────
   mem trelis_mem_A (.clk, .wr(wr_mem_A), .addr(addr_mem_A),
                     .d_i(d_in_mem_A), .d_o(d_o_mem_A));
   mem trelis_mem_B (.clk, .wr(wr_mem_B), .addr(addr_mem_B),
                     .d_i(d_in_mem_B), .d_o(d_o_mem_B));
   mem trelis_mem_C (.clk, .wr(wr_mem_C), .addr(addr_mem_C),
                     .d_i(d_in_mem_C), .d_o(d_o_mem_C));
   mem trelis_mem_D (.clk, .wr(wr_mem_D), .addr(addr_mem_D),
                     .d_i(d_in_mem_D), .d_o(d_o_mem_D));

// ─── mem_bank pipeline (2-bit: Q, Q2) for TBU mux alignment ──────────────
   always @(posedge clk) begin
      mem_bank_Q  <= mem_bank;
      mem_bank_Q2 <= mem_bank_Q;
   end

// ─── TBU enable (set once, never cleared after first activation) ──────────
   always @ (posedge clk, negedge rst)
      if (!rst)                        enable_tbu_0 <= 1'b0;
      else if (mem_bank_Q2 == 2'b10)   enable_tbu_0 <= 1'b1;

   always @ (posedge clk, negedge rst)
      if (!rst)                        enable_tbu_1 <= 1'b0;
      else if (mem_bank_Q2 == 2'b11)   enable_tbu_1 <= 1'b1;

// ─── TBU input mux (registered, aligned to mem_bank_Q2) ──────────────────
   always @ (posedge clk)
      case (mem_bank_Q2)
         2'b00: begin
            d_in_0_tbu_0 <= d_o_mem_D;  d_in_1_tbu_0 <= d_o_mem_C;
            d_in_0_tbu_1 <= d_o_mem_C;  d_in_1_tbu_1 <= d_o_mem_B;
            selection_tbu_0 <= 1'b0;    selection_tbu_1 <= 1'b1;
         end
         2'b01: begin
            d_in_0_tbu_0 <= d_o_mem_D;  d_in_1_tbu_0 <= d_o_mem_C;
            d_in_0_tbu_1 <= d_o_mem_A;  d_in_1_tbu_1 <= d_o_mem_D;
            selection_tbu_0 <= 1'b1;    selection_tbu_1 <= 1'b0;
         end
         2'b10: begin
            d_in_0_tbu_0 <= d_o_mem_B;  d_in_1_tbu_0 <= d_o_mem_A;
            d_in_0_tbu_1 <= d_o_mem_A;  d_in_1_tbu_1 <= d_o_mem_D;
            selection_tbu_0 <= 1'b0;    selection_tbu_1 <= 1'b1;
         end
         2'b11: begin
            d_in_0_tbu_0 <= d_o_mem_B;  d_in_1_tbu_0 <= d_o_mem_A;
            d_in_0_tbu_1 <= d_o_mem_C;  d_in_1_tbu_1 <= d_o_mem_B;
            selection_tbu_0 <= 1'b1;    selection_tbu_1 <= 1'b0;
         end
         default: begin
            d_in_0_tbu_0 <= 8'b0;  d_in_1_tbu_0 <= 8'b0;
            d_in_0_tbu_1 <= 8'b0;  d_in_1_tbu_1 <= 8'b0;
            selection_tbu_0 <= 1'b0;  selection_tbu_1 <= 1'b0;
         end
      endcase

// ─── Trace-Back module instances ──────────────────────────────────────────
   tbu tbu_0 (
      .clk, .rst,
      .enable   (enable_tbu_0),
      .selection(selection_tbu_0),
      .d_in_0   (d_in_0_tbu_0),
      .d_in_1   (d_in_1_tbu_0),
      .d_o      (d_o_tbu_0),
      .wr_en    (wr_disp_mem_0)
   );

   tbu tbu_1 (
      .clk, .rst,
      .enable   (enable_tbu_1),
      .selection(selection_tbu_1),
      .d_in_0   (d_in_0_tbu_1),
      .d_in_1   (d_in_1_tbu_1),
      .d_o      (d_o_tbu_1),
      .wr_en    (wr_disp_mem_1)
   );

// ─── Display memory data connections ──────────────────────────────────────
   assign d_in_disp_mem_0 = d_o_tbu_0;
   assign d_in_disp_mem_1 = d_o_tbu_1;

// ─── Display memory instances ─────────────────────────────────────────────
   mem_disp disp_mem_0 (
      .clk,
      .wr  (wr_disp_mem_0),
      .addr(addr_disp_mem_0),
      .d_i (d_in_disp_mem_0),
      .d_o (d_o_disp_mem_0)
   );

   mem_disp disp_mem_1 (
      .clk,
      .wr  (wr_disp_mem_1),
      .addr(addr_disp_mem_1),
      .d_i (d_in_disp_mem_1),
      .d_o (d_o_disp_mem_1)
   );

// ─── Display memory operation ─────────────────────────────────────────────
   always @ (posedge clk)
      mem_bank_Q3 <= mem_bank_Q2[0];

   // write counter: starts at 2, decrements (ping-pong with rd_counter)
   always @ (posedge clk)
      if (!rst || !enable)
         wr_mem_counter_disp <= 10'd2;
      else
         wr_mem_counter_disp <= wr_mem_counter_disp - 10'd1;

   // read counter: starts at 1021, increments
   always @ (posedge clk)
      if (!rst || !enable)
         rd_mem_counter_disp <= 10'd1021;
      else
         rd_mem_counter_disp <= rd_mem_counter_disp + 10'd1;

   // address mux: alternate which disp_mem reads vs writes based on Q3
   always @ (posedge clk)
      if (!mem_bank_Q3) begin
         addr_disp_mem_0 <= rd_mem_counter_disp;
         addr_disp_mem_1 <= wr_mem_counter_disp;
      end else begin
         addr_disp_mem_0 <= wr_mem_counter_disp;
         addr_disp_mem_1 <= rd_mem_counter_disp;
      end

// ─── Output pipeline: Q3 → Q4 → Q5 → d_out ──────────────────────────────
   always @ (posedge clk) begin
      mem_bank_Q4 <= mem_bank_Q3;
      mem_bank_Q5 <= mem_bank_Q4;
   end

   always @ (posedge clk)
      d_out <= mem_bank_Q5 ? d_o_disp_mem_1 : d_o_disp_mem_0;

endmodule
