`timescale 1ns / 1ps


module watch_cu (
    input clk,
    input rst,
    input i_time_up,
    input i_time_down,
    input i_digit_right,
    input i_digit_left,
    output reg o_sec_up,
    output reg o_sec_down,
    output reg o_min_up,
    output reg o_min_down,
    output reg o_hour_up,
    output reg o_hour_down
);

    // state define
    parameter SEC = 2'b01, MIN = 2'b10, HOUR = 2'b11;
    reg [1:0] c_state, n_state;

    // state register SL
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= SEC;
        end else begin
            c_state <= n_state;
        end
    end

    // next combinational logic
    always @(*) begin
        n_state     = c_state;
        o_sec_up    = 1'b0;
        o_sec_down  = 1'b0;
        o_min_up    = 1'b0;
        o_min_down  = 1'b0;
        o_hour_up   = 1'b0;
        o_hour_down = 1'b0;
        case (c_state)
            SEC: begin
                // up/down
                if (i_time_up) begin
                    o_sec_up = 1'b1;
                end else if (i_time_down) begin
                    o_sec_down = 1'b1;
                end
                // next state
                if (i_digit_right) begin
                    n_state = MIN;
                end else if (i_digit_left) begin
                    n_state = HOUR;
                end
            end
            MIN: begin
                if (i_time_up) begin
                    o_min_up = 1'b1;
                end else if (i_time_down) begin
                    o_min_down = 1'b1;
                end
                if (i_digit_right) begin
                    n_state = HOUR;
                end else if (i_digit_left) begin
                    n_state = SEC;
                end
            end
            HOUR: begin
                if (i_time_up) begin
                    o_hour_up = 1'b1;
                end else if (i_time_down) begin
                    o_hour_down = 1'b1;
                end
                if (i_digit_right) begin
                    n_state = SEC;
                end else if (i_digit_left) begin
                    n_state = MIN;
                end
            end
            default : n_state = SEC;
        endcase
    end

endmodule

