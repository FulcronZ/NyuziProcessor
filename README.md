# Nyuzi Processor

Nyuzi is an experimental multicore GPGPU processor. It supports vector floating
point, hardware multithreading, and cache coherence. The SystemVerilog-based 
hardware implementation is synthesizable and runs on FPGA. This project also 
includes an LLVM-based C++ toolchain, a symbolic debugger, an emulator, software 
libraries, and hardware verification tests. It is useful for microarchitecture 
experimentation, performance modeling, and parallel software development.

I've attempted to make this easy to set up and highly hackable. It uses free and
mostly open source tools. Contributions are welcome, please see 
[CONTRIBUTING](CONTRIBUTING.md) for more details.

**Documentation:** https://github.com/jbush001/NyuziProcessor/wiki  
**Mailing list:** https://groups.google.com/forum/#!forum/nyuzi-processor-dev   
**License:** Apache 2.0    
**Blog:** http://latchup.blogspot.com/   
[![Chat at https://gitter.im/jbush001/NyuziProcessor](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/jbush001/NyuziProcessor?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

# Getting Started

The following instructions explain how to get the Nyuzi development environment
set up. This allows cycle-accurate simulation of the hardware and software 
development using the emulator. It does not require an FPGA.

If you have issues, feel free to send a message to the mailing list or Gitter 
(links above).

These instructions assume you have cloned this repo locally and have a shell open 
in the top directory.

## Install Prerequisites


### Linux (Ubuntu)

This requires Ubuntu 14 or later to get the proper package versions. It should
work for other distributions, but you will probably need to modify some 
package names.

	sudo apt-get -y install cmake make gcc g++ bison flex python perl emacs curl openjdk-7-jdk swig zlib1g-dev python-dev libxml2-dev libedit-dev ncurses-dev libsdl2-dev gtkwave imagemagick 

*Emacs is used for [verilog-mode](http://www.veripool.org/wiki/verilog-mode) AUTO macros. 
The makefile executes this operation in batch mode*

### MacOS

These instructions assume Mavericks or later.  If you don't have XCode
already, install the command line tools like this:

    xcode-select --install

This installs the remaining packages using [MacPorts](https://www.macports.org/):

    sudo port install cmake bison swig swig-python imagemagick libsdl2 curl emacs

You may optionally also want to install [GTKWave](http://gtkwave.sourceforge.net/) 
for analyzing waveform files.

### Windows

I have not tested this on Windows. Many of the libraries are already cross
platform, so it should theoretically be possible. The easiest route is probably
to run Linux under VirtualBox or VMWare.

## Build (Linux & MacOS)

Download and build Verilator as follows (while some Linux package managers have
this, it is way out of date):

    cd tools
    curl http://www.veripool.org/ftp/verilator-3.876.tgz | tar xz
    cd verilator-3.876/ 
    ./configure 
    make
    sudo make install
    cd ../..

Download and build the Nyuzi toolchain as follows (This clones my repo. If you
want to use your own fork, change the clone URL):

    git clone https://github.com/jbush001/NyuziToolchain.git tools/NyuziToolchain
    cd tools/NyuziToolchain
    mkdir build
    cd build
    cmake .. 
    make
    sudo make install
    cd ../../..
	
Build remaining tools and hardware model. Run unit tests.

    make
    make test

## What next?

Various sample applications are available in [software/apps](software/apps).
These can be run in the emulator by typing 'make run' (some may require
downloading 3rd party data files, details are in the READMEs in those
directories). 

For example, this will render a 3D model:

    cd software/apps/sceneview
    make run

# Running on FPGA

See instructions in hardware/fpga/de2-115/README.md
