`timescale 1ns / 1ps

module fifo_mem #(
    parameter DATASIZE = 8,  // Data bus width
    parameter ADDRSIZE = 4   // Depth = 2^ADDRSIZE (16 entries)
)(
    input  wire                wclk,
    input  wire                wclken,
    input  wire [ADDRSIZE-1:0] waddr,
    input  wire [DATASIZE-1:0] wdata,
    input  wire                wfull,
    input  wire [ADDRSIZE-1:0] raddr,
    output wire [DATASIZE-1:0] rdata
);

    localparam DEPTH = 1 << ADDRSIZE;

    // RAM array declaration
    reg [DATASIZE-1:0] mem [0:DEPTH-1];

    // Synchronous write (only when enabled and not full)
    always @(posedge wclk) begin
        if (wclken && !wfull) begin
            mem[waddr] <= wdata;
        end
    end

    // Asynchronous read output
    assign rdata = mem[raddr];

endmodule