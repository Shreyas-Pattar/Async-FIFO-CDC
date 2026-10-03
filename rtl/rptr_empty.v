`timescale 1ns / 1ps

module rptr_empty #(
    parameter ADDRSIZE = 4
)(
    input  wire                rclk,
    input  wire                rrst_n,
    input  wire                rinc,
    input  wire [ADDRSIZE:0]   rq2_wptr, // Synchronized write Gray pointer
    output reg                 rempty,
    output wire [ADDRSIZE-1:0] raddr,
    output reg  [ADDRSIZE:0]   rptr      // Gray pointer to be sent to write domain
);

    reg  [ADDRSIZE:0] rbin;
    wire [ADDRSIZE:0] rbin_next;
    wire [ADDRSIZE:0] rgray_next;
    wire              rempty_val;

    // Memory read address is the lower bits of the binary pointer
    assign raddr = rbin[ADDRSIZE-1:0];

    // Increment binary counter if read enable is high and FIFO is not empty
    assign rbin_next = rbin + (rinc & ~rempty);

    // Binary to Gray conversion: Bin ^ (Bin >> 1)
    assign rgray_next = rbin_next ^ (rbin_next >> 1);

    // Empty condition check: Gray pointers are identical
    assign rempty_val = (rgray_next == rq2_wptr);

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rbin   <= {(ADDRSIZE+1){1'b0}};
            rptr   <= {(ADDRSIZE+1){1'b0}};
            rempty <= 1'b1; // Empty on reset
        end else begin
            rbin   <= rbin_next;
            rptr   <= rgray_next;
            rempty <= rempty_val;
        end
    end

endmodule