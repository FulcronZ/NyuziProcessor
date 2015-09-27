#!/usr/bin/env python
# 
# Copyright 2011-2015 Jeff Bush
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# 

import sys
import os

sys.path.insert(0, '../..')
import test_harness

FILE_SIZE = 8192
SOURCE_BLOCK_DEV = 'obj/bdevimage.bin'
EMULATOR_OUTPUT='obj/emumem.bin'
VERILATOR_OUTPUT='obj/verimem.bin'

test_harness.compile_test('sdmmc.c')

# Create random file
with open(SOURCE_BLOCK_DEV, 'wb') as f:
	f.write(os.urandom(FILE_SIZE))

print 'testing in emulator'
test_harness.run_emulator(block_device=SOURCE_BLOCK_DEV, dump_file=EMULATOR_OUTPUT, dump_base=0x200000,
	dump_length=FILE_SIZE)
if not test_harness.assert_files_equal(SOURCE_BLOCK_DEV, EMULATOR_OUTPUT):
	print "FAIL: simulator final memory contents do not match"
	sys.exit(1)

print 'testing in verilator'
test_harness.run_verilator(block_device=SOURCE_BLOCK_DEV, dump_file=VERILATOR_OUTPUT, dump_base=0x200000,
	dump_length=FILE_SIZE, extra_args=['+autoflushl2=1'])
if not test_harness.assert_files_equal(SOURCE_BLOCK_DEV, VERILATOR_OUTPUT):
	print "FAIL: verilator final memory contents do not match"
	sys.exit(1)

print 'PASS'


