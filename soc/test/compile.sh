../../tools/or1k-linux/bin/or1k-linux-gcc -nostdlib -nostartfiles -nodefaultlibs -Wl,-Tlinker.ld -o test.o or1k_test.c

../../tools/or1k-linux/bin/or1k-linux-objdump -D -x test.o > test.txt
