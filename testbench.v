// Test bench for Asynchronous Dual Port RAM
`define WIDTH 8

class stimulus_control;
  rand bit oe_l;
  rand bit we_l;
  rand bit oe_r;
  rand bit we_r;
  
  constraint choose_l {oe_l != we_l;}
  constraint choose_r {oe_r != we_r;}

endclass

class stimulus_data;
  rand bit [`WIDTH-1:0] addr_l;
  rand bit [`WIDTH-1:0] addr_r;
  rand bit [`WIDTH-1:0] data_l;
  rand bit [`WIDTH-1:0] data_r;
  
  constraint overlap {(addr_l-addr_r) dist {0:/50,[1:8]:/50};}
endclass

module test_dual_port_ram;
  
  reg rst;
  reg ce_l;
  reg oe_l;
  reg we_l;
  reg ce_r;
  reg oe_r;
  reg we_r;

  reg [`WIDTH-1:0] addr_l;
  reg [`WIDTH-1:0] addr_r;
  wire [`WIDTH-1:0] data_l;
  wire [`WIDTH-1:0] data_r;

  reg [`WIDTH-1:0] data_l_in;
  reg [`WIDTH-1:0] data_r_in;

  assign data_l = (oe_l) ? data_l_in : `WIDTH'bZ;
  assign data_r = (oe_r) ? data_r_in : `WIDTH'bZ;

  dual_port_ram #(`WIDTH) uut (.rst(rst), .ce_l(ce_l), .oe_l(oe_l), .we_l(we_l), .addr_l(addr_l), .data_l(data_l), .ce_r(ce_r), .oe_r(oe_r), .we_r(we_r), .addr_r(addr_r), .data_r(data_r));

  task tick_left;
    #8; ce_l = ~ce_l; 
    $display("%0ts> Trigger: rst = %d, ce_l = %d, oe_l = %d, we_l = %d, addr_l = %d, data_l = %d", $time, rst, ce_l, oe_l, we_l, addr_l, data_l);
    #10; ce_l = ~ce_l;
    //$display("data_l = %d", data_l);
  endtask

  task tick_right;
    #15; ce_r = ~ce_r;
    $display("%0ts> Trigger: rst = %d, ce_r = %d, oe_r = %d, we_r = %d, addr_r = %d, data_r = %d", $time, rst, ce_r, oe_r, we_r, addr_r, data_r);
    #9; ce_r = ~ce_r;
    //$display("data_r = %d", data_r);
  endtask

  task reset;
    #5; rst = 0; ce_l = 1; ce_r = 1;
    #5; rst = 1;
  endtask
  
  initial begin
    stimulus_control io = new();
    stimulus_data data = new();

    reset;
    repeat(6) begin
      data.randomize();
      repeat(6) begin
        io.randomize();

        oe_l = io.oe_l;
        we_l = io.we_l;
        addr_l = data.addr_l;
        data_l_in = data.data_l;
        oe_r = io.oe_r;
        we_r = io.we_r;
        addr_r = data.addr_r;
        data_r_in = data.data_r;
        
        fork
          tick_left;
          tick_right;
        join
      end
    end
  end
endmodule