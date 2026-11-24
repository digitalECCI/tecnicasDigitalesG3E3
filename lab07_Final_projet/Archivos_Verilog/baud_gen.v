`ifndef BAUD_GEN_V
`define BAUD_GEN_V
`timescale 1ns / 1ps

module baud_gen #(
    parameter CLK_DIV = 326
)(
    input  wire clk,
    input  wire rst_n,
    output reg  tick16
);
    reg [15:0] cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt    <= 16'd0;
            tick16 <= 1'b0;
        end else if (cnt == CLK_DIV - 1) begin
            cnt    <= 16'd0;
            tick16 <= 1'b1;
        end else begin
            cnt    <= cnt + 1'b1;
            tick16 <= 1'b0;
        end
    end
endmodule
`endif
