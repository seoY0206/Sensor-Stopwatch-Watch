module stopwatch (
    input         clk,
    input         rst,
    input  [ 3:0] i_btn,
    output [ 6:0] msec,
    output [ 5:0] sec,
    output [ 5:0] min,
    output [ 4:0] hour,
    output        o_event_start,
    output        o_event_stop,
    output        o_event_clear,
    output        o_event_save
);


    wire w_runstop, w_clear, w_save, w_restore;

    // edge trigger
    reg runstop_prev;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            runstop_prev <= 1'b0;
        end else begin
            runstop_prev <= w_runstop;
        end
    end

    // event trigger
    assign o_event_start = (~runstop_prev) & w_runstop;  // rising edge
    assign o_event_stop  = runstop_prev & ~w_runstop;  // falling edge
    assign o_event_clear = w_clear;
    assign o_event_save  = w_save;

    stopwatch_cu U_SW_CU (
        .clk(clk),
        .rst(rst),
        .i_clear(i_btn[0]),
        .i_runstop(i_btn[1]),
        .i_restore(i_btn[2]),
        .i_save(i_btn[3]),
        .o_clear(w_clear),
        .o_runstop(w_runstop),
        .o_restore(w_restore),
        .o_save(w_save)
    );
    stopwatch_dp U_SW_DP (
        .clk(clk),
        .rst(rst),
        .i_clear(w_clear),
        .i_runstop(w_runstop),
        .i_restore(w_restore),
        .i_save(w_save),
        .msec(msec),
        .sec(sec),
        .min(min),
        .hour(hour)
    );



endmodule
