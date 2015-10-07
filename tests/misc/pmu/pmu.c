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

#include <stdio.h>
#include <unistd.h>

#define CHECK(cond) do { if (!(cond)) { printf("FAIL: %d: %s\n", __LINE__, \
	#cond); abort(); } } while(0)

volatile unsigned int * const PMU = (volatile unsigned int*) 0xFFFF1000;

int main () 
{
	int i, a, b, c;
	// Some dummy calculation
	a = 1; b = 2; c = 3;
	for (i = 0; i < 100; i++)
	{
		if ((i << 31) > 0)
			a += b;
		else
			a += c;
	}
	
	// Read from L2 and 1st core perf events
	for (i = 0; i < 11; i++)
	{
		*PMU = i;
		printf("event[%d] = %d\n", i, *PMU);
	}

	printf("PASS\n");
	return 0;
}
