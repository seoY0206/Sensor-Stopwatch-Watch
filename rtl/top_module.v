`timescale 1ns / 1ps


module top_module (
    input        clk,
    input        rst,
    input        rx,
    input  [2:0] sw,
    input        btnU,
    input        btnL,
    input        btnR,
    input        btnD,
    input        echo,      // sr04
    output       trig,      // sr04
    output       tx,
    output [3:0] fnd_com,
    output [7:0] fnd_data,
    output       led,
    inout        dht_io     // dht11
);

    parameter L = 0, R = 1, U = 2, D = 3;

    wire [7:0] w_rx_data, w_send_data;
    wire w_tx_push, w_tx_full, w_rx_empty, w_rx_pop;
    wire w_sr04, w_dht11;
    wire [3:0] o_stopwatch, o_watch;
    wire [ 1:0] w_mode;
    wire [11:0] dist_data;
    wire [15:0] dht11_humidity, dht11_temperature;
    wire sw_start_trig, sw_stop_trig, sw_clear_trig, sw_save_trig, w_time_trig, sr04_done, dht11_done;

    wire [6:0] w_msec, sw_msec;
    wire [5:0] w_sec, sw_sec;
    wire [5:0] w_min, sw_min;
    wire [4:0] w_hour, sw_hour;


    uart_top U_UART (
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .tx_push_data(w_send_data),
        .pop(w_rx_pop),
        .push(w_tx_push),
        .full(w_tx_full),
        .tx(tx),
        .rx_empty(w_rx_empty),
        .rx_fifo_data(w_rx_data)
    );


    commend_cu U_COMMEND_CU (
        .clk(clk),
        .rst(rst),
        .sw(sw[2:1]),
        .btn({btnD, btnU, btnR, btnL}),
        .fifo_data(w_rx_data),
        .rx_trigger(w_rx_empty),
        .o_mode(w_mode),
        .pop(w_rx_pop),
        .o_event_time(w_time_trig),
        .o_stopwatch(o_stopwatch),
        .o_watch(o_watch),
        .o_sr04(w_sr04),
        .o_dht11(w_dht11)
    );

    dht11_control_unit U_DHT11 (
        .clk(clk),
        .rst(rst),
        .i_start(w_dht11),
        .o_valid(led),
        .humidity(dht11_humidity),
        .temperature(dht11_temperature),
        .o_trig(dht11_done),
        .dht_io(dht_io)
    );

    sr04_controller U_SR04 (
        .clk(clk),
        .rst(rst),
        .start(w_sr04),
        .echo(echo),
        .o_done(sr04_done),
        .o_trig(trig),
        .o_dist(dist_data)
    );

    stopwatch U_SW (
        .clk(clk),
        .rst(rst),
        .i_btn(o_stopwatch),
        .msec(sw_msec),
        .sec(sw_sec),
        .min(sw_min),
        .hour(sw_hour),
        .o_event_start(sw_start_trig),
        .o_event_stop(sw_stop_trig),
        .o_event_clear(sw_clear_trig),
        .o_event_save(sw_save_trig)
    );

    watch U_W (
        .clk  (clk),
        .rst  (rst),
        .i_btn(o_watch),
        .msec (w_msec),
        .sec  (w_sec),
        .min  (w_min),
        .hour (w_hour)
    );


    sender U_SENDER (
        .clk(clk),
        .rst(rst),
        .sw_msec(sw_msec),
        .sw_sec(sw_sec),
        .sw_min(sw_min),
        .sw_hour(sw_hour),
        .w_msec(w_msec),
        .w_sec(w_sec),
        .w_min(w_min),
        .w_hour(w_hour),
        .sr04_dist(dist_data),
        .dht11_humidity(dht11_humidity),
        .dht11_temperature(dht11_temperature),
        .sw_start_trig(sw_start_trig),
        .sw_stop_trig(sw_stop_trig),
        .sw_clear_trig(sw_clear_trig),
        .sw_save_trig(sw_save_trig),
        .w_time_trig(w_time_trig),
        .sr04_dist_trig(sr04_done),
        .dht11_trig(dht11_done),
        .full(w_tx_full),
        .push(w_tx_push),
        .o_data(w_send_data)
    );

    

    fnd_controller U_FND_CTRL (
        .clk(clk),
        .rst(rst),
        .mode({w_mode, sw[0]}),
        .i_stopwatch({sw_hour, sw_min, sw_sec, sw_msec}),
        .i_watch({w_hour, w_min, w_sec, w_msec}),
        .i_sr04(dist_data),
        .i_dht11({dht11_humidity, dht11_temperature}),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data)
    );



endmodule
