`ifndef BIN2DEC_V
`define BIN2DEC_V
`timescale 1ns / 1ps

module bin2dec (
    input  wire [9:0]  valor,
    output reg  [47:0] msg,
    output reg  [2:0]  len
);
    wire [3:0] d3 = valor / 1000;
    wire [3:0] d2 = (valor / 100) % 10;
    wire [3:0] d1 = (valor / 10)  % 10;
    wire [3:0] d0 = valor % 10;

    wire [7:0] a3 = 8'h30 + d3;
    wire [7:0] a2 = 8'h30 + d2;
    wire [7:0] a1 = 8'h30 + d1;
    wire [7:0] a0 = 8'h30 + d0;

    localparam [7:0] CR = 8'h0D;
    localparam [7:0] LF = 8'h0A;

    always @(*) begin
        if (valor >= 10'd1000) begin
            msg = {LF, CR, a0, a1, a2, a3};
            len = 3'd6;
        end else if (valor >= 10'd100) begin
            msg = {8'h00, LF, CR, a0, a1, a2};
            len = 3'd5;
        end else if (valor >= 10'd10) begin
            msg = {16'h0000, LF, CR, a0, a1};
            len = 3'd4;
        end else begin
            msg = {24'h000000, LF, CR, a0};
            len = 3'd3;
        end
    end
endmodule
`endif
