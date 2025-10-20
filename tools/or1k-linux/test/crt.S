//    .section .text
    .globl _start
//    .org 0xf0000100
_start:
	// mc_ reg rf0  mc_cs_0 // csr_r2[31:24], csr_r[10:1] (init)
	//	*((unsigned int *) MC_CSR_INIT) = 0x1; 
	l.movhi r17,0x800
 	l.ori r17,r17,0x5010
 	l.ori r19,r0,0x1
 	l.sw 0(r17),r19
	// delay a while
	// *((unsigned int *) SRAM_BASE) = 0; // zero out SRAM [0]
	// while(*((unsigned int *) SRAM_BASE) < 64) {
	//   *((unsigned int *) SRAM_BASE) = *((unsigned int *) SRAM_BASE) + 1; // increment it
	// }
 	l.movhi r17,0xe000
 	l.sw 0(r17),r0
 	l.j 144 // <_start+0x44>
 	l.nop 0x0
 	l.movhi r17,0xe000
 	l.lwz r19,0(r17)
 	l.movhi r17,0xe000
 	l.addi r19,r19,1
 	l.sw 0(r17),r19
 	l.movhi r17,0xe000
 	l.lwz r19,0(r17)
 	l.ori r17,r0,0x3f
 	l.sfleu r19,r17
 	l.bf 130 // <_start+0x30>
 	l.nop 0x0

	// load mode reg req mc_cs_0 [CAS latency=2, Sequential Burst Type, Programmed Burst Length]
	// *((unsigned int *) (MC_CSR_BASE + 0x14)) = 0x22;
 	l.movhi r17,0x800

	// Optional: clear r1 (stack pointer) if not used
	l.ori   r1, r0, 0x0000

	// Optional: clear other registers
	l.movhi r2, 0x0000
	l.movhi r3, 0x0000

	// Jump to main in DRAM
	l.movhi r4, 0x0000        // upper 16 bits of 0x00000000
	l.ori   r4, r4, 0x0000    // lower 16 bits
	l.jr    r4
	l.nop                     // delay slot

	
