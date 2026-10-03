`timescale 1ns / 1ps

module sync_flop #(
    parameter ADDRSIZE = 4
)(
    input  wire                clk,
    input  wire                rst_n,
    input  wire [ADDRSIZE:0]   async_in,
    output reg  [ADDRSIZE:0]   sync_out
);

    // Intermediate register to resolve metastability
    reg [ADDRSIZE:0] q1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q1       <= {(ADDRSIZE+1){1'b0}};
            sync_out <= {(ADDRSIZE+1){1'b0}};
        end else begin
            q1       <= async_in;
            sync_out <= q1;
        end
    end

endmodule