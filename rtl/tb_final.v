`timescale 1ns / 1ps

module tb_final ();

    reg        clk;
    reg        rst;
    reg        rx;
    reg  [2:0] sw;
    reg        btnU;
    reg        btnL;
    reg        btnR;
    reg        btnD;
    reg        echo;
    wire       trig;
    wire       tx;
    wire [3:0] fnd_com;
    wire [7:0] fnd_data;
    wire       led;
    wire       dht_io;
    reg  [7:0] send_data;

    reg dht11_sensor_reg, dht11_sensor_enable;
    assign dht_io = (dht11_sensor_enable) ? dht11_sensor_reg : 1'bz;
    reg [39:0] dht11_sensor_data;

    integer i;
    parameter US = 1_000, MS = 1_000_000;

    top_module dut (
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .sw(sw),
        .btnU(btnU),
        .btnL(btnL),
        .btnR(btnR),
        .btnD(btnD),
        .echo(echo),
        .trig(trig),
        .tx(tx),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data),
        .led(led),
        .dht_io(dht_io)
    );

    always #5 clk = ~clk;

    initial begin
        #0;
        clk = 0;
        rst = 1;
        rx = 1;
        sw = 3'b000;  // mode 000 = SW, 010 = W, 100 = SR04, 110 = DHT11
        btnU = 0;
        btnL = 0;
        btnR = 0;
        btnD = 0;
        echo = 0;
        i = 0;
        dht11_sensor_enable = 0;
        dht11_sensor_reg = 0;
        dht11_sensor_data = 40'b10101010_00001111_11000110_00000000_01111111;

        #10;
        rst = 0;

        #10;
        btnR = 1;  // stopwatch simulation

        #20_000;  // button debounce time
        #10;
        btnR = 0;  // state = sw : run


        #10_000_000;
        send_data = "r";
        send_uart(send_data);

        #30;
        send_data = "r";
        send_uart(send_data);



        #30_000_000;
        $stop;



        // #(20 * MS);  // state = start sync to wait
        // #(30 * US);  // state = wait to wait sync low

        // // sensor io is changed for RX to TX
        // dht11_sensor_enable = 1;

        // #(60 * US);  // state = wait sync low to wait sync high
        // dht11_sensor_reg = 1;
        // #(60 * US);  // state = wait sync high to data start

        // // to transmit to FPGA. sensor data 40bit
        // for (i = 0; i < 40; i = i + 1) begin
        //     dht11_sensor_reg = 0;
        //     #(50 * US);
        //     dht11_sensor_reg = 1;
        //     if (dht11_sensor_data[39-i]) begin
        //         #(70 * US);
        //     end else begin
        //         #(28 * US);
        //     end
        // end
        // dht11_sensor_reg = 0;

        // #(50 * US);  // state = done
        // dht11_sensor_enable = 0;  // state = idle
        // #1000;
        // $stop;



    end


    task send_uart(input [7:0] send_data);
        integer i;
        begin
            // start bit
            rx = 0;
            #(104166);  // uart 9600bps bit time
            // data bit
            for (i = 0; i < 8; i = i + 1) begin
                rx = send_data[i];
                #(104166);  // uart 9600bps bit time 
            end
            // stopbit
            rx = 1;
            #(1000);  // uart 9600bps bit time
            wait (dut.U_UART.w_tx_busy);
            wait (!dut.U_UART.w_tx_busy);
        end
    endtask

    // task sr04_echo_gen(input integer echo_delay);
    //     begin
    //         #11_000;  // 1st, 10us TTL delay time
    //         #10_000;  // 2nd, echo min delay

    //         echo = 1;
    //         #echo_delay;
    //         echo = 0;
    //     end

    // endtask
endmodule
