`timescale 1ns / 1ps

module watch_dp (
    input        clk,
    input        rst,
    input        i_sec_up,
    input        i_sec_down,
    input        i_min_up,
    input        i_min_down,
    input        i_hour_up,
    input        i_hour_down,
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour
);

    wire w_tick_100hz;
    wire w_sec_tick_up, w_min_tick_up, w_hour_tick_up;
    wire w_min_tick_down, w_hour_tick_down;

    // hour
    watch_time_counter #(
        .BIT_WIDTH  (5),
        .TIME_COUNT (24),
        .RESET_VALUE(12)
    ) U_W_HOUR_COUNTER (
        .clk(clk),
        .rst(rst),
        .i_tick(w_hour_tick_up),
        .i_time_up(i_hour_up),
        .i_time_down(i_hour_down|w_hour_tick_down),
        .o_time(hour),
        .o_carry_up(),
        .o_borrow_down()
    );

    // minute
    watch_time_counter #(
        .BIT_WIDTH  (6),
        .TIME_COUNT (60),
        .RESET_VALUE(0)
    ) U_W_MIN_COUNTER (
        .clk(clk),
        .rst(rst),
        .i_tick(w_min_tick_up),
        .i_time_up(i_min_up),
        .i_time_down(i_min_down|w_min_tick_down),
        .o_time(min),
        .o_carry_up(w_hour_tick_up),
        .o_borrow_down(w_hour_tick_down)
    );

    // second
    watch_time_counter #(
        .BIT_WIDTH  (6),
        .TIME_COUNT (60),
        .RESET_VALUE(0)
    ) U_W_SEC_COUNTER (
        .clk(clk),
        .rst(rst),
        .i_tick(w_sec_tick_up),
        .i_time_up(i_sec_up),
        .i_time_down(i_sec_down),
        .o_time(sec),
        .o_carry_up(w_min_tick_up),
        .o_borrow_down(w_min_tick_down)
    );

    // milisecond
    watch_time_counter #(
        .BIT_WIDTH  (7),
        .TIME_COUNT (100),
        .RESET_VALUE(0)
    ) U_W_MSEC_COUNTER (
        .clk(clk),
        .rst(rst),
        .i_tick(w_tick_100hz),
        .i_time_up(1'b0),
        .i_time_down(1'b0),
        .o_time(msec),
        .o_carry_up(w_sec_tick_up),
        .o_borrow_down()
    );

    // clock divider
    watch_tick_gen_100hz U_TICK_GEN_100HZ (
        .clk(clk),
        .rst(rst),
        .o_tick_100hz(w_tick_100hz)
    );


endmodule


// time data
module watch_time_counter #(
    parameter BIT_WIDTH = 7,
    TIME_COUNT = 100,
    RESET_VALUE = 0
) (
    input                      clk,
    input                      rst,
    input                      i_tick,
    input                      i_time_up,
    input                      i_time_down,
    output [BIT_WIDTH - 1 : 0] o_time,
    output                     o_carry_up,    // carry up
    output                     o_borrow_down  // carry down
);


    reg [$clog2(TIME_COUNT)-1:0] count_reg, count_next;
    reg carry_reg, carry_next;
    reg borrow_reg, borrow_next;

    assign o_time = count_reg;
    assign o_carry_up = carry_reg;
    assign o_borrow_down = borrow_reg;

    // current logic
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            count_reg  <= RESET_VALUE;
            carry_reg  <= 0;
            borrow_reg <= 0;
        end else begin
            count_reg  <= count_next;
            carry_reg  <= carry_next;
            borrow_reg <= borrow_next;
        end
    end

    // next logic
    always @(*) begin
        count_next  = count_reg;
        carry_next  = 1'b0;
        borrow_next = 1'b0;

        if (i_tick) begin
            // time count
            if (count_reg == TIME_COUNT - 1) begin
                count_next = 0;
                carry_next = 1'b1;
            end else begin
                count_next = count_reg + 1;
            end
        end else if (i_time_up) begin
            // up btn
            if (count_reg == TIME_COUNT - 1) begin
                count_next = 0;
                carry_next = 1'b1;
            end else begin
                count_next = count_reg + 1;
            end
        end else if (i_time_down) begin
            // down btn
            if (count_reg == 0) begin
                count_next  = TIME_COUNT - 1;
                borrow_next = 1'b1;
            end else begin
                count_next = count_reg - 1;
            end
        end
    end

endmodule


module watch_tick_gen_100hz (
    input  clk,
    input  rst,
    output o_tick_100hz
);
    parameter FCOUNT = 100_000_000 / 100;  // 100MHz to 100hz
    reg [$clog2(FCOUNT) - 1 : 0] r_counter;
    reg r_tick;
    assign o_tick_100hz = r_tick;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            r_counter <= 0;
            r_tick    <= 1'b0;
        end else begin
            if (r_counter == FCOUNT - 1) begin
                r_counter <= 0;
                r_tick    <= 1'b1;
            end else begin
                r_counter <= r_counter + 1;
                r_tick    <= 1'b0;
            end
        end
    end
endmodule

