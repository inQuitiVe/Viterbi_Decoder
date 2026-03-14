// Part 2.a.2: Invert bit[1] once every 8 samples  (BER = 1/16)
// Pattern: 7 clean, 1 bad, 7 clean, 1 bad, ...
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

   always @ (posedge clk, negedge rst)
      if (!rst) begin
         $display("2.a.2: bit[1] every 8 samples");
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

         // invert bit[1] every 8 samples
         if (word_ct[2:0] == 3'h7) begin
            err_inj       <= 2'b10;
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
