/* Use internal memory*/

MEMORY    
{
    ld_info     : ORIGIN = 0xF0000000, LENGTH = 0x000000F0 
    vectors     : ORIGIN = 0xF0000100, LENGTH = 0x00000D00 - 0x100
    flash       : ORIGIN = 0xF0000D00, LENGTH = 0x00002000 - 0x0A00
    ram         : ORIGIN = 0xF0003000, LENGTH = 0x00001000
}
 
/*
  The following section defines where to put the different input sections.
  .text contains the code.
  .data contains the initialized data.
  .bss contains uninitialized data.
  .sdata contains small constant data.
*/

SECTIONS
{

      .ld_info :
      {
        revision.o(.data)        
      } > ld_info

    .vectors :   { *(.vectors) }    > vectors

    .text :     { *(.text)  }       > flash

    . = ALIGN (0x20);
    __end = .;
   

    .rodata :   { *(.rodata)}       > flash 
    .rodata.str1.1 :   { *(.rodata.str1.1)}       > flash 
    .rodata.cst4 :   { *(.rodata.cst4)}       > flash
    .data :     { *(.data)  }       > ram
    .bss :      { *(.bss)   }       > ram

    .stack :
    {
        __STACK_TOP    = . ;
        . = . + 0x500;
        __STACK_BOTTOM = . ;
    }                               > ram

}

/*
  Definitions of identifiers that control initialization and memory allocation:
  These two symbols must be present.
   __BSS_START  : Start of uninitialized data
   __BSS_END    : End of data to be cleared
*/

__CODE_START  = ADDR( .text );
__CODE_END    = ADDR( .text ) + SIZEOF( .text );

__DATA_START  = ADDR( .bss );
__DATA_END    = ADDR( .bss ) + SIZEOF( .bss );
