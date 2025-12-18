#!/bin/sh
mkdir work
$VCS_HOME/bin/vlogan -full64 -work work -sverilog -f vcs.flist +define+MEMORY_FILE=\"./bench/ATMEL_FLASH/flash_verilog/flash_verilog_w_wo_hold/memory.txt\" -timescale=1ns/1ns +incdir+./rtl/gfx/rtl/verilog/+./bench/ATMEL_FLASH/flash_verilog/simple_model+./sim/bin  
$VCS_HOME/bin/vcs -full64 -top work.or1k_soc_top -hw_top=or1k_soc_top -timescale=1ns/1ns 




