`timescale 1ns / 1ps

module async_fifo #(
    parameter DSIZE = 8,
    parameter ASIZE = 4
)(
    // Write Domain
    input  wire             wclk,
    input  wire             wrst_n,
    input  wire             winc,
    input  wire [DSIZE-1:0] wdata,
    output wire             wfull,

    // Read Domain
    input  wire             rclk,
    input  wire             rrst_n,
    input  wire             rinc,
    output wire [DSIZE-1:0] rdata,
    output wire             rempty
);

    wire [ASIZE-1:0] waddr, raddr;
    wire [ASIZE:0]   wptr, rptr;
    wire [ASIZE:0]   wq2_rptr, rq2_wptr;

    // Dual-stage sync from Read to Write domain
    sync_flop #(.ADDRSIZE(ASIZE)) sync_r2w (
        .clk      (wclk),
        .rst_n    (wrst_n),
        .async_in (rptr),
        .sync_out (wq2_rptr)
    );

    // Dual-stage sync from Write to Read domain
    sync_flop #(.ADDRSIZE(ASIZE)) sync_w2r (
        .clk      (rclk),
        .rst_n    (rrst_n),
        .async_in (wptr),
        .sync_out (rq2_wptr)
    );

    // Dual-port SRAM storage
    fifo_mem #(.DATASIZE(DSIZE), .ADDRSIZE(ASIZE)) mem (
        .wclk   (wclk),
        .wclken (winc),
        .waddr  (waddr),
        .wdata  (wdata),
        .wfull  (wfull),
        .raddr  (raddr),
        .rdata  (rdata)
    );

    // Read pointer and empty generation
    rptr_empty #(.ADDRSIZE(ASIZE)) rptr_inst (
        .rclk     (rclk),
        .rrst_n   (rrst_n),
        .rinc     (rinc),
        .rq2_wptr (rq2_wptr),
        .rempty   (rempty),
        .raddr    (raddr),
        .rptr     (rptr)
    );

    // Write pointer and full generation
    wptr_full #(.ADDRSIZE(ASIZE)) wptr_inst (
        .wclk     (wclk),
        .wrst_n   (wrst_n),
        .winc     (winc),
        .wq2_rptr (wq2_rptr),
        .wfull    (wfull),
        .waddr    (waddr),
        .wptr     (wptr)
    );

endmodule
