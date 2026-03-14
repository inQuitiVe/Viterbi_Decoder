module encoder_tb;

   bit         clk;
   bit         rst;
   bit         enable_i=1;
   bit         d_in;
   wire  [1:0] d_out1,
               d_out2;
   wire        valid_o;

   encoder DUT    (
      .clk,
      .rst,
	  .enable_i,
      .d_in,
      .d_out(d_out1),
	  .valid_o   );

   encoder2 DUT2    (
      .clk,
      .rst,
	  .enable_i,
      .d_in,
      .d_out(d_out2),
	  .valid_o   );


   always begin
      #10   clk  =  1'b1;
      #10   clk  = 1'b0;
   end

   initial  begin

      #110
      rst   =  1'b1;
      d_in  =  1'b0;
      
      #20
      d_in  =  1'b1;

      #20
      d_in  =  1'b0;

      #20
      d_in  =  1'b0;

      #20
      d_in  =  1'b0;

      #20
      d_in  =  1'b1;

      #20
      d_in  =  1'b0;

      #20
      d_in  =  1'b0;

      #20
      d_in  =  1'b1;

      #20
      d_in  =  1'b1;
      
      #20
      d_in  =  1'b0;
      
      #20
      d_in  =  1'b0;

      $stop;

   end
endmodule
