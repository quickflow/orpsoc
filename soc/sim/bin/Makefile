# Icarus Verilog simulation defaults to LXT - but cannot be watched

# live in GTK wave though - thus VCD option included

TOPDIR := ../..

INC := -I${TOPDIR}/bench
INC += -I${TOPDIR}/bench/models
INC += -I${TOPDIR}/bench/models/28f016s3
INC += -I${TOPDIR}/bench/ATMEL_FLASH/flash_verilog/flash_verilog_w_wo_hold
INC += -I${TOPDIR}/rtl/wb_conmax/rtl/verilog
INC += -I${TOPDIR}/rtl
INC += -I${TOPDIR}/rtl/rom_wb
INC += -I${TOPDIR}/rtl/or1200/rtl/verilog
INC += -I${TOPDIR}/rtl/mem_if/rtl/verilog
INC += -I${TOPDIR}/rtl/flash_sram
#INC += -I${TOPDIR}/rtl/uart16550/rtl/verilog
INC += -I${TOPDIR}/rtl/wbuart/rtl
INC += -I${TOPDIR}/rtl/gpio/rtl/verilog
INC += -I${TOPDIR}/rtl/spi/rtl/verilog
INC += -I${TOPDIR}/rtl/ethernet/rtl/verilog
INC += -I${TOPDIR}/rtl/gfx/rtl/verilog
INC += -I${TOPDIR}/rtl/altera_pll
INC += -I${TOPDIR}/rtl/adv_debug_sys/Hardware/adv_dbg_if/rtl/verilog

sim:
	iverilog -D LXT -osim.out ${INC} -s CPUboard_tb  -c ../bin/iver.cmd
	./sim.out -lxt

sim_vcs:
	vcs -f vcs.flist
	./simv | tee output.log

show_wave:
	gtkwave ./wavedump.vcd wave_signals.sav &

sim_vcd:
	iverilog -D VCD -osim.out ${INC} -s CPUboard_tb -c ../bin/iver.cmd
	./sim.out | tee output.log

show_wave_lxt:
	gtkwave ./wavedump.lxt wave_signals.sav &

clean:
	rm -rf *.key *.log *.shm INCA* .simvision *.out *.vcd *.lxt *~

all: clean sim
