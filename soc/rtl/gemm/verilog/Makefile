# Icarus Verilog simulation defaults to LXT - but cannot be watched

# live in GTK wave though - thus VCD option included

TOPDIR := ../..

sim:
	iverilog -g2012 -o gemm_dp_tb tb_gemm_packed_pipe_dp.v gemm_dma_packed_pipe_dp.v dp_ram.v wishbone_mem.v
	vvp gemm_dp_tb -lxt2 |tee output.log

show_wave_lxt:
	gtkwave ./gemm_packet_pipe_dp.lxt2 wave_signals.sav &

clean:
	rm -rf *.log *.out *.lxt *~

all: clean sim
