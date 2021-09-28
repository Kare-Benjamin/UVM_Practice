class my_driver extends uvm_driver #(my_transaction);

  `uvm_component_utils(my_driver)

  virtual dut_if dut_vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    // Get interface reference from config database
    if(!uvm_config_db#(virtual dut_if)::get(this, "", "dut_vif", dut_vif)) begin
      `uvm_error("", "uvm_config_db::get failed")
    end
  endfunction 

  task run_phase(uvm_phase phase);
    // First toggle reset
    dut_vif.rst = 1;
    @(posedge dut_vif.clk);
    #1;
    dut_vif.rst = 0;
    
    // Now drive normal traffic
    forever begin
      seq_item_port.get_next_item(req);

      // Wiggle pins of DUT
      dut_vif.data_in  = req.data_in;
      dut_vif.read_enable = req.read_enable;
      dut_vif.write_enable = req.write_enable;
      @(posedge dut_vif.clk);

      seq_item_port.item_done();
    end
  endtask

endclass: my_driver
