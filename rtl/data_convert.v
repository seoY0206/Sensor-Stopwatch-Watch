`timescale 1ns / 1ps


module data_convert (
    input         clk,
    input         rst,
    input         start,
    input  [63:0] i_data,
    input         full,
    output        push,
    output [ 7:0] o_data
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
    reg [3:0] evt_reg, evt_next;

    reg [63:0] i_data_reg, i_data_next;
    reg [4:0] count_reg, count_next;

    // state
    localparam IDLE = 0, CAL = 1, SEND = 2;
    reg [1:0] state_reg, state_next;

    // output
    reg push_reg, push_next;
    reg [7:0] o_data_reg, o_data_next;

    // sr04
    reg [11:0] sr04_int_reg;  // integer
    reg [ 3:0] sr04_dec_reg;  // decimal
    reg [3:0] sr04_100_reg, sr04_10_reg, sr04_1_reg;  // to bcd

    reg [11:0] sr04_int_next;  // integer
    reg [ 3:0] sr04_dec_next;  // decimal
    reg [3:0] sr04_100_next, sr04_10_next, sr04_1_next;  // to bcd

    // dht11
    reg [7:0]
        hum_int_reg, hum_dec_reg, temp_int_reg, temp_dec_reg;  // dht11 data
    reg [3:0]
        hum_int_10_reg,
        hum_int_1_reg,
        hum_dec_10_reg,
        hum_dec_1_reg;  // humidity bcd
    reg [3:0]
        temp_int_10_reg,
        temp_int_1_reg,
        temp_dec_10_reg,
        temp_dec_1_reg;  // temperature bcd


    reg [7:0]
        hum_int_next, hum_dec_next, temp_int_next, temp_dec_next;  // dht11 data
    reg [3:0]
        hum_int_10_next,
        hum_int_1_next,
        hum_dec_10_next,
        hum_dec_1_next;  // humidity bcd
    reg [3:0]
        temp_int_10_next,
        temp_int_1_next,
        temp_dec_10_next,
        temp_dec_1_next;  // temperature bcd

    assign push   = push_reg;
    assign o_data = o_data_reg;


    always @(posedge clk, posedge rst) begin
        if (rst) begin
            o_data_reg      <= 0;
            count_reg       <= 0;
            state_reg       <= IDLE;
            evt_reg         <= EVT_NONE;
            push_reg        <= 0;
            i_data_reg      <= 0;
            sr04_int_reg    <= 0;
            sr04_dec_reg    <= 0;
            sr04_100_reg    <= 0;
            sr04_10_reg     <= 0;
            sr04_1_reg      <= 0;
            hum_int_reg     <= 0;
            hum_dec_reg     <= 0;
            temp_int_reg    <= 0;
            temp_dec_reg    <= 0;
            hum_int_10_reg  <= 0;
            hum_int_1_reg   <= 0;
            hum_dec_10_reg  <= 0;
            hum_dec_1_reg   <= 0;
            temp_int_10_reg <= 0;
            temp_int_1_reg  <= 0;
            temp_dec_10_reg <= 0;
            temp_dec_1_reg  <= 0;
        end else begin
            o_data_reg      <= o_data_next;
            count_reg       <= count_next;
            state_reg       <= state_next;
            evt_reg         <= evt_next;
            push_reg        <= push_next;
            i_data_reg      <= i_data_next;
            sr04_int_reg    <= sr04_int_next;
            sr04_dec_reg    <= sr04_dec_next;
            sr04_100_reg    <= sr04_100_next;
            sr04_10_reg     <= sr04_10_next;
            sr04_1_reg      <= sr04_1_next;
            hum_int_reg     <= hum_int_next;
            hum_dec_reg     <= hum_dec_next;
            temp_int_reg    <= temp_int_next;
            temp_dec_reg    <= temp_dec_next;
            hum_int_10_reg  <= hum_int_10_next;
            hum_int_1_reg   <= hum_int_1_next;
            hum_dec_10_reg  <= hum_dec_10_next;
            hum_dec_1_reg   <= hum_dec_1_next;
            temp_int_10_reg <= temp_int_10_next;
            temp_int_1_reg  <= temp_int_1_next;
            temp_dec_10_reg <= temp_dec_10_next;
            temp_dec_1_reg  <= temp_dec_1_next;
        end
    end

    always @(*) begin
        state_next       = state_reg;
        o_data_next      = o_data_reg;
        count_next       = count_reg;
        evt_next         = evt_reg;
        push_next        = 0;
        i_data_next      = i_data_reg;
        sr04_int_next    = sr04_int_reg;
        sr04_dec_next    = sr04_dec_reg;
        sr04_100_next    = sr04_100_reg;
        sr04_10_next     = sr04_10_reg;
        sr04_1_next      = sr04_1_reg;
        hum_int_next     = hum_int_reg;
        hum_dec_next     = hum_dec_reg;
        temp_int_next    = temp_int_reg;
        temp_dec_next    = temp_dec_reg;
        hum_int_10_next  = hum_int_10_reg;
        hum_int_1_next   = hum_int_1_reg;
        hum_dec_10_next  = hum_dec_10_reg;
        hum_dec_1_next   = hum_dec_1_reg;
        temp_int_10_next = temp_int_10_reg;
        temp_int_1_next  = temp_int_1_reg;
        temp_dec_10_next = temp_dec_10_reg;
        temp_dec_1_next  = temp_dec_1_reg;
        case (state_reg)
            IDLE: begin
                if (start) begin
                    i_data_next = i_data;
                    evt_next = i_data[63:60];
                    count_next = 0;
                    o_data_next = 0;
                    state_next = CAL;

                    // sr04
                    sr04_int_next = i_data[59:48];
                    sr04_dec_next = i_data[47:44];
                    // dht11
                    hum_int_next = i_data[59:52];
                    hum_dec_next = i_data[51:44];
                    temp_int_next = i_data[43:36];
                    temp_dec_next = i_data[35:28];
                end
            end

            CAL: begin

                // sr04
                sr04_100_next = ((sr04_int_reg % 1000) / 100);
                sr04_10_next = ((sr04_int_reg % 100) / 10);
                sr04_1_next = (sr04_int_reg % 10);

                // dht11
                hum_int_10_next = (hum_int_reg / 10);
                hum_int_1_next = (hum_int_reg % 10);
                hum_dec_10_next = (hum_dec_reg / 10);
                hum_dec_1_next = (hum_dec_reg % 10);
                temp_int_10_next = (temp_int_reg / 10);
                temp_int_1_next = (temp_int_reg % 10);
                temp_dec_10_next = (temp_dec_reg / 10);
                temp_dec_1_next = (temp_dec_reg % 10);

                state_next = SEND;

            end
            SEND: begin
                if (!full) begin
                    push_next = 1'b1;
                    case (evt_reg)
                        EVT_SW_START: begin
                            case (count_reg)
                                5'd0:    o_data_next = "S";
                                5'd1:    o_data_next = "W";
                                5'd2:    o_data_next = ":";
                                5'd3:    o_data_next = "S";
                                5'd4:    o_data_next = "T";
                                5'd5:    o_data_next = "A";
                                5'd6:    o_data_next = "R";
                                5'd7:    o_data_next = "T";
                                5'd8:    o_data_next = 8'h0A;
                                default: o_data_next = 8'h00;  // null
                            endcase
                            if (count_reg == 31) begin
                                state_next = IDLE;
                            end else begin
                                count_next = count_reg + 1;
                            end
                        end
                        EVT_SW_STOP: begin
                            case (count_reg)  // sw stop = HH:MM:SS:MM
                                5'd0: o_data_next = "S";
                                5'd1: o_data_next = "W";
                                5'd2: o_data_next = ":";
                                5'd3: o_data_next = "S";
                                5'd4: o_data_next = "T";
                                5'd5: o_data_next = "O";
                                5'd6: o_data_next = "P";
                                5'd7: o_data_next = "=";
                                5'd8: o_data_next = i_data_reg[59:56] + 8'h30;
                                5'd9: o_data_next = i_data_reg[55:52] + 8'h30;
                                5'd10: o_data_next = ":";
                                5'd11: o_data_next = i_data_reg[51:48] + 8'h30;
                                5'd12: o_data_next = i_data_reg[47:44] + 8'h30;
                                5'd13: o_data_next = ":";
                                5'd14: o_data_next = i_data_reg[43:40] + 8'h30;
                                5'd15: o_data_next = i_data_reg[39:36] + 8'h30;
                                5'd16: o_data_next = ":";
                                5'd17: o_data_next = i_data_reg[35:32] + 8'h30;
                                5'd18: o_data_next = i_data_reg[31:28] + 8'h30;
                                5'd19: o_data_next = 8'h0A;
                                default: o_data_next = 8'h00;  // null
                            endcase
                            if (count_reg == 31) begin
                                state_next = IDLE;
                            end else begin
                                count_next = count_reg + 1;
                            end
                        end
                        EVT_SW_CLEAR: begin
                            case (count_reg)  // sw clear                  
                                5'd0:    o_data_next = "S";
                                5'd1:    o_data_next = "W";
                                5'd2:    o_data_next = ":";
                                5'd3:    o_data_next = "C";
                                5'd4:    o_data_next = "L";
                                5'd5:    o_data_next = "E";
                                5'd6:    o_data_next = "A";
                                5'd7:    o_data_next = "R";
                                5'd8:    o_data_next = 8'h0A;
                                default: o_data_next = 8'h00;  // null
                            endcase
                            if (count_reg == 31) begin
                                state_next = IDLE;
                            end else begin
                                count_next = count_reg + 1;
                            end

                        end
                        EVT_SW_SAVE: begin
                            case (count_reg)  // sw save
                                5'd0: o_data_next = "S";
                                5'd1: o_data_next = "W";
                                5'd2: o_data_next = ":";
                                5'd3: o_data_next = "S";
                                5'd4: o_data_next = "A";
                                5'd5: o_data_next = "V";
                                5'd6: o_data_next = "E";
                                5'd7: o_data_next = "=";
                                5'd8: o_data_next = i_data_reg[59:56] + 8'h30;
                                5'd9: o_data_next = i_data_reg[55:52] + 8'h30;
                                5'd10: o_data_next = ":";
                                5'd11: o_data_next = i_data_reg[51:48] + 8'h30;
                                5'd12: o_data_next = i_data_reg[47:44] + 8'h30;
                                5'd13: o_data_next = ":";
                                5'd14: o_data_next = i_data_reg[43:40] + 8'h30;
                                5'd15: o_data_next = i_data_reg[39:36] + 8'h30;
                                5'd16: o_data_next = ":";
                                5'd17: o_data_next = i_data_reg[35:32] + 8'h30;
                                5'd18: o_data_next = i_data_reg[31:28] + 8'h30;
                                5'd19: o_data_next = 8'h0A;
                                default: o_data_next = 8'h00;  // null
                            endcase
                            if (count_reg == 31) begin
                                state_next = IDLE;
                            end else begin
                                count_next = count_reg + 1;
                            end

                        end
                        EVT_W_TIME: begin
                            case (count_reg)  // w time = HH:MM:SS:MM
                                5'd0: o_data_next = "W";
                                5'd1: o_data_next = ":";
                                5'd2: o_data_next = "T";
                                5'd3: o_data_next = "I";
                                5'd4: o_data_next = "M";
                                5'd5: o_data_next = "E";
                                5'd6: o_data_next = "=";
                                5'd7: o_data_next = i_data_reg[59:56] + 8'h30;
                                5'd8: o_data_next = i_data_reg[55:52] + 8'h30;
                                5'd9: o_data_next = ":";
                                5'd10: o_data_next = i_data_reg[51:48] + 8'h30;
                                5'd11: o_data_next = i_data_reg[47:44] + 8'h30;
                                5'd12: o_data_next = ":";
                                5'd13: o_data_next = i_data_reg[43:40] + 8'h30;
                                5'd14: o_data_next = i_data_reg[39:36] + 8'h30;
                                5'd15: o_data_next = ":";
                                5'd16: o_data_next = i_data_reg[35:32] + 8'h30;
                                5'd17: o_data_next = i_data_reg[31:28] + 8'h30;
                                5'd18: o_data_next = 8'h0A;
                                default: o_data_next = 8'h00;  // null
                            endcase
                            if (count_reg == 31) begin
                                state_next = IDLE;
                            end else begin
                                count_next = count_reg + 1;
                            end

                        end
                        EVT_SR04: begin
                            case (count_reg)  // sr04
                                5'd0:    o_data_next = "S";
                                5'd1:    o_data_next = "R";
                                5'd2:    o_data_next = "0";
                                5'd3:    o_data_next = "4";
                                5'd4:    o_data_next = ":";
                                5'd5:    o_data_next = "d";
                                5'd6:    o_data_next = "i";
                                5'd7:    o_data_next = "s";
                                5'd8:    o_data_next = "t";
                                5'd9:    o_data_next = "=";
                                5'd10:    o_data_next = sr04_100_reg+ 8'h30;
                                5'd11:    o_data_next = sr04_10_reg+ 8'h30;
                                5'd12:    o_data_next = sr04_1_reg+ 8'h30;
                                5'd13:    o_data_next = 8'h2E;  // '.'
                                5'd14:    o_data_next = sr04_dec_reg+ 8'h30;
                                5'd15:    o_data_next = "c";
                                5'd16:    o_data_next = "m";
                                5'd17:    o_data_next = 8'h0A; // \n
                                default: o_data_next = 8'h00;  // null
                            endcase
                            if (count_reg == 31) begin
                                state_next = IDLE;
                            end else begin
                                count_next = count_reg + 1;
                            end
                        end

                        EVT_DHT11: begin
                            case (count_reg)  // sr04
                                5'd0:    o_data_next = "D";
                                5'd1:    o_data_next = "H";
                                5'd2:    o_data_next = "T";
                                5'd3:    o_data_next = ":";
                                5'd4:    o_data_next = 8'h0A;
                                5'd5:    o_data_next = "r";
                                5'd6:    o_data_next = "h";
                                5'd7:    o_data_next = "=";
                                5'd8:    o_data_next = hum_int_10_reg+ 8'h30;
                                5'd9:    o_data_next = hum_int_1_reg+ 8'h30;
                                5'd10:    o_data_next = 8'h2E;
                                5'd11:    o_data_next = hum_dec_10_reg+ 8'h30;
                                5'd12:    o_data_next = hum_dec_1_reg+ 8'h30;
                                5'd13:    o_data_next = "%";
                                5'd14:    o_data_next = 8'h0A;
                                5'd15:    o_data_next = "t";
                                5'd16:    o_data_next = "=";
                                5'd17:    o_data_next = temp_int_10_reg+ 8'h30;
                                5'd18:    o_data_next = temp_int_1_reg+ 8'h30;
                                5'd19:    o_data_next = 8'h2E;
                                5'd20:    o_data_next = temp_dec_10_reg+ 8'h30;
                                5'd21:    o_data_next = temp_dec_1_reg+ 8'h30;
                                5'd22:    o_data_next = "C";
                                5'd23:    o_data_next = 8'h0A; // \n
                                default: o_data_next = 8'h00;  // null
                            endcase
                            if (count_reg == 31) begin
                                state_next = IDLE;
                            end else begin
                                count_next = count_reg + 1;
                            end
                        end
                    endcase
                end
            end
        endcase
    end
endmodule
