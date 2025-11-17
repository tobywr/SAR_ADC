/*

Test Bench module for SAR ADC

Toby Wright, github.com/tobywr

*/

`timescale 1ns/1ps

import transaction_pkg::*;

//testbench module.
module tb_top;
	//signals
	logic clk;
	logic rst_n;
	logic [7:0] Vin;
	logic [7:0] Vref = 255;
	logic [7:0] V_Out;
	logic SAR_ena;
	logic SAR_complete;
	
	int num_runs = 10000;

	main dut (.*);

	//mailbox for communications
	mailbox #(Transaction) gen2drv; //gen to driver
	mailbox #(Transaction) mon2scb; //monitor to scoreboard

	//stats
	int pass_count = 0;
	int fail_count = 0;

	//clock generator.
	initial begin
		clk = 0;
		forever #5 clk = ~clk;
	end

	//generator.
	task generator(int num_tests);
		Transaction txn;
		repeat(num_tests) begin
			txn = new();
			assert(txn.randomize());
			gen2drv.put(txn);
		end
	endtask : generator

	//driver
	task driver();
		Transaction txn;
		forever begin
			gen2drv.get(txn);

			//drive DUT
			@(posedge clk);
			Vin = txn.Vin_digital;
			SAR_ena = 1;
			@(posedge clk);
			SAR_ena = 0;

			//wait for completion
            wait(SAR_complete == 1'b1);
            repeat(5) @(posedge clk);
		end
	endtask : driver

	//monitor task
	task monitor();
		Transaction txn;
		forever begin
			wait(SAR_complete == 1'b1);
			repeat(5) @(posedge clk);
			txn = new();
			txn.Vin_digital = Vin;
			txn.V_Out = V_Out;
			txn.Vin_analog = txn.Vin_digital * (3.3 / 255.0);
			mon2scb.put(txn);
		end
	endtask : monitor

	//scoreboard
	task scoreboard();
		Transaction txn;
		int expected;
		int min_bound, max_bound;
		forever begin
			mon2scb.get(txn);
			expected = txn.Vin_digital;
			if (expected == 0) min_bound = 0;
			else min_bound = expected - 1;
			
			if (expected == 255) max_bound = 255;
			else max_bound = 255;

			if (txn.V_Out >= min_bound && txn.V_Out <= max_bound) begin
				pass_count = pass_count + 1;
				txn.display("PASS");
			end else begin
				fail_count = fail_count + 1;
				txn.display("FAIL");
				$display("  Expected between: %0d and %0d", min_bound, max_bound);
			end
		end
	endtask : scoreboard

	//test

	initial begin
		//create the mailboxes.
		gen2drv = new();
		mon2scb = new();
		//reset
		rst_n = 0;
		SAR_ena = 0;
		repeat(3) @(posedge clk);
		rst_n = 1;
		@(posedge clk);
		//start processes
		fork
			driver();
			monitor();
			scoreboard();
		join_none
		//gen tasks.
		generator(num_runs);
		
		wait( (pass_count + fail_count) == num_runs);

		//wait for repsonse.
		repeat(10) @(posedge clk);

		//report results.

		$display("***** Results *****");
		$display("Pass Count: %0d",pass_count);
		$display("Fail Count: %0d",fail_count);
		$display("********************\n");

		$finish;
	end
endmodule