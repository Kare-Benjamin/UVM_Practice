/* Created 2021 by Kåre-Benjamin H Rørvik 
 * This is a simple synchronous FIFO, with asynchronous reset.
 * THIS FIFO WILL NOT OVERWRITE WHEN FULL
 * In the current mode of operation you may only read or write at the same time.
 * (write_enable takes priority of read_enable).
 * The FIFO uses two dedicated pointers one for read and one for write.
 * To store the inputs a [x][y] memory is used.
 * The parameters FIFO_DEPTH and FIFO_W is used to adjust the fifo properties.
 * Where the width defines how wide the input may be, and the depth is the n
 * inputs that may be stored (the depth of the FIFO).
 */

/* Interface to connect */
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

module dut (dut_if dif);

    parameter FIFO_DEPTH = 8;
    parameter FIFO_W = 8;

    /* Memory for temporary storage of FIFO data */
    logic [FIFO_DEPTH - 1:0] memory [FIFO_W - 1:0];

    /* Gates the circuit from writing */
    logic stop_write;
    logic stop_read;
  
  	/* Pointers */
    logic [$clog2(FIFO_DEPTH) - 1:0] write_pointer;
    logic [$clog2(FIFO_DEPTH) - 1:0] read_pointer;
    
    /* Fifo is full if write_pointer has reached the highest address value
     * or if the read pointer is at 0.
     * FIFO is empty if the two pointers has the same address value */
    assign dif.full = ((write_pointer == FIFO_DEPTH - 1) & ((read_pointer == 3'b000)) ? 1'b1 : 1'b0);
    assign dif.empty = ((write_pointer == read_pointer) ? 1'b1 : 1'b0);

    /* Reset to flush/initialize/clean the FIFO */    
    always @(*) begin
        if (dif.rst) 
            begin
                dif.data_out <= 8'b00000000;
                write_pointer <= 3'b000;
                read_pointer  <= 3'b000;
                stop_write    <= 1'b0;
                stop_read    <= 1'b0;
                    for (int i = 0; i < FIFO_DEPTH; i++) begin
                        memory[i] = 8'b0000_0000;
                    end       
            end 
    end
    /* Read/Write stage */
    always @(posedge dif.clk) begin
        /* Write takes priority over write */

        /* 3-step strategy to prevent bad systemstates 
         * This is not ideal for HW implementation and 
         * is strictly for debuggin purposes*/
        
        /* If a stop_write has taken place, start pointer from 0 again
         * also dissable stop_write */
        if (dif.write_enable & !dif.full & stop_write)
            begin
                write_pointer = 0;
                memory[write_pointer] <= dif.data_in;
                write_pointer++;
                stop_write <= 1'b0;
            end
        /* This is the standard write operation */
        else if (dif.write_enable & !dif.full & !stop_write)
            begin
                memory[write_pointer] <= dif.data_in;
                write_pointer++;
            end
        /* When write_pointer reaches 3'b111 it would otherwise overflow
        *  we will leave it at 3'b111 and write the last value 
        *  set stop_write so that no further write happens until 
        *  FIFO is no longer full */ 
        else if (dif.write_enable & dif.full & !stop_write)
            begin
                memory[write_pointer] <= dif.data_in;
                stop_write <= 1'b1;
            end

        /* Read stage */

        /* Same 3-step strategy to prevent bad systemstates 
         * This is not ideal for HW implementation and 
         * is strictly for debuggin purposes*/
        else if (dif.read_enable & !dif.empty & stop_read)
            begin
                read_pointer = 0;
                dif.data_out <= memory[read_pointer];
                read_pointer++;
                stop_read <= 1'b0;
            end
        else if (dif.read_enable & !dif.empty & !stop_read)
            begin
                dif.data_out <= memory[read_pointer];
                read_pointer++;
                stop_read <= 1'b0;
            end
        else if (dif.read_enable & dif.empty & !stop_read)
            begin
                dif.data_out <= memory[read_pointer];
                stop_read <= 1'b1;
            end
    end
endmodule