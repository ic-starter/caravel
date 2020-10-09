/*
 *  StriVe - A full example SoC using PicoRV32 in SkyWater s8
 *
 *  Copyright (C) 2017  Clifford Wolf <clifford@clifford.at>
 *  Copyright (C) 2018  Tim Edwards <tim@efabless.com>
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */

`timescale 1 ns / 1 ps

`include "caravel.v"
`include "spiflash.v"

module timer_tb;
	wire VDD3V3;
	assign VDD3V3 = 1'b1;

	reg clock;

	always #10 clock <= (clock === 1'b0);

	initial begin
		clock <= 0;
	end

	initial begin
		$dumpfile("timer.vcd");
		$dumpvars(0, timer_tb);

		// Repeat cycles of 1000 clock edges as needed to complete testbench
		repeat (50) begin
			repeat (1000) @(posedge clock);
			$display("+1000 cycles");
		end
		$display("%c[1;31m",27);
		$display ("Monitor: Timeout, Test GPIO (RTL) Failed");
		 $display("%c[0m",27);
		$finish;
	end

	wire [36:0] mprj_io;	// Most of these are no-connects
	wire [4:0] checkbits;
	wire [31:0] countbits;

	assign checkbits = mprj_io[36:32];
	assign countbits = mprj_io[31:0];

	wire flash_csb;
	wire flash_clk;
	wire flash_io0;
	wire flash_io1;

	reg RSTB;

	// Monitor
	initial begin
		wait(checkbits == 5'h0a);
		$display("Monitor: Test Timer (RTL) Started");

		/* Add checks here */
		wait(checkbits == 5'h01);
		$display("   countbits = 0x%x (should be 0xdcba7eb0)", countbits);
		if(countbits !== 32'hdcba7eb0) begin
		    $display("Monitor: Test Timer (RTL) Failed");
		    $finish;
		end
		wait(checkbits == 5'h02);
		$display("   countbits = 0x%x (should be 0x10)", countbits);
		if(countbits !== 32'h10) begin
		    $display("Monitor: Test Timer (RTL) Failed");
		    $finish;
		end
		wait(checkbits == 5'h03);
		$display("   countbits = %x (should be 0x0c)", countbits);
		if(countbits !== 32'h0c) begin
		    $display("Monitor: Test Timer (RTL) Failed");
		    $finish;
		end
		wait(checkbits == 5'h04);
		$display("   countbits = %x (should be 0x0c)", countbits);
		if(countbits !== 32'h0c) begin
		    $display("Monitor: Test Timer (RTL) Failed");
		    $finish;
		end
		wait(checkbits == 5'h05);
		$display("   countbits = %x (should be 0x117c)", countbits);
		if(countbits !== 32'h117c) begin
		    $display("Monitor: Test Timer (RTL) Failed");
		    $finish;
		end

		$display("Monitor: Test Timer (RTL) Passed");
		$finish;
	end

	initial begin
		RSTB <= 1'b0;
		
		#1000;
		RSTB <= 1'b1;	    // Release reset
		#2000;
	end

	always @(checkbits) begin
		#1 $display("Timer state = %b (%d)", countbits, countbits);
	end

	wire VDD1V8;
	wire VSS;

	assign VSS = 1'b0;
	assign VDD1V8 = 1'b1;

	// These are the mappings of mprj_io GPIO pads that are set to
	// specific functions on startup:
	//
	// JTAG      = mgmt_gpio_io[0]              (inout)
	// SDO       = mgmt_gpio_io[1]              (output)
	// SDI       = mgmt_gpio_io[2]              (input)
	// CSB       = mgmt_gpio_io[3]              (input)
	// SCK       = mgmt_gpio_io[4]              (input)
	// ser_rx    = mgmt_gpio_io[5]              (input)
	// ser_tx    = mgmt_gpio_io[6]              (output)
	// irq       = mgmt_gpio_io[7]              (input)

	caravel uut (
		.vddio	  (VDD3V3),
		.vssio	  (VSS),
		.vdda	  (VDD3V3),
		.vssa	  (VSS),
		.vccd	  (VDD1V8),
		.vssd	  (VSS),
		.vdda1    (VDD3V3),
		.vdda2    (VDD3V3),
		.vssa1	  (VSS),
		.vssa2	  (VSS),
		.vccd1	  (VDD1V8),
		.vccd2	  (VDD1V8),
		.vssd1	  (VSS),
		.vssd2	  (VSS),
		.clock	  (clock),
		.gpio     (gpio),
		.mprj_io  (mprj_io),
		.flash_csb(flash_csb),
		.flash_clk(flash_clk),
		.flash_io0(flash_io0),
		.flash_io1(flash_io1),
		.resetb	  (RSTB)
	);

	spiflash #(
		.FILENAME("timer.hex")
	) spiflash (
		.csb(flash_csb),
		.clk(flash_clk),
		.io0(flash_io0),
		.io1(flash_io1),
		.io2(),			// not used
		.io3()			// not used
	);

endmodule
