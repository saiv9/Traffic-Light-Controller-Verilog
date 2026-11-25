`timescale 1ns/1ps

module tb_traffic_light_controller;
    localparam integer GREEN_CYCLES = 4;
    localparam integer YELLOW_CYCLES = 2;
    localparam integer ALL_RED_CYCLES = 1;

    localparam [2:0] RED = 3'b100;
    localparam [2:0] YELLOW = 3'b010;
    localparam [2:0] GREEN = 3'b001;

    reg clk = 1'b0;
    reg rst_n = 1'b0;
    wire [2:0] ns_light;
    wire [2:0] ew_light;
    integer checks;

    always #5 clk = ~clk;

    traffic_light_controller #(
        .GREEN_CYCLES(GREEN_CYCLES),
        .YELLOW_CYCLES(YELLOW_CYCLES),
        .ALL_RED_CYCLES(ALL_RED_CYCLES)
    ) dut (
        .clk(clk), .rst_n(rst_n),
        .ns_light(ns_light), .ew_light(ew_light)
    );

    task expect_cycles;
        input integer number_of_cycles;
        input [2:0] expected_ns;
        input [2:0] expected_ew;
        integer i;
        begin
            for (i = 0; i < number_of_cycles; i = i + 1) begin
                #1;
                if (ns_light !== expected_ns || ew_light !== expected_ew) begin
                    $display("FAIL at %0t: NS=%b EW=%b expected NS=%b EW=%b",
                             $time, ns_light, ew_light, expected_ns, expected_ew);
                    $fatal(1);
                end
                checks = checks + 1;
                @(posedge clk);
                #1;
            end
        end
    endtask

    initial begin
        $dumpfile("build/traffic_light_controller.vcd");
        $dumpvars(0, tb_traffic_light_controller);
    end

    initial begin
        checks = 0;
        repeat (2) @(posedge clk);
        #1;
        if (ns_light !== GREEN || ew_light !== RED) begin
            $display("FAIL: reset outputs are incorrect");
            $fatal(1);
        end

        @(negedge clk);
        rst_n = 1'b1;

        expect_cycles(GREEN_CYCLES, GREEN, RED);
        expect_cycles(YELLOW_CYCLES, YELLOW, RED);
        expect_cycles(ALL_RED_CYCLES, RED, RED);
        expect_cycles(GREEN_CYCLES, RED, GREEN);
        expect_cycles(YELLOW_CYCLES, RED, YELLOW);
        expect_cycles(ALL_RED_CYCLES, RED, RED);

        #1;
        if (ns_light !== GREEN || ew_light !== RED) begin
            $display("FAIL: sequence did not return to north-south green");
            $fatal(1);
        end

        $display("PASS: %0d phase checks completed", checks);
        $finish;
    end

    initial begin
        #10000;
        $display("FAIL: testbench timeout");
        $fatal(1);
    end
endmodule
