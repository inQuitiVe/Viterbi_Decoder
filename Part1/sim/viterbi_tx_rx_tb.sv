// test bench	generates test signals, operates environment, checks and scores outputs
module viterbi_tx_rx_tb();
   bit clk;
   bit rst;
   bit encoder_i;		   // original data
   bit enc_i_hist[2048];   // history thereof
   bit enable_encoder_i;
   wire decoder_o;		   // decoded data, should match original
   bit dec_o_hist[2048];   // history thereof
   bit disp;			   // end of test flag
   int good, bad; 		   // scoreboard

// this module contains conv. encode, channel, and Vit decode
   viterbi_tx_rx vtr(
      .clk,
      .rst,
      .encoder_i,		    // original data
      .enable_encoder_i,
      .decoder_o    );		// decoded data

   always begin
      #50ns  clk   = 'b1;
      #50ns  clk   = 'b0;
   end
   int i, j, k, l;

   always @(posedge clk) begin
	 enc_i_hist[i] <= encoder_i;
	 i <= i+1;				// counters for data in and out
	 l <= l+1;
   end

   initial begin   
	 #410500ns;//#410400;//
	 forever @(posedge clk) begin
	   dec_o_hist[k] <= decoder_o;
	   k<=k+1;
     end
   end
   initial begin	   // bring in the message
      #1000ns    rst       =  1'b1;
                 enable_encoder_i  =  1'b1;
      repeat(2) begin
      #100ns     encoder_i=  1'b1; 
      #100ns     encoder_i=  1'b0;   
      #200ns     encoder_i=  1'b1;  
      #200ns     encoder_i=  1'b0;  
      #300ns     encoder_i=  1'b1;  
      #300ns     encoder_i=  1'b0;  
      #400ns     encoder_i=  1'b1;  
      #400ns     encoder_i=  1'b0;  
      #500ns	 encoder_i=  1'b1;  
      #500ns     encoder_i=  1'b0;
      #100ns     encoder_i=  1'b1; 
      #100ns     encoder_i=  1'b0;   
      #100ns     encoder_i=  1'b1; 
      #100ns     encoder_i=  1'b0;   
      #100ns     encoder_i=  1'b1; 
      #100ns     encoder_i=  1'b0;   
      #100ns     encoder_i=  1'b1; 
      #100ns     encoder_i=  1'b0;   
      end
      #1000ns  	 encoder_i=  1'b1;
      #1000ns	 encoder_i=  1'b0;
	  repeat(20)
      #100ns	 encoder_i=  $random>>3;
      #100ns 	 encoder_i=  1'b0;
      #1000ns    encoder_i=  1'b1;
      #1000ns	 encoder_i=  1'b0;
      #100ns	 encoder_i=  1'b1;
      #10000ns   encoder_i=  1'b0;
      #100ns     encoder_i=  1'b1;
      #10000ns   encoder_i=  1'b0;
      #100ns     encoder_i=  1'b1;
      #10000ns	 encoder_i=  1'b0;
      #1000000ns $display("word_count = %d",vtr.word_ct);                    	    
      for(j=0; j<256; j=j+1) 		// checker & scoreboard
        if(enc_i_hist[j]==dec_o_hist[j]) begin 
          $displayb("yaa! in = %b, out = %b, w_ct = %d, err = %b",
                     enc_i_hist[j],dec_o_hist[j],j,vtr.err_inj);
          good++;
		end
		else begin
          $displayb("boo! in = %b, out = %b, w_ct = %d, err = %b, %t, BAD!",
                    enc_i_hist[j],dec_o_hist[j],j,vtr.err_inj,$time);
          bad++;
		end
	  $display("corrupted_bits = %d, OUT: good = %d, bad = %d",
	    vtr.error_counter,good,bad);
	  disp = 1;
      $stop;
   end

endmodule
