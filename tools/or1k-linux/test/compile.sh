../bin/or1k-linux-gcc -nostdlib -nostartfiles -nodefaultlibs -Wl,-Tlinker.ld -Igfx_inc -o test.o or1k_test.c gfx_demo.c

../bin/or1k-linux-objdump -D -x test.o > test.txt

echo "@100" > tt
od -t x1 -w1 -v --skip-bytes=272 --address-radix=n test.o >> tt
