`timescale 1ns / 1ps

module dht11_control_unit (
    input         clk,
    input         rst,
    input         i_start,      // start trig
    output        o_valid,      // result of check sum calculate
    output [15:0] humidity,
    output [15:0] temperature,
    output        o_trig,
    inout         dht_io        // sensor in/out
);

    reg dht_io_enable_reg, dht_io_enable_next;  // to control for dht_out_reg
    reg dht_out_reg, dht_out_next;  // to dht11 sensor output
    reg valid_reg, valid_next;  // valid output
    reg o_trig_reg, o_trig_next;

    wire w_tick_1us;

    assign dht_io  = (dht_io_enable_reg) ? dht_out_reg : 1'bz;
    assign o_valid = valid_reg;
    assign o_trig = o_trig_reg;

    // state
    parameter [3:0] IDLE = 0, START_SYNC = 1, WAIT = 2, WAIT_SYNC_LOW = 3,
                    WAIT_SYNC_HIGH = 4, DATA_START = 5, DATA_HIGH = 6, DONE = 7;

    reg [3:0] state_reg, state_next;

    // tick count
    reg [$clog2(20000)-1:0] tick_count_reg, tick_count_next;

    // data
    reg [5:0] bit_count_reg, bit_count_next;
    reg [39:0] bit_data_reg, bit_data_next;

    // output
    assign humidity = bit_data_reg[39:24];
    assign temperature = bit_data_reg[23:8];

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state_reg <= IDLE;
            dht_io_enable_reg <= 1'b1;
            dht_out_reg <= 1'b1;
            tick_count_reg <= 1'b0;
            valid_reg <= 1'b0;
            bit_count_reg <= 1'b0;
            bit_data_reg <= 0;
            o_trig_reg <= 0;
        end else begin
            state_reg <= state_next;
            dht_io_enable_reg <= dht_io_enable_next;
            dht_out_reg <= dht_out_next;
            tick_count_reg <= tick_count_next;
            valid_reg <= valid_next;
            bit_count_reg <= bit_count_next;
            bit_data_reg <= bit_data_next;
            o_trig_reg <= o_trig_next;
        end
    end

    always @(*) begin
        state_next = state_reg;
        dht_io_enable_next = dht_io_enable_reg;
        dht_out_next = dht_out_reg;
        tick_count_next = tick_count_reg;
        valid_next = valid_reg;
        bit_count_next = bit_count_reg;
        bit_data_next = bit_data_reg;
        o_trig_next = 0;
        case (state_reg)
            IDLE: begin
                dht_io_enable_next = 1'b1;
                if (i_start) begin
                    state_next = START_SYNC;
                    tick_count_next = 0;
                end
            end
            START_SYNC: begin
                dht_out_next = 1'b0;
                if (w_tick_1us) begin
                    if (tick_count_reg == (20000 - 1)) begin
                        dht_out_next = 1'b1;
                        state_next = WAIT;
                        tick_count_next = 0;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
            WAIT: begin
                if (w_tick_1us) begin
                    if (tick_count_reg >= 30) begin
                        dht_io_enable_next = 0;
                        if (dht_io == 0) begin
                            state_next = WAIT_SYNC_LOW;
                            tick_count_next = 0;
                        end else if (tick_count_reg >= 30 + 300) begin // 300us time out
                            state_next = IDLE;  // restart
                        end else begin
                            tick_count_next = tick_count_reg + 1;
                        end
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
            WAIT_SYNC_LOW: begin
                if (w_tick_1us) begin
                    if (dht_io == 1) begin
                        if (tick_count_reg >= 50 && tick_count_reg <= 100) begin
                            state_next = WAIT_SYNC_HIGH;
                            tick_count_next = 0;
                        end else begin
                            valid_next = 1'b0;
                            state_next = IDLE;
                        end
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
            WAIT_SYNC_HIGH: begin
                if (w_tick_1us) begin
                    if (dht_io == 0) begin
                        if (tick_count_reg >= 50 && tick_count_reg <= 100) begin
                            state_next = DATA_START;
                            tick_count_next = 0;
                            bit_count_next = 0;
                            bit_data_next = 0;
                        end else begin
                            valid_next = 1'b0;
                            state_next = IDLE;
                        end
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
            DATA_START: begin
                if (w_tick_1us) begin
                    if (dht_io == 1) begin
                        state_next = DATA_HIGH;
                        tick_count_next = 0;
                    end
                end
            end
            DATA_HIGH: begin
                if (w_tick_1us) begin
                    if (dht_io == 0) begin
                        if (tick_count_reg < 15 || tick_count_reg > 90) begin
                            valid_next = 0;
                            state_next = IDLE;
                        end else if (tick_count_reg <= 50) begin
                            bit_data_next[39-bit_count_reg] = 0;
                        end else begin
                            bit_data_next[39-bit_count_reg] = 1;
                        end

                        if (bit_count_reg == 39) begin
                            state_next = DONE;
                            tick_count_next = 0;
                        end else begin
                            bit_count_next = bit_count_reg + 1;
                            state_next = DATA_START;
                        end
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
            DONE: begin
                if (w_tick_1us) begin
                    if (bit_count_reg == 49) begin
                        if (bit_data_reg[39:32]+bit_data_reg[31:24]+bit_data_reg[23:16]+bit_data_reg[15:8] == bit_data_reg[7:0]) begin
                            valid_next = 1;
                            dht_io_enable_next = 1;
                            o_trig_next = 1;
                            state_next = IDLE;
                        end else begin
                            valid_next = 0;
                            dht_io_enable_next = 1;
                            o_trig_next = 1;
                            state_next = IDLE;
                        end
                    end else begin
                        bit_count_next = bit_count_reg + 1;
                    end
                end
            end
        endcase
    end

    tick_gen_1us U_TICK_1US (
        .clk(clk),
        .rst(rst),
        .o_tick_1us(w_tick_1us)
    );


endmodule



