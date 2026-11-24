`ifndef DEC2BIN_V
`define DEC2BIN_V
`timescale 1ns / 1ps

module dec2bin (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       rx_valid,
    input  wire [7:0] rx_data,
    output reg  [9:0] valor,
    output reg        valor_ok,     // pulso: valor nuevo
    output reg        overflow      // pulso: numero > 1023 descartado
);
    reg [13:0] acc;       // hasta 1023*10+9 = 10239 cabe en 14 bits
    reg        hay_dig;
    reg        desb;

    wire es_digito = (rx_data >= 8'h30) && (rx_data <= 8'h39);
    wire es_enter  = (rx_data == 8'h0D) || (rx_data == 8'h0A);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc      <= 14'd0;
            hay_dig  <= 1'b0;
            desb     <= 1'b0;
            valor    <= 10'd0;
            valor_ok <= 1'b0;
            overflow <= 1'b0;
        end else begin
            valor_ok <= 1'b0;
            overflow <= 1'b0;

            if (rx_valid) begin
                if (es_digito) begin
                    hay_dig <= 1'b1;
                    if (!desb) begin
                        if (acc * 10 + (rx_data - 8'h30) > 14'd1023)
                            desb <= 1'b1;
                        else
                            acc <= acc * 10 + (rx_data - 8'h30);
                    end
                end else if (es_enter && hay_dig) begin
                    if (desb)
                        overflow <= 1'b1;
                    else begin
                        valor    <= acc[9:0];
                        valor_ok <= 1'b1;
                    end
                    acc     <= 14'd0;
                    hay_dig <= 1'b0;
                    desb    <= 1'b0;
                end
            end
        end
    end
endmodule
`endif
