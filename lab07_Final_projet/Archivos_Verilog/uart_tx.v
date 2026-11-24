`ifndef UART_TX_V
`define UART_TX_V
`timescale 1ns / 1ps

module uart_tx (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       tick16,   // 16 ticks = 1 bit
    input  wire       start,
    input  wire [7:0] data,
    output reg        tx,
    output reg        busy
);
    localparam S_IDLE  = 3'd0;
    localparam S_SYNC  = 3'd1;   // espera un tick para alinear el start bit
    localparam S_START = 3'd2;
    localparam S_DATA  = 3'd3;
    localparam S_STOP  = 3'd4;

    reg [2:0] state;
    reg [3:0] cnt;      // 0..15 ticks dentro de un bit
    reg [2:0] bitn;     // bit de dato actual
    reg [7:0] sh;       // registro de desplazamiento

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            tx    <= 1'b1;
            busy  <= 1'b0;
            cnt   <= 4'd0;
            bitn  <= 3'd0;
            sh    <= 8'd0;
        end else begin
            case (state)

                S_IDLE: begin
                    tx <= 1'b1;
                    if (start) begin
                        sh    <= data;
                        busy  <= 1'b1;
                        state <= S_SYNC;
                    end
                end

                S_SYNC: begin
                    if (tick16) begin
                        tx    <= 1'b0;          // bit de start
                        cnt   <= 4'd0;
                        state <= S_START;
                    end
                end

                S_START: begin
                    if (tick16) begin
                        if (cnt == 4'd15) begin
                            cnt   <= 4'd0;
                            tx    <= sh[0];     // D0
                            sh    <= {1'b0, sh[7:1]};
                            bitn  <= 3'd0;
                            state <= S_DATA;
                        end else
                            cnt <= cnt + 1'b1;
                    end
                end

                S_DATA: begin
                    if (tick16) begin
                        if (cnt == 4'd15) begin
                            cnt <= 4'd0;
                            if (bitn == 3'd7) begin
                                tx    <= 1'b1;  // bit de stop
                                state <= S_STOP;
                            end else begin
                                tx   <= sh[0];
                                sh   <= {1'b0, sh[7:1]};
                                bitn <= bitn + 1'b1;
                            end
                        end else
                            cnt <= cnt + 1'b1;
                    end
                end

                S_STOP: begin
                    if (tick16) begin
                        if (cnt == 4'd15) begin
                            busy  <= 1'b0;
                            state <= S_IDLE;
                        end else
                            cnt <= cnt + 1'b1;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end
endmodule
`endif
