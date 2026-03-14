// Branch Metric Computation
// For states 0,3,4,7: expected outputs are 00/11 (bits identical) -- no inversion
// For states 1,2,5,6: expected outputs are 10/01 (bits differ)    -- invert rx_pair[1]
//
// tmp00 = rx_pair[0];  tmp01 = rx_pair[1]  (or ~rx_pair[1] for bmc_inv)
// tmp10 = ~tmp00;      tmp11 = ~tmp01
// path_0_bmc = { tmp00 & tmp01,  tmp00 ^ tmp01 }   (Hamming dist from 00)
// path_1_bmc = { tmp10 & tmp11,  tmp10 ^ tmp11 }   (Hamming dist from 11)

module bmc (
   input  [1:0] rx_pair,
   output [1:0] path_0_bmc,
   output [1:0] path_1_bmc);

   wire tmp00 = rx_pair[0];
   wire tmp01 = rx_pair[1];
   wire tmp10 = ~tmp00;
   wire tmp11 = ~tmp01;

   assign path_0_bmc = {tmp00 & tmp01, tmp00 ^ tmp01};
   assign path_1_bmc = {tmp10 & tmp11, tmp10 ^ tmp11};
endmodule

module bmc_inv (
   input  [1:0] rx_pair,
   output [1:0] path_0_bmc,
   output [1:0] path_1_bmc);

   wire tmp00 = rx_pair[0];
   wire tmp01 = ~rx_pair[1];    // invert rx_pair[1]
   wire tmp10 = ~tmp00;
   wire tmp11 = ~tmp01;

   assign path_0_bmc = {tmp00 & tmp01, tmp00 ^ tmp01};
   assign path_1_bmc = {tmp10 & tmp11, tmp10 ^ tmp11};
endmodule
