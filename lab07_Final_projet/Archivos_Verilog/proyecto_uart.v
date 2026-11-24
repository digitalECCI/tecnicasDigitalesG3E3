`ifndef PROYECTO_UART_V
`define PROYECTO_UART_V
`timescale 1ns / 1ps

`include "baud_gen.v"
`include "uart_tx.v"
`include "uart_rx.v"
`include "bin2dec.v"
`include "dec2bin.v"

// proyecto_uart.v  -  Modulo superior (DE10-Lite)
//  FPGA -> PC : SW9..SW0 + KEY0  -> texto decimal por GPIO_TX
//  PC -> FPGA : texto decimal + Enter por GPIO_RX -> binario en LEDR9..LEDR0
module proyecto_uart #(
    parameter CLK_DIV      = 326,      // 50 MHz / (16*326) ~ 9600 baud
    parameter DEBOUNCE_MAX = 499999    // 10 ms a 50 MHz
)(
    input  wire       MAX10_CLK1_50,
    input  wire       KEY0,            // enviar (activo en bajo)
    input  wire       KEY1,            // reset  (activo en bajo)
    input  wire [9:0] SW,
    output wire [9:0] LEDR,
    output wire       GPIO_TX,
    input  wire       GPIO_RX
);
    wire clk   = MAX10_CLK1_50;
    wire rst_n = KEY1;

    //--------------------------------------------------
    // Sincronizacion de entradas asincronas (2 FF)
    //--------------------------------------------------
    reg [9:0] sw_s1, sw_s2;
    reg       rx_s1, rx_s2;
    reg       k_s1,  k_s2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sw_s1 <= 10'd0; sw_s2 <= 10'd0;
            rx_s1 <= 1'b1;  rx_s2 <= 1'b1;
            k_s1  <= 1'b1;  k_s2  <= 1'b1;
        end else begin
            sw_s1 <= SW;        sw_s2 <= sw_s1;
            rx_s1 <= GPIO_RX;   rx_s2 <= rx_s1;
            k_s1  <= KEY0;      k_s2  <= k_s1;
        end
    end

    //--------------------------------------------------
    // Antirrebote de KEY0 + deteccion de flanco (1 pulso por pulsacion)
    //--------------------------------------------------
    reg [19:0] dc;
    reg        k_stable;
    reg        press;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dc       <= 20'd0;
            k_stable <= 1'b1;
            press    <= 1'b0;
        end else begin
            press <= 1'b0;
            if (k_s2 == k_stable)
                dc <= 20'd0;
            else if (dc < DEBOUNCE_MAX)
                dc <= dc + 1'b1;
            else begin
                k_stable <= k_s2;
                dc       <= 20'd0;
                if (k_s2 == 1'b0)
                    press <= 1'b1;
            end
        end
    end

    //--------------------------------------------------
    // Generador de baudios
    //--------------------------------------------------
    wire tick16;
    baud_gen #(.CLK_DIV(CLK_DIV)) u_baud (
        .clk(clk), .rst_n(rst_n), .tick16(tick16)
    );

    //--------------------------------------------------
    // Sentido FPGA -> PC
    //--------------------------------------------------
    reg  [9:0]  sw_lat;
    wire [47:0] msg;
    wire [2:0]  len;
    bin2dec u_b2d (.valor(sw_lat), .msg(msg), .len(len));

    wire       tx_busy;
    wire       tx_start;
    wire [7:0] tx_data;

    localparam T_IDLE = 2'd0;
    localparam T_LOAD = 2'd1;
    localparam T_SEND = 2'd2;
    localparam T_WAIT = 2'd3;

    reg [1:0] tstate;
    reg [2:0] idx;

    assign tx_start = (tstate == T_SEND) && !tx_busy;
    assign tx_data  = msg[8*idx +: 8];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tstate <= T_IDLE;
            idx    <= 3'd0;
            sw_lat <= 10'd0;
        end else begin
            case (tstate)
                T_IDLE: if (press) begin
                    sw_lat <= sw_s2;       // congelar el valor de los switches
                    idx    <= 3'd0;
                    tstate <= T_LOAD;
                end
                T_LOAD: tstate <= T_SEND;  // deja asentar bin2dec
                T_SEND: if (!tx_busy) tstate <= T_WAIT;
                T_WAIT: if (!tx_busy) begin
                    if (idx == len - 1'b1)
                        tstate <= T_IDLE;
                    else begin
                        idx    <= idx + 1'b1;
                        tstate <= T_SEND;
                    end
                end
            endcase
        end
    end

    uart_tx u_tx (
        .clk(clk), .rst_n(rst_n), .tick16(tick16),
        .start(tx_start), .data(tx_data),
        .tx(GPIO_TX), .busy(tx_busy)
    );

    //--------------------------------------------------
    // Sentido PC -> FPGA
    //--------------------------------------------------
    wire [7:0] rx_data;
    wire       rx_valid, rx_ferr;

    uart_rx u_rx (
        .clk(clk), .rst_n(rst_n), .tick16(tick16),
        .rx(rx_s2),
        .data(rx_data), .valid(rx_valid), .frame_err(rx_ferr)
    );

    wire [9:0] valor_rx;
    wire       valor_ok, desbordado;

    dec2bin u_d2b (
        .clk(clk), .rst_n(rst_n),
        .rx_valid(rx_valid), .rx_data(rx_data),
        .valor(valor_rx), .valor_ok(valor_ok), .overflow(desbordado)
    );

    reg [9:0] leds;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)         leds <= 10'd0;
        else if (valor_ok)  leds <= valor_rx;
    end

    assign LEDR = leds;
endmodule
`endif
