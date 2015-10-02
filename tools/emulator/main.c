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

#include <errno.h>
#include <getopt.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>
#include <sys/resource.h>
#include <stdlib.h>
#include "core.h"
#include "cosimulation.h"
#include "device.h"
#include "fbwindow.h"

extern void remoteGdbMainLoop(Core *core, int enableFbWindow);

static void usage(void)
{
	fprintf(stderr, "usage: emulator [options] <hex image file>\n");
	fprintf(stderr, "options:\n");
	fprintf(stderr, "  -v Verbose, will print register transfer traces to stdout\n");
	fprintf(stderr, "  -m Mode, one of:\n");
	fprintf(stderr, "     normal  Run to completion (default)\n");
	fprintf(stderr, "     cosim   Cosimulation validation mode\n");
	fprintf(stderr, "     gdb     Start GDB listener on port 8000\n");
	fprintf(stderr, "  -f <width>x<height> Display framebuffer output in window\n");
	fprintf(stderr, "  -d <filename>,<start>,<length>  Dump memory\n");
	fprintf(stderr, "  -b <filename> Load file into a virtual block device\n");
	fprintf(stderr, "  -t <num> Total threads (default 4)\n");
	fprintf(stderr, "  -c <size> Total amount of memory\n");
	fprintf(stderr, "  -r <cycles> Refresh rate, cycles between each screen update\n");
}

static uint32_t parseNumArg(const char *argval)
{
	if (argval[0] == '0' && argval[1] == 'x')
		return (uint32_t) strtoul(argval + 2, NULL, 16);
	else
		return (uint32_t) strtoul(argval, NULL, 10);
}

int main(int argc, char *argv[])
{
	Core *core;
	int option;
	bool enableMemoryDump = false;
	uint32_t memDumpBase = 0;
	uint32_t memDumpLength = 0;
	char memDumpFilename[256];
	bool verbose = false;
	uint32_t fbWidth = 640;
	uint32_t fbHeight = 480;
	bool blockDeviceOpen = false;
	bool enableFbWindow = false;
	uint32_t totalThreads = 4;
	char *separator;
	uint32_t memorySize = 0x1000000;
	
	enum
	{
		MODE_NORMAL,
		MODE_COSIMULATION,
		MODE_GDB_REMOTE_DEBUG
	} mode = MODE_NORMAL;

#if 0
	// Enable coredumps for this process
    struct rlimit limit;
	limit.rlim_cur = RLIM_INFINITY;
	limit.rlim_max = RLIM_INFINITY;
	setrlimit(RLIMIT_CORE, &limit);
#endif

	while ((option = getopt(argc, argv, "if:d:vm:b:t:c:r:")) != -1)
	{
		switch (option)
		{
			case 'v':
				verbose = true;
				break;
				
			case 'r':
				gScreenRefreshRate = parseNumArg(optarg);
				break;
				
			case 'f':
				enableFbWindow = true;
				separator = strchr(optarg, 'x');
				if (!separator)
				{
					fprintf(stderr, "Invalid framebuffer size %s\n", optarg);
					return 1;
				}

				fbWidth = parseNumArg(optarg);
				fbHeight = parseNumArg(separator + 1);
				break;
				
			case 'm':
				if (strcmp(optarg, "normal") == 0)
					mode = MODE_NORMAL;
				else if (strcmp(optarg, "cosim") == 0)
					mode = MODE_COSIMULATION;
				else if (strcmp(optarg, "gdb") == 0)
					mode = MODE_GDB_REMOTE_DEBUG;
				else
				{
					fprintf(stderr, "Unkown execution mode %s\n", optarg);
					return 1;
				}

				break;
				
			case 'd':
				// Memory dump, of the form:
				//  filename,start,length
				separator = strchr(optarg, ',');
				if (separator == NULL)
				{
					fprintf(stderr, "bad format for memory dump\n");
					usage();
					return 1;
				}
				
				strncpy(memDumpFilename, optarg, separator - optarg);
				memDumpFilename[separator - optarg] = '\0';
				memDumpBase = parseNumArg(separator + 1);
	
				separator = strchr(separator + 1, ',');
				if (separator == NULL)
				{
					fprintf(stderr, "bad format for memory dump\n");
					usage();
					return 1;
				}
				
				memDumpLength = parseNumArg(separator + 1);
				enableMemoryDump = true;
				break;
				
			case 'b':
				if (openBlockDevice(optarg) < 0)
					return 1;
				
				blockDeviceOpen = true;
				break;
			
			case 'c':
				memorySize = parseNumArg(optarg);
				break;
				
			case 't':
				totalThreads = parseNumArg(optarg);
				if (totalThreads < 1 || totalThreads > 32)
				{
					fprintf(stderr, "Total threads must be between 1 and 32\n");
					return 1;
				}
				
				break;
				
			case '?':
				usage();
				return 1;
		}
	}

	if (optind == argc)
	{
		fprintf(stderr, "No image filename specified\n");
		usage();
		return 1;
	}

	// We don't randomize memory for cosimulation mode, because 
	// memory is checked against the hardware model to ensure a match

	core = initCore(memorySize, totalThreads, mode != MODE_COSIMULATION);
	if (core == NULL)
		return 1;
	
	if (loadHexFile(core, argv[optind]) < 0)
	{
		fprintf(stderr, "Error reading image %s\n", argv[optind]);
		return 1;
	}

	if (enableFbWindow)
	{
		if (initFramebuffer(fbWidth, fbHeight) < 0)
			return 1;
	}

	switch (mode)
	{
		case MODE_NORMAL:
			if (verbose)
				enableTracing(core);
			
			setStopOnFault(core, true);
			if (enableFbWindow)
			{
				while (executeInstructions(core, ALL_THREADS, gScreenRefreshRate))
				{
					updateFramebuffer(getFramebuffer(core));
					pollEvent();
				}
			}
			else
				executeInstructions(core, ALL_THREADS, 0x7fffffffu);

			break;

		case MODE_COSIMULATION:
			setStopOnFault(core, false);
			if (runCosimulation(core, verbose) < 0)
				return 1;	// Failed

			break;
			
		case MODE_GDB_REMOTE_DEBUG:
			setStopOnFault(core, true);
			remoteGdbMainLoop(core, enableFbWindow);
			break;
	}

	if (enableMemoryDump)
		writeMemoryToFile(core, memDumpFilename, memDumpBase, memDumpLength);

	dumpInstructionStats(core);
	if (blockDeviceOpen)
		closeBlockDevice();
	
	return 0;
}
