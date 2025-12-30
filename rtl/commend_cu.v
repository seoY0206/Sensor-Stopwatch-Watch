`timescale 1ns / 1ps

module commend_cu (
    input        clk,
    input        rst,
    input  [2:1] sw,
    input  [3:0] btn,
    input  [7:0] fifo_data,
    input        rx_trigger,
    output [1:0] o_mode,
    output       pop,
    output       o_event_time,
    output [3:0] o_stopwatch,
    output [3:0] o_watch,
    output       o_sr04,
    output       o_dht11
);

    wire w_uart_mode, w_tick_sr04, w_tick_dht11;
    wire [3:0] w_tick_sw, w_tick_w;



    button_router U_BT_ROUTER (
        .clk(clk),
        .rst(rst),
        .mode(o_mode),
        .btn(btn),
        .uart_sw(w_tick_sw),
        .uart_w(w_tick_w),
        .uart_sr04(w_tick_sr04),
        .uart_dht11(w_tick_dht11),
        .o_sw(o_stopwatch),
        .o_w(o_watch),
        .o_sr04(o_sr04),
        .o_dht11(o_dht11)
    );


    mode_controller U_MODE_CNTL (
        .clk(clk),
        .rst(rst),
        .sw(sw),
        .tick_uart(w_uart_mode),
        .mode(o_mode)
    );

    command_decoder U_CMD_DEC (
        .clk(clk),
        .rst(rst),
        .rx_fifo_data(fifo_data),
        .rx_trigger(rx_trigger),
        .pop(pop),
        .o_event_time(o_event_time),
        .tick_mode(w_uart_mode),
        .tick_stopwatch(w_tick_sw),
        .tick_watch(w_tick_w),
        .tick_sr04(w_tick_sr04),
        .tick_dht11(w_tick_dht11)
    );




endmodule



module button_router (
    input        clk,
    input        rst,
    input  [1:0] mode,
    input  [3:0] btn,
    input  [3:0] uart_sw,
    input  [3:0] uart_w,
    input        uart_sr04,
    input        uart_dht11,
    output [3:0] o_sw,
    output [3:0] o_w,
    output       o_sr04,
    output       o_dht11
);

    // mode, btn parameter
    parameter L = 0, R = 1, U = 2, D = 3;
    parameter SW = 2'b00, W = 2'b01, SR04 = 2'b10, DHT11 = 2'b11;

    // button debounce output
    wire [3:0] w_btn;

    // btn or uart
    wire [3:0] sw_src = (mode == SW) ? (w_btn | uart_sw) : 4'b0;
    wire [3:0] w_src = (mode == W) ? (w_btn | uart_w) : 4'b0;
    wire       s4_src = (mode == SR04) ? (w_btn[R] | uart_sr04) : 1'b0;
    wire       dht11_src = (mode == DHT11) ? (w_btn[L] | uart_dht11) : 1'b0;

    //output
    reg [3:0] o_sw_reg, o_w_reg;
    reg o_sr04_reg, o_dht11_reg;

    assign o_sw   = o_sw_reg;
    assign o_w    = o_w_reg;
    assign o_sr04 = o_sr04_reg;
    assign o_dht11 = o_dht11_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            o_sw_reg   <= 4'b0;
            o_w_reg    <= 4'b0;
            o_sr04_reg <= 1'b0;
            o_dht11_reg <= 1'b0;
        end else begin
            o_sw_reg   <= sw_src;
            o_w_reg    <= w_src;
            o_sr04_reg <= s4_src;
            o_dht11_reg <= dht11_src;
        end
    end


    button_debounce U_BD_L (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btn[L]),
        .o_btn(w_btn[L])
    );
    button_debounce U_BD_R (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btn[R]),
        .o_btn(w_btn[R])
    );
    button_debounce U_BD_U (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btn[U]),
        .o_btn(w_btn[U])
    );
    button_debounce U_BD_D (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btn[D]),
        .o_btn(w_btn[D])
    );

endmodule



module mode_controller (
    input        clk,
    input        rst,
    input  [2:1] sw,
    input        tick_uart,
    output [1:0] mode        // sw = 0, w = 1, sr04 = 2, dht11 = 3
);

    wire sw2_up, sw2_down, sw1_up, sw1_down;

    // state fsm
    parameter [1:0] SW = 0, W = 1, SR04 = 2, DHT11 = 3;
    reg [1:0] mode_reg, mode_next;
    assign mode = mode_reg;

    // state reg SL
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            mode_reg <= 0;
        end else begin
            mode_reg <= mode_next;
        end
    end

    // next CL + output CL
    always @(*) begin
        mode_next = mode_reg;
        if (tick_uart) begin
            mode_next = mode_reg + 1;
        end else if (sw2_up | sw2_down | sw1_up | sw1_down) begin
            mode_next = {sw[2], sw[1]};
        end
    end

    edge_detector U_SW_2 (
        .clk(clk),
        .rst(rst),
        .sw(sw[2]),
        .tick_sw_rise(sw2_up),
        .tick_sw_fall(sw2_down)
    );

    edge_detector U_SW_1 (
        .clk(clk),
        .rst(rst),
        .sw(sw[1]),
        .tick_sw_rise(sw1_up),
        .tick_sw_fall(sw1_down)
    );

endmodule


module command_decoder (
    input        clk,
    input        rst,
    input  [7:0] rx_fifo_data,
    input        rx_trigger,
    output       o_event_time,
    output       pop,
    output       tick_mode,
    output [3:0] tick_stopwatch,
    output [3:0] tick_watch,
    output       tick_sr04,
    output       tick_dht11
);

    // btn state
    parameter L = 0, R = 1, U = 2, D = 3;
    // receive state
    localparam IDLE = 0, RECEIVE = 1;
    reg state, next;
    // output
    reg mode_reg, mode_next;
    reg pop_reg, pop_next;
    reg [3:0] sw_reg, sw_next;  // stopwatch
    reg [3:0] w_reg, w_next;  // watch
    reg sr04_reg, sr04_next;
    reg time_reg, time_next;
    reg dht11_reg, dht11_next;


    assign tick_mode = mode_reg;
    assign pop = pop_reg;
    assign tick_stopwatch = sw_reg;
    assign tick_watch = w_reg;
    assign tick_sr04 = sr04_reg;
    assign o_event_time = time_reg;
    assign tick_dht11 = dht11_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state     <= IDLE;
            mode_reg  <= 0;
            sw_reg    <= 0;
            w_reg     <= 0;
            pop_reg   <= 0;
            sr04_reg  <= 0;
            time_reg  <= 0;
            dht11_reg <= 0;
        end else begin
            state     <= next;
            mode_reg  <= mode_next;
            sw_reg    <= sw_next;
            w_reg     <= w_next;
            pop_reg   <= pop_next;
            sr04_reg  <= sr04_next;
            time_reg  <= time_next;
            dht11_reg <= dht11_next;
        end
    end

    // next CL
    always @(*) begin
        next = state;
        pop_next = 1'b0;
        mode_next = 1'b0;
        sw_next   = 4'b0000;
        w_next    = 4'b0000;
        sr04_next = 0;
        time_next = 0;
        dht11_next = 0;
        case (state)
            IDLE: begin
                if (~rx_trigger) begin
                    next = RECEIVE;
                end
            end

            RECEIVE: begin
                pop_next = 1'b1;
                case (rx_fifo_data)
                    "t": time_next = 1'b1;  // time event trigger
                    "m": mode_next = 1'b1;  // next mode
                    "d": sr04_next = 1'b1;  // sr04 distance
                    "e": dht11_next = 1'b1;  // dht11 run
                    "c": sw_next[L] = 1'b1;  // L : clear
                    "r": sw_next[R] = 1'b1;  // R : runstop
                    "z": sw_next[U] = 1'b1;  // U : restore
                    "s": sw_next[D] = 1'b1;  // D : save
                    "L": w_next[L] = 1'b1;  // L : digit_up
                    "R": w_next[R] = 1'b1;  // R : digit_down
                    "+": w_next[U] = 1'b1;  // U : time_up
                    "-": w_next[D] = 1'b1;  // D : time_down
                endcase
                next = IDLE;
            end
        endcase
    end

endmodule


module button_debounce (
    input  clk,
    input  rst,
    input  i_btn,
    output o_btn
);

    // 100MHz to 1MHz
    reg [$clog2(100) - 1 : 0] counter_reg;
    reg clk_reg;

    parameter register = 8;
    reg [register - 1:0] q_reg, q_next;
    reg  edge_reg;
    wire debounce;

    // clock divider
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            clk_reg <= 1'b0;
        end else begin
            if (counter_reg == 100 - 1) begin
                counter_reg <= 0;
                clk_reg <= 1'b1;
            end else begin
                counter_reg <= counter_reg + 1;
                clk_reg <= 1'b0;
            end
        end
    end

    // debounce, shift register
    always @(posedge clk_reg, posedge rst) begin
        if (rst) begin
            q_reg <= 0;
        end else begin
            q_reg <= q_next;
        end
    end

    //serial input, Parallel output shift register
    always @(*) begin
        q_next = {i_btn, q_reg[register-1 : 1]};
    end

    // 8 input AND
    assign debounce = &q_reg;

    // Q9 output
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            edge_reg <= 1'b0;
        end else begin
            edge_reg <= debounce;
        end
    end

    // edge output
    assign o_btn = ~edge_reg & debounce;

endmodule


module edge_detector (
    input  clk,
    input  rst,
    input  sw,
    output tick_sw_rise,
    output tick_sw_fall
);

    reg [1:0] r_q;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            r_q <= 0;
        end else begin
            r_q <= {r_q[0], sw};
        end
    end

    assign tick_sw_rise = r_q[0] & ~r_q[1];
    assign tick_sw_fall = ~r_q[0] & r_q[1];

endmodule


