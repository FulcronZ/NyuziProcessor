//
// Copyright 2015 Jeff Bush
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
#include <string.h>
#include "mmu_test_common.h"

//
// This creates two virtual mappings to the same physical address
// (cache synonym) and ensures the value written in one is readable
// in the other.
//

extern void tlb_miss_handler();

// The TLB handler makes memory wrap every 4 MB
// The MMU maps these to physical address 0x100000.
char *tmp1 = (char*) 0x500000;
char *tmp2 = (char*) 0x900000;

int main(void)
{
	__builtin_nyuzi_write_control_reg(CR_TLB_MISS_HANDLER, tlb_miss_handler);
	__builtin_nyuzi_write_control_reg(CR_FLAGS, FLAG_MMU_EN | FLAG_SUPERVISOR_EN);

	// Test that stores are properly translated. Test harness will read
	// physical memory. This should be written to 1MB.
	strcpy(tmp1, "Test String");

	// Test that loads are properly mapped. This should alias to tmp1
	printf("read %p \"%s\"\n", tmp2, tmp2);

	// Flush first address so it will be in memory dump.
	asm("dflush %0" : : "s" (tmp1));

	return 0;
}
