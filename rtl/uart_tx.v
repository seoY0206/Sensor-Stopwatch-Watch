`timescale 1ns / 1ps


module uart_tx (
    input        clk,
    input        rst,
    input        start_trigger,
    input  [7:0] tx_data,
    input        b_tick,
    output       tx,
    output       tx_busy
);

    // fsm state
    localparam [2:0] IDLE = 0, WAIT = 1, START = 2, DATA = 3, STOP = 4;

    // state
    reg [2:0] state, next;
    // bit control reg
    reg [2:0] bit_count, bit_next;
    // tx internal buffer
    reg [7:0] data_reg, data_next;
    // b_tick counter
    reg [3:0] b_tick_cnt_reg, b_tick_cnt_next;

    //output
    reg tx_reg, tx_next;
    reg tx_busy_reg, tx_busy_next;

    assign tx = tx_reg;
    assign tx_busy = tx_busy_reg;

    // state register
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state          <= IDLE;
            tx_reg         <= 1'b1;  // output high
            bit_count      <= 0;
            b_tick_cnt_reg <= 0;
            data_reg       <= 0;
            tx_busy_reg    <= 0;
        end else begin
            state          <= next;
            tx_reg         <= tx_next;
            bit_count      <= bit_next;
            b_tick_cnt_reg <= b_tick_cnt_next;
            data_reg       <= data_next;
            tx_busy_reg    <= tx_busy_next;
        end
    end

    // next CL
    always @(*) begin
        // remove latch
        next = state;
        tx_next = tx_reg;
        bit_next = bit_count;
        b_tick_cnt_next = b_tick_cnt_reg;
        data_next = data_reg;
        tx_busy_next = tx_busy_reg;
        case (state)
            IDLE: begin
                // output tx
                tx_next = 1'b1;
                tx_busy_next = 1'b0;
                if (start_trigger == 1'b1) begin
                    next = WAIT;
                    tx_busy_next = 1'b1;
                    data_next = tx_data;
                end
            end
            WAIT: begin
                if (b_tick == 1'b1) begin
                    next = START;
                    b_tick_cnt_next = 0;
                end
            end
            START: begin
                tx_next = 0;
                if (b_tick == 1'b1) begin
                    if (b_tick_cnt_reg == 15) begin
                        bit_next = 0;
                        b_tick_cnt_next = 0;
                        next = DATA;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
            DATA: begin
                tx_next = data_reg[0];
                if (b_tick == 1'b1) begin
                    if (b_tick_cnt_reg == 15) begin
                        b_tick_cnt_next = 0;
                        if (bit_count == 3'b111) begin
                            next = STOP;
                        end else begin
                            data_next = data_reg >> 1;
                            bit_next  = bit_count + 1;
                        end
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
            STOP: begin
                tx_next = 1;
                if (b_tick == 1'b1) begin
                    if (b_tick_cnt_reg == 15) begin
                        next = IDLE;
                        tx_busy_next = 1'b0;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
        endcase

    end

endmodule
