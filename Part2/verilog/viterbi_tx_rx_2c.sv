// Part 2.c: Find minimum consecutive bit[0] errors needed to cause decoder output errors
//
// BURST_LEN: number of consecutive samples in which bit[0] is inverted
// GAP      : total period (must be > BURST_LEN; large gap isolates each burst)
//
// Usage: change BURST_LEN from 1 upward and recompile/resimulate until bad > 0.
// Suggested GAP=32 (large enough to let decoder recover between bursts).
//
// Injection timing: trigger window = [GAP-BURST_LEN-1, GAP-2]
//   -> actual injections at  [GAP-BURST_LEN, GAP-1]  (BURST_LEN consecutive cycles)
module viterbi_tx_rx #(
   parameter BURST_LEN = 1,   // <-- sweep this: 1,2,3,4,...
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

   // window: positions [GAP-BURST_LEN-1 .. GAP-2] within each GAP-cycle period
   wire in_window = ( (word_ct % GAP) >= (GAP - BURST_LEN - 1) ) &&
                    ( (word_ct % GAP) <= (GAP - 2)              );

   always @ (posedge clk, negedge rst)
      if (!rst) begin
         $display("2.c: consecutive bit[0] burst, BURST_LEN=%0d, GAP=%0d", BURST_LEN, GAP);
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
            err_inj       <= 2'b01;
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
