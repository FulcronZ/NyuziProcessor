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

#include <schedule.h>
#include <stdio.h>

//
// This test only works with 8 cores enabled
// In hardware/core/config.sv, set NUM_CORES to 8
//

static volatile int gCurrentThread = 0;
const int kNumThreads = 32;

int main(int argc, const char *argv[])
{
	int myThreadId = __builtin_nyuzi_read_control_reg(0);
	
	startAllThreads();
	
	for (;;)
	{
		while (gCurrentThread != myThreadId)
			;

		printf("%d\n", myThreadId);
		gCurrentThread = (gCurrentThread + 1) % kNumThreads;
	}
}
