// Part 2.e: Find minimum consecutive BOTH-bit errors needed to cause decoder output errors
//
// BURST_LEN: number of consecutive samples in which both bit[0] and bit[1] are inverted
// GAP      : total period (must be > BURST_LEN; large gap isolates each burst)
//
// Usage: change BURST_LEN from 1 upward and recompile/resimulate until bad > 0.
// Expected: both bits flipped simultaneously counts as 2 channel bit errors per sample,
//   so the threshold is lower than 2.c or 2.d (fewer samples needed to confuse the decoder).
module viterbi_tx_rx #(
   parameter BURST_LEN = 1,   // <-- sweep this: 1,2,3,...
   parameter GAP       = 32
) (
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

   wire in_window = ( (word_ct % GAP) >= (GAP - BURST_LEN - 1) ) &&
                    ( (word_ct % GAP) <= (GAP - 2)              );

   always @ (posedge clk, negedge rst)
      if (!rst) begin
         $display("2.e: consecutive bit[0]+bit[1] burst, BURST_LEN=%0d, GAP=%0d", BURST_LEN, GAP);
         error_counter        <= 0;
         bad_bit_ct           <= 0;
         encoder_o_reg        <= 0;
         encoder_o_reg0       <= 0;
         enable_decoder_in    <= 0;
         enable_encoder_i_reg <= 0;
         word_ct              <= 0;
         err_inj              <= 0;
      end
      else begin
         enable_encoder_i_reg <= enable_encoder_i;
         enable_decoder_in    <= valid_encoder_o;
         encoder_i_reg        <= encoder_i;
         encoder_o_reg0       <= encoder_o;
         word_ct              <= word_ct + 1;

         if (in_window) begin
            err_inj       <= 2'b11;
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
