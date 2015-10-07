// 
// Copyright 2011-2015 Jeff Bush
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// 

`include "defines.sv"

//
// Top level block for processor.  Contains all cores and L2 cache, connects
// to AXI system bus.
//

module nyuzi
	#(parameter RESET_PC = 0)

	(input                 clk,
	input                 reset,
	axi4_interface.master axi_bus,
	output                processor_halt,
	input                 interrupt_req,

	// Non-cacheable memory signals
	output                io_write_en,
	output                io_read_en,
	output scalar_t       io_address,
	output scalar_t       io_write_data,
	input scalar_t        io_read_data);

	l2req_packet_t l2i_request[`NUM_CORES];
	l2rsp_packet_t l2_response;
	logic l2_ready[`NUM_CORES];
	ioreq_packet_t io_request[`NUM_CORES];
	logic ia_ready[`NUM_CORES];
	iorsp_packet_t ia_response;
	logic perf_l2_hit;		
	logic perf_l2_miss;		
	logic perf_l2_writeback;	
	logic[`TOTAL_THREADS - 1:0] ny_thread_enable;
	logic[`TOTAL_PERF_EVENTS - 1:0] perf_events;

	initial
	begin
		assert(`NUM_CORES >= 1 && `NUM_CORES <= (1 << `CORE_ID_WIDTH));
	end

	assign processor_halt = ny_thread_enable == 0;

	genvar core_idx;
	generate
		for (core_idx = 0; core_idx < `NUM_CORES; core_idx++)
		begin : core_gen
			core #(.CORE_ID(core_id_t'(core_idx)), .RESET_PC(RESET_PC)) core(
				.l2i_request(l2i_request[core_idx]),
				.l2_ready(l2_ready[core_idx]),
				.ny_thread_enable(ny_thread_enable[core_idx * `THREADS_PER_CORE+:`THREADS_PER_CORE]),
				.ior_request(io_request[core_idx]),
				.ia_ready(ia_ready[core_idx]),
				.ia_response(ia_response),
				.core_perf_events(perf_events[`L2_PERF_EVENTS + `CORE_PERF_EVENTS * core_idx+:`CORE_PERF_EVENTS]),
				.*);
		end
	endgenerate
	
	always_ff @(posedge clk, posedge reset)
	begin
		if (reset)
			ny_thread_enable <= 1;
		else if (io_write_en)
		begin
			// Thread mask  This is limited to 32 threads.
			// To add more, put the next 32 bits in subsequent io addresses.
			if (io_address == 'h60) // resume thread
				ny_thread_enable <= ny_thread_enable | io_write_data[`TOTAL_THREADS - 1:0];	
			else if (io_address == 'h64) // halt thread
				ny_thread_enable <= ny_thread_enable & ~io_write_data[`TOTAL_THREADS - 1:0];	
		end
	end
	
	l2_cache l2_cache(
		.l2_perf_events(perf_events[`L2_PERF_EVENTS - 1:0]),
		.*);

	// XXX: Multiplex io_read_data to get perf counter on it
	logic[31:0] io_arbiter_read_data;
	io_arbiter io_arbiter(.io_read_data(io_arbiter_read_data),
		.*);

	localparam COUNTER_WIDTH = 32;
	localparam PMU_ADDR = 32'hffff1000;

	wire[31:0] perf_read_data;
	performance_counters #(.NUM_COUNTERS(`TOTAL_PERF_EVENTS), 
		.PRFC_WIDTH(COUNTER_WIDTH),
		.BASE_ADDRESS(PMU_ADDR)) performance_counters(
		.io_read_data(perf_read_data),
		.*);

	reg perf_sel;
	always_ff @(posedge clk, posedge reset)
	begin
		if (reset)
			perf_sel <= 0;
		else
		begin
			if (io_read_en)
			begin
				if (io_address[15:0] == 16'h1000)
					perf_sel <= 1;
				else
					perf_sel <= 0;
			end
		end
	end

	always_comb
	begin
		if (perf_sel)
			io_arbiter_read_data = perf_read_data;
		else
			io_arbiter_read_data = io_read_data;
	end

endmodule

// Local Variables:
// verilog-typedef-regexp:"_t$"
// End:
