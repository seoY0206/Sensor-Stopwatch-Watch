`timescale 1ns / 1ps


module sr04_controller (
    input         clk,
    input         rst,
    input         start,
    input         echo,
    output        o_done,
    output        o_trig,
    output [11:0] o_dist
);
    // tick 1us
    wire w_tick_1us;

    // state
    localparam [2:0] IDLE = 0, START = 1, WAIT = 2, DIST = 3, OUT_DELAY = 4;
    reg [2:0] state, next;
    // 10us trigger count
    reg [3:0] tick_cnt_reg, tick_cnt_next;
    // output trigger
    reg trig_reg, trig_next;
    reg o_done_reg, o_done_next;
    // output distance
    reg [$clog2(400*58)-1:0] dist_reg, dist_next;
    reg [5:0] int_counter_reg, int_counter_next;
    reg [5:0] reminder_reg, reminder_next;

    assign o_trig = trig_reg;
    assign o_done = o_done_reg;
    assign o_dist = dist_reg;


    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state <= IDLE;
            dist_reg <= 0;
            trig_reg <= 0;
            tick_cnt_reg <= 0;
            o_done_reg <= 0;
            int_counter_reg <= 0;
            reminder_reg <= 0;
        end else begin
            state <= next;
            dist_reg <= dist_next;
            trig_reg <= trig_next;
            tick_cnt_reg <= tick_cnt_next;
            o_done_reg <= o_done_next;
            int_counter_reg <= int_counter_next;
            reminder_reg <= reminder_next;
        end
    end

    always @(*) begin
        next = state;
        dist_next = dist_reg;
        trig_next = trig_reg;
        tick_cnt_next = tick_cnt_reg;
        o_done_next = 1'b0;
        int_counter_next = int_counter_reg;
        reminder_next = reminder_reg;
        case (state)
            IDLE: begin
                if (start) begin
                    next = START;
                    tick_cnt_next = 0;
                end
            end

            START: begin
                trig_next = 1'b1;
                if (w_tick_1us == 1) begin
                    if (tick_cnt_reg == 9) begin
                        tick_cnt_next = 0;
                        next = WAIT;
                        trig_next = 0;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end

            WAIT: begin
                if (echo == 1) begin
                    if (w_tick_1us == 1) begin
                        next = DIST;
                        dist_next = 0;
                        int_counter_next = 0;
                        reminder_next = 0;
                    end
                end
            end

            DIST: begin
                if (echo == 0) begin
                    next = OUT_DELAY;
                    dist_next = dist_reg;
                    reminder_next = int_counter_reg;
                end else begin
                    if (w_tick_1us == 1) begin
                        if (int_counter_reg == 57) begin
                            int_counter_next = 0;
                            dist_next = dist_reg + 1;
                        end else begin
                            int_counter_next = int_counter_reg + 1;
                        end
                    end
                end
            end
            OUT_DELAY: begin
                dist_next = dist_reg * 10 + reminder_reg / 6;
                o_done_next = 1'b1;
                next = IDLE;
            end
        endcase
    end

    tick_gen_1us U_TICK_1US (
        .clk(clk),
        .rst(rst),
        .o_tick_1us(w_tick_1us)
    );

endmodule




module tick_gen_1us (
    input  clk,
    input  rst,
    output o_tick_1us
);
    parameter TICK_COUNT = 100_000_000 / 1_000_000;

    reg [$clog2(TICK_COUNT)-1:0] r_counter;
    reg tick_reg;

    assign o_tick_1us = tick_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            r_counter <= 0;
            tick_reg  <= 0;
        end else begin
            if (r_counter == TICK_COUNT - 1) begin
                r_counter <= 0;
                tick_reg  <= 1'b1;
            end else begin
                r_counter <= r_counter + 1;
                tick_reg  <= 1'b0;
            end
        end
    end
endmodule
