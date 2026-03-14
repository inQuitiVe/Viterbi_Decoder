module ACS                              // add-compare-select
(  input       path_0_valid,
   input       path_1_valid,
   input [1:0] path_0_bmc,             // branch metric computation
   input [1:0] path_1_bmc,
   input [7:0] path_0_pmc,             // path metric (accumulated cost)
   input [7:0] path_1_pmc,

   output logic        selection,
   output logic        valid_o,
   output       [7:0]  path_cost);

   wire [7:0] path_cost_0 = path_0_pmc + {6'b0, path_0_bmc};
   wire [7:0] path_cost_1 = path_1_pmc + {6'b0, path_1_bmc};

   always_comb begin
      valid_o = path_0_valid | path_1_valid;
      // selection truth table per spec:
      //  path_1_valid=0          -> selection=0  (regardless of path_0_valid)
      //  path_0_valid=0, p1v=1   -> selection=1
      //  both valid              -> 1 if path_cost_0 > path_cost_1, else 0
      if (!path_1_valid)
         selection = 1'b0;
      else if (!path_0_valid)
         selection = 1'b1;
      else
         selection = (path_cost_0 > path_cost_1) ? 1'b1 : 1'b0;
   end

   // when valid_o=0 (neither path valid), output 0 per spec
   assign path_cost = valid_o ? (selection ? path_cost_1 : path_cost_0) : 8'b0;

endmodule
