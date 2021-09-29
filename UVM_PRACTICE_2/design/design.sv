/* Created 2021 by Kåre-Benjamin H Rørvik 
 * This is a simple synchronous FIFO, with asynchronous reset.
 * THIS FIFO WILL OVERWRITE WHEN FULL
 * In the current mode of operation you may only read or write at the same time.
 * (write_enable takes priority of read_enable).
 * The FIFO uses two dedicated pointers one for read and one for write.
 * To store the inputs a [x][y] memory is used.
 * The parameters FIFO_DEPTH and FIFO_W is used to adjust the fifo properties.
 * Where the width defines how wide the input may be, and the depth is the n
 * inputs that may be stored (the depth of the FIFO).
 */
module FIFO (
    input logic clk,
    output logic [7:0] data_out0,
    output logic full0,
    output logic empty0,
    input logic [7:0] data_in0,
    input logic rst0,
    input logic write_enable0,
    input logic read_enable0
);
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
    assign full0 = ((write_pointer == FIFO_DEPTH) & (read_pointer == 3'b000) ? 1'b1 : 1'b0);
    assign empty0 = ((write_pointer == read_pointer) ? 1'b1 : 1'b0);
      
    always @(*) begin
        if (rst0) 
            begin
                data_out0 <= 8'b00000000;
                write_pointer <= 3'b000;
                read_pointer  <= 3'b000;
                    for (int i = 0; i < FIFO_DEPTH; i++) begin
                        memory[i] = 8'b0000_0000;
                    end       
            end 
    end

    always @(posedge clk) begin
        if (write_enable0 & !full0)
            begin
                memory[write_pointer] <= data_in0;
                write_pointer++;
            end
        else if (read_enable0 & !empty0)
            begin
                data_out0 <= memory[read_pointer];
                read_pointer++;
            end
    end
endmodule

/* Interface for the FIFO */

interface FIFO_if(
    input clk,
    input [7:0] data_out, // out
    input full,           // out
    input empty,          // out
    input [7:0] data_in,
    input rst,
    input write_enable,
    input read_enable
);

  clocking cb @(posedge clk);
    input data_out; // out
    input full;           // out
    input empty;          // out
    output data_in;
    output rst;
    output write_enable;
    output read_enable;
  endclocking 

endinterface: FIFO_if

/* Binding the interface */
bind FIFO FIFO_if FIFO_if0(
    .clk(clk),
    .data_out(data_out0),
    .full(full0),
    .empty(empty0),
    .data_in(data_in0),
    .rst(rst0),
    .write_enable(write_enable0),
    .read_enable(read_enable0)
);
