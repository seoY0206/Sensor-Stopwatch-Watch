`timescale 1ns / 1ps


module uart_top (
    input        clk,
    input        rst,
    input        rx,
    input  [7:0] tx_push_data,
    input        pop,
    input        push,
    output       full,
    output       tx,
    output       rx_empty,
    output [7:0] rx_fifo_data
);

    wire w_baud_tick;
    wire rx_done;
    wire [7:0] w_rx_data, w_tx_fifo_popdata;
    wire w_tx_fifo_empty, w_tx_busy;


    uart_tx U_UART_TX (
        .clk(clk),
        .rst(rst),
        .start_trigger(~w_tx_fifo_empty),
        .tx_data(w_tx_fifo_popdata),
        .b_tick(w_baud_tick),
        .tx(tx),
        .tx_busy(w_tx_busy)
    );

    fifo U_TX_FIFO (
        .clk      (clk),
        .rst      (rst),
        .push_data(tx_push_data),       // from data convert
        .push     (push),               // from data convert
        .pop      (~w_tx_busy),         // from uart tx
        .pop_data (w_tx_fifo_popdata),  // to uart tx
        .full     (full),               // to data convert
        .empty    (w_tx_fifo_empty)     // to uart tx
    );

    fifo U_RX_FIFO (
        .clk      (clk),
        .rst      (rst),
        .push_data(w_rx_data),     // from uart rx
        .push     (rx_done),       // from uart rx
        .pop      (pop),           // from commend cu
        .pop_data (rx_fifo_data),  // to commend cu
        .full     (),
        .empty    (rx_empty)       // to commend cu
    );

    uart_rx U_UART_RX (
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .b_tick(w_baud_tick),
        .rx_data(w_rx_data),
        .rx_done(rx_done)
    );

    baud_tick_gen U_BAUD_TICK_GEN (
        .clk(clk),
        .rst(rst),
        .b_tick(w_baud_tick)
    );



endmodule





module baud_tick_gen (
    input  clk,
    input  rst,
    output b_tick
);

    // baudrate
    parameter BAUDRATE = 9600 * 16;
    localparam BAUD_COUNT = 100_000_000 / BAUDRATE;
    reg [$clog2(BAUD_COUNT)-1:0] counter_reg, counter_next;
    reg tick_reg, tick_next;

    //output
    assign b_tick = tick_reg;

    // SL
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            tick_reg <= 0;
        end else begin
            counter_reg <= counter_next;
            tick_reg <= tick_next;
        end
    end

    // next CL
    always @(*) begin
        counter_next = counter_reg;
        tick_next = tick_reg;
        if (counter_reg == BAUD_COUNT - 1) begin
            counter_next = 0;
            tick_next = 1'b1;
        end else begin
            counter_next = counter_reg + 1;
            tick_next = 1'b0;
        end
    end

endmodule
