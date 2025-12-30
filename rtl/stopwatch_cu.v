`timescale 1ns / 1ps
module stopwatch_cu (
    input  clk,
    input  rst,
    input  i_clear,
    input  i_runstop,
    input  i_restore,
    input  i_save,
    output o_runstop,
    output o_clear,
    output o_save,
    output o_restore
);
    // state define
    parameter STOP = 3'b000, RUN = 3'b001, 
              CLEAR = 3'b010, SAVE = 3'b011, 
              RESTORE = 3'b100;
    reg [2:0] c_state, n_state;
    reg
        runstop_reg,
        runstop_next,
        clear_reg,
        clear_next,
        save_reg,
        save_next,
        restore_reg,
        restore_next;

    assign o_runstop = runstop_reg;
    assign o_clear   = clear_reg;
    assign o_save    = save_reg;
    assign o_restore = restore_reg;

    // state register SL
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state     <= STOP;
            runstop_reg <= 1'b0;
            clear_reg   <= 1'b0;
            save_reg    <= 1'b0;
            restore_reg <= 1'b0;
        end else begin
            c_state     <= n_state;
            runstop_reg <= runstop_next;
            clear_reg   <= clear_next;
            save_reg    <= save_next;
            restore_reg <= restore_next;
        end
    end

    // next CL + output CL
    always @(*) begin
        n_state      = c_state;
        runstop_next = runstop_reg;
        clear_next   = clear_reg;
        save_next    = save_reg;
        restore_next = restore_reg;
        case (c_state)
            STOP: begin
                // moore output
                runstop_next = 1'b0;
                clear_next   = 1'b0;
                save_next    = 1'b0;
                restore_next = 1'b0;
                casex ({i_clear, i_runstop, i_restore, i_save})
                    4'b1000: n_state = CLEAR;  // L
                    4'b0100: n_state = RUN;  // R
                    4'b0010: n_state = RESTORE;  // U
                    4'b0001: n_state = SAVE;  // D
                endcase
            end
            RUN: begin
                runstop_next = 1'b1;
                if (i_runstop) begin
                    n_state = STOP;
                end else if (i_save) begin
                    n_state = SAVE;
                end
            end
            CLEAR: begin
                clear_next = 1'b1;
                n_state = STOP;
            end
            SAVE: begin
                save_next = 1'b1;
                runstop_next = 1'b0;
                n_state = STOP;
            end
            RESTORE: begin
                restore_next = 1'b1;
                n_state = STOP;
            end
        endcase
    end

endmodule
