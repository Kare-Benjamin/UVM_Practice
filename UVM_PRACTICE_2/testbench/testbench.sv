import uvm_pkg::*;
`include "uvm_macros.svh"

//----------------
// environment env
//----------------
class env extends uvm_env;

  virtual add_sub_if m_if;

  function new(string name, uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  function void connect_phase(uvm_phase phase);
    `uvm_info("LABEL", "Started connect phase.", UVM_HIGH);
    // Get the interface from the resource database.
    assert(uvm_resource_db#(virtual add_sub_if)::read_by_name(
      get_full_name(), "add_sub_if", m_if));
    `uvm_info("LABEL", "Finished connect phase.", UVM_HIGH);
  endfunction: connect_phase

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info("LABEL", "Started run phase.", UVM_HIGH);
    /*
    rand int a;
    rand int b;
    constraint a {a >= 0; a < 255;} // 8-bit
    constraint b {b >= 0; b < 255;} // 8-bit
    */
    begin 
      @(m_if.cb);
        m_if.cb.rst <= 1'b1;
      repeat(2) @(m_if.cb);
    end

    begin
      int data_in = $urandom_range(0, 255);
      bit rst = 1'b0;
      bit write_enable = 1'b1;
      bit read_enable = 1'b0;
      @(m_if.cb);
        m_if.cb.data_in <= $urandom_range(0, 255);
        m_if.cb.rst <= rst;
        m_if.cb.write_enable <= write_enable;
        m_if.cb.read_enable <= read_enable;
        //m_if.cb.doAdd <= 1'b1;
      repeat(6) @(m_if.cb);

      @(m_if.cb);
        m_if.cb.read_enable <= 1'b1;
      	m_if.cb.write_enable <= 1'b0;
      repeat(6) @(m_if.cb);

      `uvm_info(
        "RESULT", 
        $sformatf("Data in is %0d, R/W enable: %0d/%0d and Data out: %0d",
        data_in, read_enable, write_enable, m_if.cb.data_out), UVM_HIGH);
    end

    `uvm_info("LABEL", "Finished run phase.", UVM_HIGH);
    phase.drop_objection(this);
  endtask: run_phase
  
endclass

//-----------
// module top
//-----------
module top;

  bit clk;
  env environment;
  ADD_SUB dut(.clk (clk));

  initial begin
    environment = new("env");
    // Put the interface into the resource database.
    uvm_resource_db#(virtual add_sub_if)::set("env",
      "add_sub_if", dut.add_sub_if0);
    clk = 0;
    run_test();
  end
  
  initial begin
    forever begin
      #(50) clk = ~clk;
    end
  end
  
  initial begin
    // Dump waves
    $dumpvars(0, top);
  end
  
endmodule