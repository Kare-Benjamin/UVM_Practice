// This is the SystemVerilog interface that we will use to connect
// our design to our UVM testbench.
interface dut_if;
    logic clk;
    logic [7:0] data_out;
    logic full;
    logic empty;
    logic [7:0] data_in;
    logic rst;
    logic write_enable;
    logic read_enable;
endinterface

`include "uvm_macros.svh"

// This is our design module.
// 
// It is an empty design that simply prints a message whenever
// the clock toggles.

module dut (dut_if dif);
    parameter FIFO_DEPTH = 8;
    parameter FIFO_W = 8;

    /* Memory for temporary storage of FIFO data */
    logic [FIFO_DEPTH - 1:0] memory [FIFO_W - 1:0];
  
  	/* Pointers */
  	logic [$clog2(FIFO_DEPTH) - 1:0] write_pointer;
  	logic [$clog2(FIFO_DEPTH) - 1:0] read_pointer;
    
    /* Fifo is full if write_pointer has reached the highest address value
     * or if the read pointer is at 0? (strange) 
     * FIFO is empty if the two pointers has the same address value */
    assign dif.full = ((write_pointer == FIFO_DEPTH) & (read_pointer == 3'b000) ? 1'b1 : 1'b0);
    assign dif.empty = ((write_pointer == read_pointer) ? 1'b1 : 1'b0);
      
    always @(*) begin
        if (dif.rst) 
            begin
                dif.data_out <= 8'b00000000;
                write_pointer <= 3'b000;
                read_pointer  <= 3'b000;
                    for (int i = 0; i < FIFO_DEPTH; i++) begin
                        memory[i] = 8'b0000_0000;
                    end       
            end 
    end

    always @(posedge dif.clk) begin
        if (dif.write_enable & !dif.full)
            begin
                memory[write_pointer] <= dif.data_in;
                write_pointer++;
            end
        else if (dif.read_enable & !dif.empty)
            begin
                dif.data_out <= memory[read_pointer];
                read_pointer++;
            end
    end
endmodule
