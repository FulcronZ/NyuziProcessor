// 
// Copyright 2015 Pipat Methavanitpong
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

/// Provide access and control to performance counters

`include "defines.sv"

module performance_monitor_unit
	#(parameter NUM_COUNTERS = `TOTAL_PERF_EVENTS,
	parameter COUNTER_WIDTH = 	32)

	(input 							clk,
	input 							reset,
	input logic[`TOTAL_PERF_EVENTS]	perf_events,
	input 							perf_write_en,
	input 							perf_read_en,
	input scalar_t 					perf_write_data
	output scalar_t 				perf_read_data);

	logic[NUM_COUNTERS - 1:0] counter_reset;
	logic[NUM_COUNTERS - 1:0] counter_en;
	logic[NUM_COUNTERS - 1:0] counter_inc;	///< impulse increment signal
	logic[NUM_COUNTERS - 1:0][`TOTAL_PERF_EVENTS - 1:0] counter_event_type;
	scalar_t[NUM_COUNTERS - 1:0] counter_val;	///< outputs from each counter
	logic[NUM_COUNTERS - 1:0] counter_idx;	///< select a counter to be modified

	assign perf_read_data = counter_val[counter_idx];

	always_comb
	begin
		for (int i = 0; i < NUM_COUNTERS; i++)
		begin
			counter_reset[i] = reset;	// TODO: add individual reset event
			counter_inc[i] = counter_event_type[i] == perf_events;
		end
	end

	always_ff @(posedge clk, posedge reset)
	begin
		if (reset)
		begin
			counter_idx <= 0;
			for (int i = 0; i < NUM_COUNTERS; i++)
			begin
				counter_en[i] <= 0;
				counter_event_type[i] <= 0;
			end
		end
		else
		begin
			if (perf_write_en)
			begin
				// TODO: Convert to switch tree
				if (perf_write_data *)
				begin
					counter_idx <= ;
				end
				else if (perf_write_data *)
				begin
					if (perf_write_data *)
						counter_en[counter_idx] <= 1;
					else
						counter_en[counter_idx] <= 0;
				end
				else if (perf_write_data *)
				begin
					counter_event_type[counter_idx] <= ;
				end
			end
		end
	end

	generate
		genvar i;
		for (i = 0; i < NUM_COUNTERS; i = i + 1)
		begin
			counter #(.WIDTH(COUNTER_WIDTH)) counter(
				.reset(counter_reset[i]),
				.enable(counter_en[i]),
				.increment(counter_inc[i]),
				.value(counter_val[i]));
		end
	endgenerate

endmodule
