`timescale 1ns / 1ps

module fnd_controller (
    input         clk,
    input         rst,
    input  [ 2:0] mode,
    input  [23:0] i_stopwatch,
    input  [23:0] i_watch,
    input  [11:0] i_sr04,
    input  [31:0] i_dht11,
    output [ 3:0] fnd_com,
    output [ 7:0] fnd_data
);

    // wire
    wire [15:0] w_mode0_sw, w_mode0_w, w_mode0_dht11;
    wire [15:0] w_sr04;
    wire [15:0] w_hex_data;
    wire [3:0] w_digit_1, w_digit_10, w_digit_100, w_digit_1000;
    wire [3:0] w_dot_10, w_dot_100;
    wire [3:0] w_bcd;
    wire [2:0] w_sel;
    wire w_clk_1khz;

    // decoder_2x4 & bcd_decoder
    decoder_2x4 U_DEC_2x4 (
        .sel(w_sel[1:0]),
        .fnd_com(fnd_com)
    );
    bcd_decoder U_BCD_DEC (
        .bcd(w_bcd),
        .fnd_data(fnd_data)
    );

    // mux_8x1
    mux_8x1 U_MUX_8x1 (
        .digit_1(w_digit_1),
        .digit_10(w_digit_10),
        .digit_100(w_digit_100),
        .digit_1000(w_digit_1000),
        .dot_1(4'hf),
        .dot_10(w_dot_10),
        .dot_100(w_dot_100),
        .dot_1000(4'hf),
        .sel(w_sel),
        .bcd(w_bcd)
    );

    // digit_splitter & dot_display
    digit_splitter U_DS_1_10 (
        .hex_data(w_hex_data[7:0]),
        .digit_1 (w_digit_1),
        .digit_10(w_digit_10)
    );
    digit_splitter U_DS_100_1000 (
        .hex_data(w_hex_data[15:8]),
        .digit_1 (w_digit_100),
        .digit_10(w_digit_1000)
    );
    dot_display U_DOT_DISPLAY (
        .msec(i_watch[6:0]),
        .mode(mode[2:1]),
        .dot_10(w_dot_10),
        .dot_100(w_dot_100)
    );

    // mux_4x1_mode_2_1
    mux_4x1_mode_2_1 U_MUX_MODE21 (
        .sw_data(w_mode0_sw),
        .w_data(w_mode0_w),
        .sr04_data(w_sr04),
        .dht11_data(w_mode0_dht11),
        .mode(mode[2:1]),
        .o_data(w_hex_data)
    );

    // mux_2x1_mode0
    mux_2x1_mode0 U_MUX_MODE0_SW (
        .in0_data({2'b0, i_stopwatch[12:7], 1'b0, i_stopwatch[6:0]}),
        .in1_data({3'b0, i_stopwatch[23:19], 2'b0, i_stopwatch[18:13]}),
        .mode0(mode[0]),
        .o_mode0_data(w_mode0_sw)
    );
    mux_2x1_mode0 U_MUX_MODE0_W (
        .in0_data({2'b0, i_watch[12:7], 1'b0, i_watch[6:0]}),
        .in1_data({3'b0, i_watch[23:19], 2'b0, i_watch[18:13]}),
        .mode0(mode[0]),
        .o_mode0_data(w_mode0_w)
    );
    mux_2x1_mode0 U_MUX_MODE0_DHT11 (
        .in0_data(i_dht11[15:0]),
        .in1_data(i_dht11[31:16]),
        .mode0(mode[0]),
        .o_mode0_data(w_mode0_dht11)
    );

    // sr04 dec4_2_hex2
    dec4_to_hex2 U_DEC2HEX (
        .decimal_data(i_sr04),
        .hex_1_10(w_sr04[7:0]),
        .hex_100_1000(w_sr04[15:8])
    );

    // clk_div_1k & count_8
    counter_8 U_CNT_8 (
        .clk(w_clk_1khz),
        .rst(rst),
        .sel(w_sel)
    );
    clk_div_1khz U_CLK_1k (
        .clk(clk),
        .rst(rst),
        .o_clk_1khz(w_clk_1khz)
    );

endmodule

module dot_display (
    input      [6:0] msec,
    input      [2:1] mode,
    output reg [3:0] dot_10,
    output reg [3:0] dot_100
);

    parameter [1:0] STOPWATCH = 0, WATCH = 1, SR04 = 2, DHT11 = 3;

    always @(*) begin
        dot_10  = 4'hf;
        dot_100 = 4'hf;
        case (mode)
            STOPWATCH, WATCH: dot_100 = (msec < 50) ? 4'hf : 4'he;
            SR04: dot_10 = 4'he;
            DHT11: dot_100 = 4'he;
        endcase
    end

endmodule

module mux_4x1_mode_2_1 (
    input  [15:0] sw_data,
    input  [15:0] w_data,
    input  [15:0] sr04_data,
    input  [15:0] dht11_data,
    input  [ 2:1] mode,
    output [15:0] o_data
);

    parameter [1:0] STOPWATCH = 0, WATCH = 1, SR04 = 2, DHT11 = 3;

    reg [15:0] r_data;
    assign o_data = r_data;

    always @(*) begin
        case (mode)
            STOPWATCH: r_data = sw_data;
            WATCH:     r_data = w_data;
            SR04:      r_data = sr04_data;
            DHT11:     r_data = dht11_data;
            default:   r_data = sw_data;
        endcase
    end

endmodule

module mux_2x1_mode0 (
    input  [15:0] in0_data,
    input  [15:0] in1_data,
    input         mode0,
    output [15:0] o_mode0_data
);

    assign o_mode0_data = mode0 ? in1_data : in0_data;

endmodule

module clk_div_1khz (
    input  clk,
    input  rst,
    output o_clk_1khz
);

    reg [$clog2(100_000)-1:0] r_counter;
    reg r_clk_1khz;
    assign o_clk_1khz = r_clk_1khz;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            r_counter  <= 0;
            r_clk_1khz <= 1'b0;
        end else begin
            if (r_counter == 100_000 - 1) begin
                r_counter  <= 0;
                r_clk_1khz <= 1'b1;
            end else begin
                r_counter  <= r_counter + 1;
                r_clk_1khz <= 1'b0;
            end
        end
    end

endmodule

module counter_8 (
    input        clk,
    input        rst,
    output [2:0] sel
);

    reg [2:0] counter;
    assign sel = counter;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter <= 3'b000;
        end else begin
            counter <= counter + 1;
        end
    end

endmodule

module decoder_2x4 (
    input  [1:0] sel,
    output [3:0] fnd_com
);
    assign fnd_com = (sel==2'b00) ? 4'b1110:
                     (sel==2'b01) ? 4'b1101:
                     (sel==2'b10) ? 4'b1011:
                     (sel==2'b11) ? 4'b0111:4'b1111;

endmodule

module mux_8x1 (
    input  [3:0] digit_1,
    input  [3:0] digit_10,
    input  [3:0] digit_100,
    input  [3:0] digit_1000,
    input  [3:0] dot_1,
    input  [3:0] dot_10,
    input  [3:0] dot_100,
    input  [3:0] dot_1000,
    input  [2:0] sel,
    output [3:0] bcd
);

    reg [3:0] r_bcd;
    assign bcd = r_bcd;

    always @(*) begin
        case (sel)
            3'b000:  r_bcd = digit_1;
            3'b001:  r_bcd = digit_10;
            3'b010:  r_bcd = digit_100;
            3'b011:  r_bcd = digit_1000;
            3'b100:  r_bcd = dot_1;
            3'b101:  r_bcd = dot_10;
            3'b110:  r_bcd = dot_100;
            3'b111:  r_bcd = dot_1000;
            default: r_bcd = digit_1;
        endcase
    end

endmodule

module dec4_to_hex2 (
    input  [11:0] decimal_data,
    output [ 7:0] hex_1_10,
    output [ 7:0] hex_100_1000
);

    assign hex_1_10 = decimal_data % 100;
    assign hex_100_1000 = decimal_data / 100;

endmodule

module digit_splitter (
    input  [7:0] hex_data,
    output [3:0] digit_1,
    output [3:0] digit_10
);

    assign digit_1  = hex_data % 10;
    assign digit_10 = (hex_data / 10) % 10;

endmodule

module bcd_decoder (
    input  [3:0] bcd,
    output [7:0] fnd_data
);

    reg [7:0] r_fnd_data;
    assign fnd_data = r_fnd_data;

    always @(bcd) begin
        case (bcd)
            4'b0000: r_fnd_data = 8'hC0;
            4'b0001: r_fnd_data = 8'hF9;
            4'b0010: r_fnd_data = 8'hA4;
            4'b0011: r_fnd_data = 8'hB0;
            4'b0100: r_fnd_data = 8'h99;
            4'b0101: r_fnd_data = 8'h92;
            4'b0110: r_fnd_data = 8'h82;
            4'b0111: r_fnd_data = 8'hF8;
            4'b1000: r_fnd_data = 8'h80;
            4'b1001: r_fnd_data = 8'h90;
            4'b1010: r_fnd_data = 8'h88;
            4'b1011: r_fnd_data = 8'h83;
            4'b1100: r_fnd_data = 8'hC6;
            4'b1101: r_fnd_data = 8'hA1;
            4'b1110: r_fnd_data = 8'h7F;
            4'b1111: r_fnd_data = 8'hFF;
            default: r_fnd_data = 8'hFF;
        endcase
    end

endmodule

