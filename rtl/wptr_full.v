`timescale 1ns / 1ps

module wptr_full #(
    parameter ADDRSIZE = 4
)(
    input  wire                wclk,
    input  wire                wrst_n,
    input  wire                winc,
    input  wire [ADDRSIZE:0]   wq2_rptr, // Synchronized read Gray pointer
    output reg                 wfull,
    output wire [ADDRSIZE-1:0] waddr,
    output reg  [ADDRSIZE:0]   wptr      // Gray pointer to be sent to read domain
);

    reg  [ADDRSIZE:0] wbin;
    wire [ADDRSIZE:0] wbin_next;
    wire [ADDRSIZE:0] wgray_next;
    wire              wfull_val;

    // Memory write address is the lower bits of the binary pointer
    assign waddr = wbin[ADDRSIZE-1:0];

    // Increment binary counter if write enable is high and FIFO is not full
    assign wbin_next = wbin + (winc & ~wfull);

    // Binary to Gray conversion: Bin ^ (Bin >> 1)
    assign wgray_next = wbin_next ^ (wbin_next >> 1);

    // Full condition check:
    // MSB inverted, 2nd MSB inverted, lower bits identical
    assign wfull_val = (wgray_next == {~wq2_rptr[ADDRSIZE:ADDRSIZE-1], wq2_rptr[ADDRSIZE-2:0]});

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wbin  <= {(ADDRSIZE+1){1'b0}};
            wptr  <= {(ADDRSIZE+1){1'b0}};
            wfull <= 1'b0;
        end else begin
            wbin  <= wbin_next;
            wptr  <= wgray_next;
            wfull <= wfull_val;
        end
    end

endmodule