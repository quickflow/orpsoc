/home/aray/fpga2/or1k_tools/binutils-2.16.1/binutils/objcopy -O ihex ../../../build/linux-2.6.23/arch/or32/kernel/head.o head.ihex
../../sw/utils/gen_memory_text.pl < head.ihex > flash.in
