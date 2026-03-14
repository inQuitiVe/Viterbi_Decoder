module encoder2                    // use this one
( input              clk,
                     rst,
                     enable_i,
                     d_in,
  output logic       valid_o,
  output logic [1:0] d_out);
   
  logic        [2:0] cstate;
  logic        [2:0] nstate;
  logic              valid_oQ;   
  logic        [1:0] d_out_reg;

  always_comb 
      valid_oQ  =   enable_i;

  always_comb d_out_reg[0] = d_in;
  always_comb d_out_reg[1] = d_in ^ cstate[2] ^ cstate[1];
  always_comb nstate[1:0]  = cstate[2:1];
  always_comb nstate[2]    = d_in^cstate[1]^cstate[0];

  always @ (posedge clk,negedge rst)   begin
//      $display("data in=%d state=%b%b%b data out=%b%b",d_in,reg_1,reg_2,reg_3,d_out_reg[1],d_out_reg[0]);
    if(!rst)
      cstate   <= 3'b000;
    else if(!enable_i)
      cstate   <= 3'b000;
    else
      cstate   <= nstate;
      d_out    <=  (enable_i)? d_out_reg : 2'b00;
	  valid_o  <= valid_oQ;
  end

endmodule
