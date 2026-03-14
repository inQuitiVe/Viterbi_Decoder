// Part 2.b.6: Random version of 2.a.6 -- random 4-consecutive bit[0] bursts
// Average: ~1 burst per 32 cycles  (trigger prob 1/32 per sample, burst length 4)
// burst_cnt counts remaining cycles in the burst (0 = idle).
module viterbi_tx_rx #(parameter N=4) (
   input    clk,
   input    rst,
   input    encoder_i,
   input    enable_encoder_i,
   output   decoder_o);

   wire  [1:0] encoder_o;

   int         error_counter, bad_bit_ct, word_ct;
   logic [1:0] encoder_o_reg0, encoder_o_reg;
   logic       encoder_i_reg, enable_decoder_in, enable_encoder_i_reg;
   wire        valid_encoder_o;
   logic [1:0] err_inj;
   logic [2:0] burst_cnt;   // counts remaining burst cycles (1-based)

   always @ (posedge clk, negedge rst)
      if (!rst) begin
         $display("2.b.6: random 4-burst bit[0], avg 1 burst per 32");
         error_counter        <= 0;
         bad_bit_ct           <= 0;
         encoder_o_reg        <= 0;
         encoder_o_reg0       <= 0;
         enable_decoder_in    <= 0;
         enable_encoder_i_reg <= 0;
         word_ct              <= 0;
         err_inj              <= 0;
         burst_cnt            <= 0;
      end
      else begin
         enable_encoder_i_reg <= enable_encoder_i;
         enable_decoder_in    <= valid_encoder_o;
         encoder_i_reg        <= encoder_i;
         encoder_o_reg0       <= encoder_o;
         word_ct              <= word_ct + 1;

         if (burst_cnt > 0) begin
            err_inj       <= 2'b01;
            burst_cnt     <= burst_cnt - 1;
            error_counter <= error_counter + 1;
         end else if (($random & 32'h1f) == 0) begin
            // ~1/32 trigger probability
            err_inj       <= 2'b01;
            burst_cnt     <= 3'd3;   // 3 more after this = 4 total
            error_counter <= error_counter + 1;
         end else
            err_inj <= 2'b00;

         encoder_o_reg <= encoder_o ^ err_inj;

         if (word_ct < 256)
            bad_bit_ct <= bad_bit_ct
                        + (encoder_o_reg0[1] ^ encoder_o_reg[1])
                        + (encoder_o_reg0[0] ^ encoder_o_reg[0]);
      end

   encoder encoder1 (
      .clk, .rst,
      .enable_i(enable_encoder_i),
      .d_in    (encoder_i),
      .valid_o (valid_encoder_o),
      .d_out   (encoder_o));

   decoder decoder1 (
      .clk, .rst,
      .enable(enable_decoder_in),
      .d_in  (encoder_o_reg),
      .d_out (decoder_o));

endmodule
