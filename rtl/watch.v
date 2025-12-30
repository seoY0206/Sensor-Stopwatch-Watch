`timescale 1ns / 1ps

module watch (
    input        clk,
    input        rst,
    input  [3:0] i_btn,
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour
);

    parameter L = 0, R = 1, U = 2, D = 3;


    wire w_sec_up, w_sec_down;
    wire w_min_up, w_min_down;
    wire w_hour_up, w_hour_down;

    watch_cu U_W_CU (
        .clk(clk),
        .rst(rst),
        .i_time_up(i_btn[U]),
        .i_time_down(i_btn[D]),
        .i_digit_right(i_btn[R]),
        .i_digit_left(i_btn[L]),
        .o_sec_up(w_sec_up),
        .o_sec_down(w_sec_down),
        .o_min_up(w_min_up),
        .o_min_down(w_min_down),
        .o_hour_up(w_hour_up),
        .o_hour_down(w_hour_down)
    );

    watch_dp U_W_DP (
        .clk(clk),
        .rst(rst),
        .i_sec_up(w_sec_up),
        .i_sec_down(w_sec_down),
        .i_min_up(w_min_up),
        .i_min_down(w_min_down),
        .i_hour_up(w_hour_up),
        .i_hour_down(w_hour_down),
        .msec(msec),
        .sec(sec),
        .min(min),
        .hour(hour)
    );

endmodule
