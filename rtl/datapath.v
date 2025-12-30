`timescale 1ns / 1ps


module sender_dp (
    input         clk,
    input         rst,
    input  [ 6:0] sw_msec,            // stopwatch
    input  [ 5:0] sw_sec,
    input  [ 5:0] sw_min,
    input  [ 4:0] sw_hour,
    input  [ 6:0] w_msec,             // watch
    input  [ 5:0] w_sec,
    input  [ 5:0] w_min,
    input  [ 4:0] w_hour,
    input  [11:0] sr04_dist,          // sr04
    input  [15:0] dht11_humidity,     // dht11
    input  [15:0] dht11_temperature,
    input         sw_start_trig,      // trigger
    input         sw_stop_trig,
    input         sw_clear_trig,
    input         sw_save_trig,
    input         w_time_trig,
    input         sr04_dist_trig,
    input         dht11_trig,
    output        o_trig,
    output [63:0] o_data
);

    // function event
    localparam EVT_NONE    = 4'd0,
               EVT_SW_START= 4'd1,
               EVT_SW_STOP = 4'd2,
               EVT_SW_CLEAR= 4'd3,
               EVT_SW_SAVE = 4'd4,
               EVT_W_TIME  = 4'd5,
               EVT_SR04    = 4'd6,
               EVT_DHT11   = 4'd7;

    // watch, stopwatch binary to bcd
    wire [3:0] sw_h_10, sw_h_1, sw_m_10, sw_m_1, 
               sw_s_10, sw_s_1, sw_ms_10, sw_ms_1;
    wire [3:0] w_h_10, w_h_1, w_m_10, w_m_1, w_s_10, w_s_1, w_ms_10, w_ms_1;

    // sr04 integer, decimal
    wire [11:0] sr04_integer;  
    wire [ 3:0] sr04_decimal;  
    assign sr04_integer = sr04_dist / 10;
    assign sr04_decimal = sr04_dist % 10;

    // output
    reg trig_reg, trig_next;
    reg [63:0] data_reg, data_next;

    assign o_trig = trig_reg;
    assign o_data = data_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            trig_reg <= 0;
            data_reg <= 0;
        end else begin
            trig_reg <= trig_next;
            data_reg <= data_next;
        end
    end

    always @(*) begin
        trig_next = 0;
        data_next = 0;

        if (sw_start_trig) begin
            data_next = {EVT_SW_START, 60'b0};
            trig_next = 1'b1;
        end else if (sw_stop_trig) begin
            data_next = {
                EVT_SW_STOP,
                sw_h_10,
                sw_h_1,
                sw_m_10,
                sw_m_1,
                sw_s_10,
                sw_s_1,
                sw_ms_10,
                sw_ms_1,
                28'b0
            };
            trig_next = 1'b1;
        end else if (sw_clear_trig) begin
            data_next = {EVT_SW_CLEAR, 60'b0};
            trig_next = 1'b1;
        end else if (sw_save_trig) begin
            data_next = {
                EVT_SW_SAVE,
                sw_h_10,
                sw_h_1,
                sw_m_10,
                sw_m_1,
                sw_s_10,
                sw_s_1,
                sw_ms_10,
                sw_ms_1,
                28'b0
            };
            trig_next = 1'b1;
        end else if (w_time_trig) begin
            data_next = {
                EVT_W_TIME,
                w_h_10,
                w_h_1,
                w_m_10,
                w_m_1,
                w_s_10,
                w_s_1,
                w_ms_10,
                w_ms_1,
                28'b0
            };
            trig_next = 1'b1;
        end else if (sr04_dist_trig) begin
            data_next = {EVT_SR04, sr04_integer, sr04_decimal, 44'd0};
            trig_next = 1'b1;
        end else if (dht11_trig) begin
            data_next = {
                EVT_DHT11,
                dht11_humidity[15:8],
                dht11_humidity[7:0],
                dht11_temperature[15:8],
                dht11_temperature[7:0],
                28'b0
            };
            trig_next = 1'b1;
        end
    end

    disit_splitter2 #(
        .BIT_WIDTH(5)
    ) U_SW_HOUR (
        .counter (sw_hour),
        .disit_1 (sw_h_1),
        .disit_10(sw_h_10)
    );

    disit_splitter2 #(
        .BIT_WIDTH(6)
    ) U_SW_MIN (
        .counter (sw_min),
        .disit_1 (sw_m_1),
        .disit_10(sw_m_10)
    );

    disit_splitter2 #(
        .BIT_WIDTH(6)
    ) U_SW_SEC (
        .counter (sw_sec),
        .disit_1 (sw_s_1),
        .disit_10(sw_s_10)
    );

    disit_splitter2 #(
        .BIT_WIDTH(7)
    ) U_SW_MSEC (
        .counter (sw_msec),
        .disit_1 (sw_ms_1),
        .disit_10(sw_ms_10)
    );

    disit_splitter2 #(
        .BIT_WIDTH(5)
    ) U_W_HOUR (
        .counter (w_hour),
        .disit_1 (w_h_1),
        .disit_10(w_h_10)
    );

    disit_splitter2 #(
        .BIT_WIDTH(6)
    ) U_W_MIN (
        .counter (w_min),
        .disit_1 (w_m_1),
        .disit_10(w_m_10)
    );

    disit_splitter2 #(
        .BIT_WIDTH(6)
    ) U_W_SEC (
        .counter (w_sec),
        .disit_1 (w_s_1),
        .disit_10(w_s_10)
    );

    disit_splitter2 #(
        .BIT_WIDTH(7)
    ) U_W_MSEC (
        .counter (w_msec),
        .disit_1 (w_ms_1),
        .disit_10(w_ms_10)
    );
endmodule

// disit_splitter
module disit_splitter2 #(
    parameter BIT_WIDTH = 7
) (
    input [BIT_WIDTH-1:0] counter,
    output [3:0] disit_1,
    output [3:0] disit_10
);

    assign disit_1  = counter % 10;
    assign disit_10 = (counter / 10) % 10;

endmodule

