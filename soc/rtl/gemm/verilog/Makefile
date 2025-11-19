# Icarus Verilog simulation defaults to LXT - but cannot be watched

# live in GTK wave though - thus VCD option included

TOPDIR := ../..

sim:
	iverilog -disable-timing -D LXT2 -osim.out -s tb_conv_accel  -c iver.cmd
	./sim.out -lxt2  | tee output.log

show_wave_lxt:
	gtkwave ./wavedump.lxt2 wave_signals.sav &

clean:
	rm -rf *.log *.out *.lxt *~

all: clean sim
