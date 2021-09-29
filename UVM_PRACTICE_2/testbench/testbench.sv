/* This is a simple UVM testbench 
 * It integrates all the UVM components necesary into on testbench
 * This approach is not very practical, and was done
 * for learning purposes */

import uvm_pkg::*;
`include "uvm_macros.svh"

/* Extending the uvm environment */ 
class env extends uvm_env;

  /* Viritual interface */
  virtual FIFO_if m_if;

  /* The new function allows us to create a new environment. *
   * If not specified it is assumed that there is no parent */
  function new(string name, uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  /* The connect phase connects FIFO_if to m_if virtually */
  function void connect_phase(uvm_phase phase);
    `uvm_info("LABEL", "Started connect phase.", UVM_HIGH);
    /* Get the interface from the resource database. 
     * read_by_name function in uvm_resouce_db# 
     * will locate a resource by 
     * name and scope and read its value */
    assert(uvm_resource_db#(virtual FIFO_if)::read_by_name(
      get_full_name(), "FIFO_if", m_if));
    `uvm_info("LABEL", "Finished connect phase.", UVM_HIGH);
  endfunction: connect_phase

  /* The run phase here contains driver and sequencer. 
  This leads to the DUT being driven with stimuli (i.e. sequence) */
  task run_phase(uvm_phase phase);
    /* Objection is used to communicate among UVM components
     * It is used to determine when the test has ended */
    phase.raise_objection(this);
    `uvm_info("LABEL", "Started run phase.", UVM_HIGH);
    
    begin
      /* These variables are used to drive the DUT */
      bit write_enable, read_enable, rst; 
      int data_in;

      /* Stimuli generation */
      @(m_if.cb);
        m_if.cb.rst <= 1'b1;
        `uvm_info("LABEL", "Doing a reset", UVM_HIGH);
      
      /* Begin Write Phase */
      repeat(6) @(m_if.cb) begin

        /* Stimuli generation */
        write_enable = 1'b1; read_enable = 1'b0; rst = 1'b0; 
        data_in = $urandom_range(0, 255); // 8-bit (could have used rand instead)

        /* driving the DUT */
        m_if.cb.write_enable <= write_enable; m_if.cb.read_enable <= read_enable;
        m_if.cb.rst <= rst; m_if.cb.data_in <= data_in;
        
        /* To monitor */
        `uvm_info(
          "RESULT", 
          $sformatf("Data in is %0d, R/W enable: %0d/%0d and Data out: %0d",
          data_in, read_enable, write_enable, m_if.cb.data_out), UVM_HIGH);
      end /* End Write Phase */

      /* One clock delay */
      repeat(1) @(m_if.cb)

      /* Begin Read Phase */
      repeat(8) @(m_if.cb) begin

        /* Stimuli generation */
        write_enable = 1'b0; read_enable = 1'b1; rst = 1'b0; 
        data_in = $urandom_range(0, 255); // 8-bit (could have used rand instead)

        /* driving the DUT */
        m_if.cb.write_enable <= write_enable; m_if.cb.read_enable <= read_enable;
        m_if.cb.rst <= rst; m_if.cb.data_in <= data_in;
        
        /* To monitor */
        `uvm_info(
          "RESULT", 
          $sformatf("Data in is %0d, R/W enable: %0d/%0d and Data out: %0d",
          data_in, read_enable, write_enable, m_if.cb.data_out), UVM_HIGH);
      end /* End Read Phase */
    end

    /* One clock delay */
      repeat(1) @(m_if.cb)

    `uvm_info("LABEL", "Finished run phase.", UVM_HIGH);
    /* Objection has been dropped, which indicates that activity is over */
    phase.drop_objection(this);
  endtask: run_phase
  
endclass

/* Top Module */
module top;

  bit clk;
  env environment;
  FIFO dut(.clk (clk));

  initial begin
    /* Creating a new environment, env */
    environment = new("env");
    /* Environment added to the resource database */
    uvm_resource_db#(virtual FIFO_if)::set("env",
      "FIFO_if", dut.FIFO_if0);
    clk = 0;
    run_test();
  end
  
  /* Clock */
  initial begin
    forever begin
      #(50) clk = ~clk;
    end
  end
  
  /* Dumping waves */
  initial begin
    /* level 0 - all is dumped */
    $dumpvars(0, top);
  end
  
endmodule