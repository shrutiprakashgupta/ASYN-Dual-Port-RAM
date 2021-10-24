// Asynchronous Dual Port RAM
module dual_port_ram #(parameter D_WIDTH = 8, A_WIDTH = 8) (rst, ce_l, oe_l, we_l, addr_l, data_l, ce_r, oe_r, we_r, addr_r, data_r);

//------ Control Signals --------
  input rst;
  input ce_l;
  input oe_l;
  input we_l;
  input ce_r;
  input oe_r;
  input we_r;

//------ Input/Output -----------
  input [A_WIDTH-1:0] addr_l;
  input [A_WIDTH-1:0] addr_r;
  inout [D_WIDTH-1:0] data_l;
  inout [D_WIDTH-1:0] data_r;
  reg [D_WIDTH-1:0] data_l_reg;
  reg [D_WIDTH-1:0] data_r_reg;

//------- Memory Block ----------
  parameter DEPTH = 1 << A_WIDTH;
  reg [D_WIDTH-1:0] mem [DEPTH-1:0];

//--- Internal Control Signals --
  wire [A_WIDTH-1:0] share_n;
  wire read_normal_l;
  wire write_normal_l;
  wire read_normal_r;
  wire write_normal_r;
  
//------- Manage read/write -----
  assign share_n = addr_l ^ addr_r;
  assign read_normal_l = ce_r | (~oe_r) | we_r;
  assign read_normal_r = ce_l | (~oe_l) | we_l;
  assign write_normal_l = oe_l & (~we_l);
  assign write_normal_r = oe_r & (~we_r);
  assign data_l = (oe_l) ? 'bZ : data_l_reg;
  assign data_r = (oe_r) ? 'bZ : data_r_reg;

//----------Initialize the Memory with all zeros-----------
  integer i;
  always @(*) begin
    if(~rst) begin
      for(i=0; i<DEPTH; i=i+1) begin
        mem [i] <= 0;
      end
      $display("%0ts> Output: Mem initialize", $time);
    end
  end

//----------------- Port Enable Trigger -------------------
  always @(negedge ce_l) 
  if(rst) begin
    if(share_n) begin   
    //Different Target Addresses
      if(write_normal_l) begin   
      //Write
        mem [addr_l] = data_l;
        $display("%0ts> Output: Normal Write Left %d", $time,mem [addr_l]);
      end
      else begin
        if((~oe_l) & we_l) begin   
        //Read
          data_l_reg = mem [addr_l];
          $display("%0ts> Output: Normal Read Left, %d", $time, data_l_reg);
        end
      end
    end
    else begin   
    //Same Target Adresses
      if((~oe_l) & we_l) begin
        if(read_normal_l) begin   
        //If both are reading
          data_l_reg = mem [addr_l];
          $display("%0ts> Output: Normal Read Left %d", $time, data_l_reg);
        end
        else begin     
        //If the other port is writing
          data_l_reg = data_r;
          $display("%0ts> Output: Read recent Left %d", $time, data_l_reg);
        end
      end
      else begin
        if(write_normal_l) begin
        //Left one prefered in writing
          mem [addr_l] = data_l;
          $display("%0ts> Output: Normal Write Left %d", $time, mem[addr_l]);
        end
      end
    end
  end

  always @(negedge ce_r)
  if(rst) begin
    if(share_n) begin
      if(write_normal_r) begin
        mem [addr_r] = data_r;
        $display("%0ts> Output: Normal Write Right %d", $time, mem[addr_r]);
      end
      else begin
        if((~oe_r) & we_r) begin
          data_r_reg = mem [addr_r];
          $display("%0ts> Output: Normal Read Right %d", $time, data_r_reg);
        end
      end
    end
    else begin
      if((~oe_r) & we_r) begin
        if(read_normal_r) begin
          data_r_reg = mem [addr_r];
          $display("%0ts> Output: Normal Read Right %d", $time, data_r_reg);
        end
        else begin
          data_r_reg = data_l;
          $display("%0ts> Output: Read recent Right %d", $time, data_r_reg);
        end
      end
      else begin
        if(oe_r & (~we_r) & read_normal_r) begin
          mem [addr_r] = data_r;
          $display("%0ts> Output: Normal Write Right %d", $time, mem[addr_r]);
        end
      end
    end
  end
endmodule