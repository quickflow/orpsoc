#include "orgfx_regs.h"

#define SRAM_BASE   0xE0000000

#define REG(reg_name) (*((unsigned int *) (reg_name)))

void gfx_demo()
{
  
  REG(SRAM_BASE + 0x1000) = REG(GFX_STATUS);
  REG(SRAM_BASE + 0x1004) = REG(GFX_ALPHA);
  REG(SRAM_BASE + 0x1008) = REG(GFX_CONTROL);
  REG(SRAM_BASE + 0x100c) = REG(GFX_COLORKEY);
}


