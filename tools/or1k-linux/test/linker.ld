/* linker.ld */
ENTRY(_start)

SECTIONS {
	 . = 0x100;

	 .text : {
	       *(.text)
	 }

	 .data : {
	       *(.data)
	 }

	 .bss : {
	       *(.bss)
	 }

}

