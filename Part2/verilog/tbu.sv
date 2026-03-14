module tbu
(
   input       clk,
   input       rst,
   input       enable,
   input       selection,
   input [7:0] d_in_0,
   input [7:0] d_in_1,
   output logic  d_o,
   output logic  wr_en);

   logic         d_o_reg;
   logic         wr_en_reg;

   logic   [2:0] pstate;
   logic   [2:0] nstate;

   logic         selection_buf;

   // d_bit selects which memory bank's data to use for traceback
   wire d_bit = selection ? d_in_1[pstate] : d_in_0[pstate];

   always @(posedge clk) begin
      selection_buf <= selection;
      wr_en         <= wr_en_reg;
      d_o           <= d_o_reg;
   end

   always @(posedge clk, negedge rst) begin
      if (!rst)
         pstate <= 3'b0;
      // exception: rst=enable=selection_buf=1, selection just dropped to 0 -> still update
      else if (enable && (selection || (selection_buf && !selection)))
         pstate <= nstate;
   end

   // combinational: wr_en_reg, d_o_reg, nstate
   always_comb begin
      wr_en_reg = selection;
      d_o_reg   = selection ? d_in_1[pstate] : 1'b0;

      // traceback state transition table (spec Table)
      case (pstate)
         3'd0: nstate = d_bit ? 3'd1 : 3'd0;
         3'd1: nstate = d_bit ? 3'd2 : 3'd3;
         3'd2: nstate = d_bit ? 3'd5 : 3'd4;
         3'd3: nstate = d_bit ? 3'd6 : 3'd7;
         3'd4: nstate = d_bit ? 3'd0 : 3'd1;
         3'd5: nstate = d_bit ? 3'd3 : 3'd2;
         3'd6: nstate = d_bit ? 3'd4 : 3'd5;
         3'd7: nstate = d_bit ? 3'd7 : 3'd6;
         default: nstate = 3'd0;
      endcase
   end

endmodule
