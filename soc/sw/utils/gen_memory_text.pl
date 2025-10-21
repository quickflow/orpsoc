#!/usr/bin/perl
#
#===============================================================================
#
#         FILE:  gen_memory_text.pl
#
#  DESCRIPTION:  Translate Intel Hex format file into memory text file  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:   (), <>
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  04/15/2009 01:06:49 PM HKT
#     REVISION:  ---
#===============================================================================

#my @data;

# Intel HEX format interpreter
while(<>) {
  if (m/\:([A-F0-9]{2})([A-F0-9]{4})([A-F0-9]{2})([A-F0-9]+)([A-F0-9]{2})/) {
    my $vec = $4;
    my $len = hex $1;
    my $rec_type = $3;
    my $byte_addr = (hex $2);
    if ($len > 0) {
      for (my($i)=0; $i < $len*2; $i+=2) {
#        $data[$byte_addr++] = hex substr($vec, $i, 2);
		printf ("%2.2x\n", hex substr($vec, $i, 2));
      }
    }
  }
}

