// This is the SystemVerilog interface that we will use to connect
// our design to our UVM testbench.
interface dut_if(
  input clock, 
  input reset,
  input cmd,
  input [7:0] addr,
  input [7:0] data
);

  clocking cb @(posedge clock);
    output reset;
    output cmd;
    output addr;
    output data;
  endclocking
endinterface

`include "uvm_macros.svh"

// This is our design module.
// 
// It is an empty design that simply prints a message whenever
// the clock toggles.
module dut(
  input logic clock0, reset0,
  input logic cmd0,
  input logic [7:0] addr0,
  input logic [7:0] data0
);
  import uvm_pkg::*;
  always @(posedge clock0)
    if (reset0 != 1) begin
      /*
      `uvm_info("DUT",
                $sformatf("Received cmd=%b, addr=0x%2h, data=0x%2h",
                          cmd0, addr0,data0), UVM_MEDIUM)
      */
    end
endmodule

bind dut dut_if dut_if0(
  .clock(clock0),
  .reset(reset0),
  .cmd(cmd0),
  .addr(addr0),
  .data(data0)
);