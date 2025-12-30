`timescale 1ns / 1ps


module sender (
    input         clk,
    input         rst,
    input  [ 6:0] sw_msec,
    input  [ 5:0] sw_sec,
    input  [ 5:0] sw_min,
    input  [ 4:0] sw_hour,
    input  [ 6:0] w_msec,
    input  [ 5:0] w_sec,
    input  [ 5:0] w_min,
    input  [ 4:0] w_hour,
    input  [11:0] sr04_dist,
    input  [15:0] dht11_humidity,
    input  [15:0] dht11_temperature,
    input         sw_start_trig,
    input         sw_stop_trig,
    input         sw_clear_trig,
    input         sw_save_trig,
    input         w_time_trig,
    input         sr04_dist_trig,
    input         dht11_trig,
    input         full,
    output        push,
    output [ 7:0] o_data
);
    wire start_trig;
    wire [63:0] w_data;

    data_convert U_DATA_CONVERT (
        .clk(clk),
        .rst(rst),
        .start(start_trig),
        .i_data(w_data),
        .full(full),
        .push(push),
        .o_data(o_data)
    );

    sender_dp U_SENDER_DP (
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
        .sr04_dist(sr04_dist),
        .dht11_humidity(dht11_humidity),
        .dht11_temperature(dht11_temperature),
        .sw_start_trig(sw_start_trig),
        .sw_stop_trig(sw_stop_trig),
        .sw_clear_trig(sw_clear_trig),
        .sw_save_trig(sw_save_trig),
        .w_time_trig(w_time_trig),
        .sr04_dist_trig(sr04_dist_trig),
        .dht11_trig(dht11_trig),
        .o_trig(start_trig),
        .o_data(w_data)
    );
endmodule
