#!/usr/bin/perl
# 2005 - David Grant.
# Take an ihex input from STDIN, and write a .mif file to STDOUT
# This script could probably be implemented with something like:
#    $#!@_%^$@%$@%$_!^$@#^@%$#@_%$@^&!%$_!%!%&$*(#^#@%^) 
# But I perfer the somewhat readable version.

# Flow from within the Nios2 SDK Shell:
# nios2-elf-as file.asm -o file.o
# nios2-elf-objcopy file.o --target ihex file.hex
# cat file.hex | perl hex2mif.pl > file.mif

sub conv {
	my ($in) = @_;
#	$out = substr($in,6,2).substr($in,4,2).substr($in,2,2).substr($in,0,2);
	$out = substr($in,0,2).substr($in,2,2).substr($in,4,2).substr($in,6,2);
	return hex $out;
}

my @code = ();

while (<STDIN>) {
	$l = $_;
	$count = (hex substr($l, 1, 2)) / 4;
	$addr = (hex substr($l, 3, 4)) / 4;
	$type = (hex substr($l, 7, 2));
	last if $type eq 1;
	for($x=0; $x<$count; $x++) {
		$code[$addr + $x] = conv(substr($l, 9+8*$x, 8)) ;
	}
}

print("WIDTH=32;\n");
print("DEPTH=".@code.";\n");
print("CONTENT BEGIN\n");
for($x=0; $x<@code; $x++) {
	printf("\t%08x : %08x;\n", $x, $code[$x]);
}
print("END;\n");

