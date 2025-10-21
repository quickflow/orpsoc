../tools/or1k-linux/bin/or1k-linux-gcc -nostdlib -nostartfiles -nodefaultlibs -Wl,-Tlinker.ld -Igfx_inc -o test.o or1k_tes
t.c gfx_demo.c

../tools/or1k-linux/bin/or1k-linux-objdump -D -x test.o > test.txt

echo "@100" > tt
od -t x1 -w1 -v --skip-bytes=272 --address-radix=n test.o >> tt

