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
// Accepts IO requests from all cores and serializes requests to external
// IO interface. Sends responses back to cores.
//

module io_arbiter(
	input                     clk,
	input                     reset,
	input ioreq_packet_t      io_request[`NUM_CORES],
	output logic              ia_ready[`NUM_CORES],
	output iorsp_packet_t     ia_response,

	// Non-cacheable memory signals
	output logic              io_write_en,
	output logic              io_read_en,
	output scalar_t           io_address,
	output scalar_t           io_write_data,
	input scalar_t            io_read_data);

	logic[`NUM_CORES - 1:0] arb_request;
	core_id_t grant_idx;
	logic[`NUM_CORES - 1:0] grant_oh;
	logic request_sent;
	core_id_t request_core;
	thread_idx_t request_thread_idx;
	ioreq_packet_t grant_request;

	genvar request_idx;
	generate
		for (request_idx = 0; request_idx < `NUM_CORES; request_idx++)
		begin : handshake_gen
			assign arb_request[request_idx] = io_request[request_idx].valid;
			assign ia_ready[request_idx] = grant_oh[request_idx];
		end
	endgenerate

	generate
		if (`NUM_CORES > 1)
		begin
			arbiter #(.NUM_REQUESTERS(`NUM_CORES)) arbiter_request(
				.request(arb_request),
				.update_lru(1'b1),
				.grant_oh(grant_oh),
				.*);

			oh_to_idx #(.NUM_SIGNALS(`NUM_CORES)) oh_to_idx_grant(
				.one_hot(grant_oh),
				.index(grant_idx[`CORE_ID_WIDTH - 1:0]));

			assign grant_request = io_request[grant_idx[`CORE_ID_WIDTH - 1:0]];
		end
		else
		begin
			assign grant_oh[0] = arb_request[0];
			assign grant_idx = 0;
			assign grant_request = io_request[0];
		end
	endgenerate

	assign io_write_en = |grant_oh && grant_request.is_store;
	assign io_read_en = |grant_oh && !grant_request.is_store;
	assign io_write_data = grant_request.value;
	assign io_address = grant_request.address;

	always_ff @(posedge clk, posedge reset)
	begin
		if (reset)
		begin
			ia_response <= '0;

			`ifdef NEVER
			// Suppress AUTORESET
			ia_response.core <= '0;
			ia_response.read_value <= '0;
			ia_response.thread_idx <= '0;
			ia_response.valid <= '0;
			`endif

			/*AUTORESET*/
			// Beginning of autoreset for uninitialized flops
			request_core <= '0;
			request_sent <= '0;
			request_thread_idx <= '0;
			// End of automatics
		end
		else
		begin
			if (|grant_oh)
			begin
				// Send a new request
				request_sent <= 1;
				request_core <= grant_idx;
				request_thread_idx <= grant_request.thread_idx;
			end
			else
				request_sent <= 0;

			if (request_sent)
			begin
				// Next cycle after request, record response
				ia_response.valid <= 1;
				ia_response.core <= request_core;
				ia_response.thread_idx <= request_thread_idx;
				ia_response.read_value <= io_read_data;
			end
			else
				ia_response.valid <= 0;
		end
	end
endmodule

// Local Variables:
// verilog-typedef-regexp:"_t$"
// verilog-auto-reset-widths:unbased
// End:


