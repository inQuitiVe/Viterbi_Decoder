// Display memory: 1-bit wide x 1024 deep (stores decoded output bits)
module mem_disp (
   input               clk,
   input               wr,
   input      [9:0]    addr,
   input               d_i,
   output logic        d_o);

   logic mem_array [1024];

   always @ (posedge clk) begin
      if (wr) mem_array[addr] <= d_i;
      d_o <= mem_array[addr];
   end
endmodule
