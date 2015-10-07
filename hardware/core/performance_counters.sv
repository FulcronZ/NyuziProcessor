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

//
// Collects statistics from various modules used for performance measuring and tuning.  
// Counts the number of discrete events in each category.
// TODO: need to expose this as device registers
//

module performance_counters
	#(parameter	NUM_COUNTERS = 1,
	parameter PRFC_WIDTH = 32,
	parameter BASE_ADDRESS = 0)

	(input                      clk,
	input                       reset,
	input[NUM_COUNTERS - 1:0]   perf_events,

	// IO bus interface
	input[31:0]					io_address,
	input						io_write_en,
	input[31:0]					io_write_data,
	input						io_read_en,
	output logic[31:0]			io_read_data);
	
	logic[PRFC_WIDTH - 1:0] event_counter[NUM_COUNTERS];
	reg[31:0] pointed_counter_idx;

	always_comb
	begin
		for (int i = 0; i < NUM_COUNTERS; i++)
		begin
			if (i == pointed_counter_idx)
				io_read_data = event_counter[i];
		end
	end

	always_ff @(posedge clk, posedge reset)
	begin : update
		if (reset)
		begin
			for (int i = 0; i < NUM_COUNTERS; i++)
				event_counter[i] <= 0;
		end
		else
		begin
			for (int i = 0; i < NUM_COUNTERS; i++)
			begin
				if (perf_events[i])
					event_counter[i] <= event_counter[i] + 1;
			end
			if (io_write_en)
				pointed_counter_idx <= io_write_data;
		end
	end
endmodule

// Local Variables:
// verilog-typedef-regexp:"_t$"
// End:
