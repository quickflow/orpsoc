
#define MC_CSR_BASE 0x08005000
#define MC_CSR_INIT (MC_CSR_BASE + 0x10)
#define MC_CSR_LMR  (MC_CSR_BASE + 0x14)

#define DRAM_BASE   0x00000000

#define SRAM_BASE   0xE0000000

#define FLASH_BASE  0xF0000000

#define GPIO_BASE   0x40000000
#define GPIO_IN     (GPIO_BASE + 0x00)
#define GPIO_OUT    (GPIO_BASE + 0x04)
#define GPIO_OEN    (GPIO_BASE + 0x08)

#define GFX_BASE    0x60000000

extern void gfx_demo();

void main()
{
  *((unsigned int *) MC_CSR_INIT) = 0x1; // mc_ reg rf0  mc_cs_0 // csr_r2[31:24], csr_r[10:1] (init)

  // delay a while
  *((unsigned int *) SRAM_BASE) = 0; // zero out SRAM [0]
  while(*((unsigned int *) SRAM_BASE) < 64) {
    *((unsigned int *) SRAM_BASE) = *((unsigned int *) SRAM_BASE) + 1; // increment it
  }

  // try lmr ?
  *((unsigned int *) (MC_CSR_BASE + 0x14)) = 0x22; // load mode reg req mc_cs_0 [CAS latency=2, Sequential Burst Type, Pro
grammed Burst Length]

  // try writes
  *((unsigned int *) (DRAM_BASE + 0x5000)) = 0x11111111;
  *((unsigned int *) (DRAM_BASE + 0x5004)) = 0x22222222;
  *((unsigned int *) (DRAM_BASE + 0x5008)) = 0x33333333;
  *((unsigned int *) (DRAM_BASE + 0x500c)) = 0x44444444;

  // try reads
  *((unsigned int *) (DRAM_BASE + 0x8000)) = *((unsigned int *) (DRAM_BASE + 0x5000));
  *((unsigned int *) (DRAM_BASE + 0x8004)) = *((unsigned int *) (DRAM_BASE + 0x5004));
  *((unsigned int *) (DRAM_BASE + 0x8008)) = *((unsigned int *) (DRAM_BASE + 0x5008));
  *((unsigned int *) (DRAM_BASE + 0x800c)) = *((unsigned int *) (DRAM_BASE + 0x500c));

  *((unsigned int *) GPIO_OEN) = 0xff;
  *((unsigned int *) GPIO_OUT) = 0x00;
  *((unsigned int *) GPIO_OUT) |= (*((unsigned int *) 0x8000) == 0x11111111);
  *((unsigned int *) GPIO_OUT) |= (*((unsigned int *) 0x8004) == 0x22222222) << 1;
  *((unsigned int *) GPIO_OUT) |= (*((unsigned int *) 0x8008) == 0x33333333) << 2;
  *((unsigned int *) GPIO_OUT) |= (*((unsigned int *) 0x800c) == 0x44444444) << 3;

  gfx_demo();
}
