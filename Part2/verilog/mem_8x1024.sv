// Trellis memory: 8-bit wide x 1024 deep (stores ACS selection vector)
module mem (
   input               clk,
   input               wr,
   input      [9:0]    addr,
   input      [7:0]    d_i,
   output logic [7:0]  d_o);

   logic [7:0] mem_array [1024];

   always @ (posedge clk) begin
      if (wr) mem_array[addr] <= d_i;
      d_o <= mem_array[addr];
   end
endmodule
