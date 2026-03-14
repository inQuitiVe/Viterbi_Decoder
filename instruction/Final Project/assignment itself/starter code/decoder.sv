module decoder
(
   input             clk,
   input             rst,
   input             enable,
   input [1:0]       d_in,
   output logic      d_out);

//bmc module signals  (8 of these)
   wire  [1:0]       bmcK_path_N_bmc;  // N=0,1,...7     N=0,1  (16 2-wire signals in all)

//ACS modules signals
   logic   [7:0]       validity;
   logic   [7:0]       selection;
   logic   [7:0]       path_cost   [8];
   wire    [7:0]       validity_nets;
   wire    [7:0]       selection_nets;

   wire              ACSK_selection;  // K=0,1,...7		 (i.e., 8 of these)
   wire              ACSK_valid_o;	  // K=0,1,...7

   wire  [7:0]       ACSK_path_cost;  // K=0,1,...7

//Trelis memory write operation, pipeline delay
   logic   [1:0]       mem_bank;
   logic   [1:0]       mem_bank_Q;
   logic   [1:0]       mem_bank_Q2;
   logic               mem_bank_Q3;
   logic               mem_bank_Q4;
   logic               mem_bank_Q5;
   logic   [9:0]       wr_mem_counter;
   logic   [9:0]       rd_mem_counter;

// 4 memory banks -- address pointers 	  (there are 4 of these)
   logic   [9:0]       addr_mem_K;  // K=A,B,C,D
// write enables
   logic               wr_mem_K;	// K=A,B,C,D
// data to memories
   logic   [7:0]       d_in_mem_K;	// K=A,B,C,D
// data from memories
   wire    [7:0]       d_o_mem_K;	// K=A,B,C,D
		  
//Trace back module signals
   logic               selection_tbu_0;
   logic               selection_tbu_1;

   logic   [7:0]       d_in_0_tbu_0;
   logic   [7:0]       d_in_1_tbu_0;
   logic   [7:0]       d_in_0_tbu_1;
   logic   [7:0]       d_in_1_tbu_1;

   wire                d_o_tbu_0;
   wire                d_o_tbu_1;

   logic               enable_tbu_0;
   logic               enable_tbu_1;

//Display memory operations 
   wire                wr_disp_mem_0;
   wire                wr_disp_mem_1;

   wire                d_in_disp_mem_0;
   wire                d_in_disp_mem_1;

   logic   [9:0]       wr_mem_counter_disp;
   logic   [9:0]       rd_mem_counter_disp;

   logic   [9:0]       addr_disp_mem_0;
   logic   [9:0]       addr_disp_mem_1;

//Branch matrc calculation modules	(8 total)
   bmcK   bmcK_inst(d_in,bmcK_path_0_bmc,bmcK_path_1_bmc);
/* K=0,1,...7 
*/


//Add Compare Select Modules (8 copies -- note pattern in connections!!)
// i = 0, 1, ... 7        j = 0, 3, 4, 7, 1, 2, 5, 6       k = 1, 2, 5, 6, 0, 3, 4, 7  -- these create lattice butterfly connection pattern
   ACS      ACSi(validity[j],validity[k],bmci_path_i_bmc,bmci_path_1_bmc,path_cost[j],path_cost[k],ACSi_selection,ACSi_valid_o,ACSi_path_cost);
   
   // selection_nets  = // concatenate ACS7 ,,, ACS0 _selections (use { ,  } format)
   // validity_nets   = // same for ACSK_valid_os 

   always @ (posedge clk, negedge rst) begin
      if(!rst)  begin
         validity          <= 8'b1;
         selection         <= 8'b0;
/* clear all 8 path costs
         path_cost[i]      <= 8'd0;
*/
      end
      else if(!enable)   begin
         validity          <= 8'b1;
         selection         <= 8'b0;
/* clear all 8 path costs
         path_cost[i]      <= 8'd0;
*/
      end
      else if ( // reduction & of all path_costs' MSBs

      begin

         validity          <= validity_nets;
         selection         <= selection_nets;
         
         path_cost[K]      <= 8'b01111111 & ACSK_path_cost;	 // K = 0, 1, ..., 7
      end
      else   begin
         validity          <= validity_nets;
         selection         <= selection_nets;

         path_cost[K]      <= ACSK_path_cost;	          // K = 0, 1, ..., 7
      end
   end

   always @ (posedge clk, negedge rst) begin	  // wr_mem_counter   commands
// if rst (active low) or not enabling (active high), force to 0; else, increment by 1

   end

   always @ (posedge clk, negedge rst) begin
      if(!rst)
         rd_mem_counter <= // set to max value
      else if(enable)
         rd_mem_counter <= // count down by 1
   end

   always @ (posedge clk, negedge rst)
      if(!rst)
         mem_bank <= 2'b0;
      else begin
         /*if(wr_mem_counter = -1  fill in the guts*/
               mem_bank <= mem_bank + 2'b1;
      end

   always @ (posedge clk)    begin
      d_in_mem_k  <= selection;		  // k = A, B, C, D
   end

// memory bank management: always write to one, read from two others, keep address at 0 (no writing) for fourth one
   always @ (posedge clk)     	  // in each case, the memory bank w/ the wr_mem_counter needs a write enable; all others = 0
      case(mem_bank)
         2'b00:         	 // write to A, clear C, read from others
         2'b01:         	 // write to B, clear D, read from others
         2'b10:       		 // write to C, clear A, read from others
         2'b11:              // write to D, clear B, read from others  
         end		       
      endcase
  end

//Trelis memory module instantiation

   mem   trelis_mem_A	   (
      .clk,
      .wr  (wr_mem_A),
      .addr(addr_mem_A),
      .d_i (d_in_mem_A),
      .d_o (d_o_mem_A)
   );
/* likewise for trelis_memB, C, D
*/

//Trace back module operation

   always @(posedge clk)
/* create mem_bank, mem_bank_Q1, mem_bank_Q2 pipeline */

   always @ (posedge clk, negedge rst)
      if(!rst)
            enable_tbu_0   <= 1'b0;
      else if(mem_bank_Q2==2'b10)
            enable_tbu_0   <= 1'b1;

   always @ (posedge clk, negedge rst)
      if(!rst)
            enable_tbu_1   <= 1'b0;
      else if(mem_bank_Q2==2'b11)
            enable_tbu_1   <= 1'b1;
   
   always @ (posedge clk)
      case(mem_bank_Q2)
         2'b00:	  begin
            d_in_0_tbu_0   <= d_o_mem_D;
            d_in_1_tbu_0   <= d_o_mem_C;
            
            d_in_0_tbu_1   <= d_o_mem_C;
            d_in_1_tbu_1   <= d_o_mem_B;

            selection_tbu_0<= 1'b0;
            selection_tbu_1<= 1'b1;

         end
         2'b01:	   begin
            d_in_0_tbu_0   <= d_o_mem_D;
            d_in_1_tbu_0   <= d_o_mem_C;
            
            d_in_0_tbu_1   <= d_o_mem_A;
            d_in_1_tbu_1   <= d_o_mem_D;
            
            selection_tbu_0<= 1'b1;
            selection_tbu_1<= 1'b0;
         end
         2'b10:	   begin
            d_in_0_tbu_0   <= d_o_mem_B;
            d_in_1_tbu_0   <= d_o_mem_A;
            
            d_in_0_tbu_1   <= d_o_mem_A;
            d_in_1_tbu_1   <= d_o_mem_D;

            selection_tbu_0<= 1'b0;
            selection_tbu_1<= 1'b1;
         end
         2'b11:	  begin
            d_in_0_tbu_0   <= d_o_mem_B;
            d_in_1_tbu_0   <= d_o_mem_A;
            
            d_in_0_tbu_1   <= d_o_mem_C;
            d_in_1_tbu_1   <= d_o_mem_B;

            selection_tbu_0<= 1'b1;
            selection_tbu_1<= 1'b0;
         end
      endcase

//Trace-Back modules instantiation

   tbu tbu_0   (
      .clk,
      .rst,
      .enable(enable_tbu_0),
      .selection(selection_tbu_0),
      .d_in_0(d_in_0_tbu_0),
      .d_in_1(d_in_1_tbu_0),
      .d_o(d_o_tbu_0),
      .wr_en(wr_disp_mem_0)
   );

/* analogous for tbu_1
*/

//Display Memory modules Instantioation
//   d_in_disp_mem_K   =  d_o_tbu_K;  K=0,1

  mem_disp   disp_mem_0	  (
      .clk              ,
      .wr(wr_disp_mem_0),
      .addr(addr_disp_mem_0),
      .d_i(d_in_disp_mem_0),
      .d_o(d_o_disp_mem_0)
   );
/* analogous for disp_mem_1
*/

// Display memory module operation
   always @ (posedge clk)
      mem_bank_Q3 <= mem_bank_Q2[0];

   always @ (posedge clk)
      if(!rst)
         wr_mem_counter_disp  <= min value + 2
      else if(!enable)
         wr_mem_counter_disp  <= //same
      else
//       decrement wr_mem_counter_disp    

   always @ (posedge clk)
      if(!rst)
         rd_mem_counter_disp  <= //max value - 2
      else if(!enable)
         rd_mem_counter_disp  <= //same
      else         // increment    rd_mem_counter_disp     
   
   always @ (posedge clk)
      // if !mem_bank_Q3
         begin
            addr_disp_mem_0   <= rd_mem_counter_disp; 
            addr_disp_mem_1   <= wr_mem_counter_disp;
         end
     //  else:	 swap rd and wr 
      endcase

   always @ (posedge clk) 	 
/* pipeline mem_bank_Q3 to Q4 to Q5
 also  d_out = d_o_disp_mem_i 
    i = mem_bank_Q5 
*/

endmodule
