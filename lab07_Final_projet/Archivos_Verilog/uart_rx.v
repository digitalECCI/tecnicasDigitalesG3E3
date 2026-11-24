`ifndef UART_RX_V
`define UART_RX_V
`timescale 1ns / 1ps

module uart_rx (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       tick16,
    input  wire       rx,
    output reg  [7:0] data,
    output reg        valid,       // pulso de 1 ciclo: byte correcto
    output reg        frame_err    // pulso de 1 ciclo: stop invalido
);
    localparam S_IDLE  = 2'd0;
    localparam S_START = 2'd1;
    localparam S_DATA  = 2'd2;
    localparam S_STOP  = 2'd3;

    reg [1:0] state;
    reg [3:0] cnt;
    reg [2:0] bitn;
    reg [7:0] sh;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= S_IDLE;
            cnt       <= 4'd0;
            bitn      <= 3'd0;
            sh        <= 8'd0;
            data      <= 8'd0;
            valid     <= 1'b0;
            frame_err <= 1'b0;
        end else begin
            valid     <= 1'b0;
            frame_err <= 1'b0;

            case (state)

                S_IDLE: begin
                    if (rx == 1'b0) begin       // flanco de bajada: posible start
                        cnt   <= 4'd0;
                        state <= S_START;
                    end
                end

                // Esperar medio bit (8 ticks) y confirmar que sigue en 0
                S_START: begin
                    if (tick16) begin
                        if (cnt == 4'd7) begin
                            if (rx == 1'b0) begin
                                cnt   <= 4'd0;
                                bitn  <= 3'd0;
                                state <= S_DATA;
                            end else
                                state <= S_IDLE;     // falso start (ruido)
                        end else
                            cnt <= cnt + 1'b1;
                    end
                end

                // Muestrear cada 16 ticks (centro de cada bit)
                S_DATA: begin
                    if (tick16) begin
                        if (cnt == 4'd15) begin
                            cnt <= 4'd0;
                            sh  <= {rx, sh[7:1]};    // LSB llega primero
                            if (bitn == 3'd7)
                                state <= S_STOP;
                            else
                                bitn <= bitn + 1'b1;
                        end else
                            cnt <= cnt + 1'b1;
                    end
                end

                S_STOP: begin
                    if (tick16) begin
                        if (cnt == 4'd15) begin
                            if (rx == 1'b1) begin
                                data  <= sh;
                                valid <= 1'b1;
                            end else
                                frame_err <= 1'b1;
                            state <= S_IDLE;
                        end else
                            cnt <= cnt + 1'b1;
                    end
                end
            endcase
        end
    end
endmodule
`endif
