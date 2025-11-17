/*

Transaction class for SAR ADC test bench.

Toby Wright, github.com/tobywr

*/

`timescale 1ns/1ps

package transaction_pkg;

	class Transaction;
		rand bit [15:0] Vin_fp;
		real Vin_analog;

		bit [7:0] Vin_digital; //Digital equiv.
		bit [7:0] V_Out;
        //distribution of the floatingpoint vin value.
	    constraint reasonable { Vin_fp dist {
	                           [0:60000] := 80,
	                           [60001:65535] := 20
	                           };
	                           }
		//convert post randomization
		function void post_randomize();
	        Vin_analog = real'(Vin_fp) * (3.3 / 65535.0);
	        Vin_digital = Vin_fp >> 8;
		endfunction

		function void display(string tag);
			$display("[%s] Vin_analog=%.3fV -> Vin_digital=%0d, V_Out=%0d", tag, Vin_analog, Vin_digital, V_Out );
		endfunction
	endclass
endpackage