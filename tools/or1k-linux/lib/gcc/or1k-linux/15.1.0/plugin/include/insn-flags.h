/* Generated automatically by the program `genflags'
   from the machine description file `md'.  */

#ifndef GCC_INSN_FLAGS_H
#define GCC_INSN_FLAGS_H

#define HAVE_nop 1
#define HAVE_addsi3 1
#define HAVE_mulsi3 (!TARGET_SOFT_MUL)
#define HAVE_divsi3 (!TARGET_SOFT_DIV)
#define HAVE_udivsi3 (!TARGET_SOFT_DIV)
#define HAVE_subsi3 1
#define HAVE_addsf3 (TARGET_HARD_FLOAT)
#define HAVE_subsf3 (TARGET_HARD_FLOAT)
#define HAVE_mulsf3 (TARGET_HARD_FLOAT)
#define HAVE_divsf3 (TARGET_HARD_FLOAT)
#define HAVE_adddf3 ((TARGET_HARD_FLOAT) && (TARGET_DOUBLE_FLOAT))
#define HAVE_subdf3 ((TARGET_HARD_FLOAT) && (TARGET_DOUBLE_FLOAT))
#define HAVE_muldf3 ((TARGET_HARD_FLOAT) && (TARGET_DOUBLE_FLOAT))
#define HAVE_divdf3 ((TARGET_HARD_FLOAT) && (TARGET_DOUBLE_FLOAT))
#define HAVE_floatsisf2 (TARGET_HARD_FLOAT)
#define HAVE_floatdidf2 ((TARGET_HARD_FLOAT) && (TARGET_DOUBLE_FLOAT))
#define HAVE_fix_truncsfsi2 (TARGET_HARD_FLOAT)
#define HAVE_fix_truncdfdi2 ((TARGET_HARD_FLOAT) && (TARGET_DOUBLE_FLOAT))
#define HAVE_ashlsi3 1
#define HAVE_ashrsi3 1
#define HAVE_lshrsi3 1
#define HAVE_rotrsi3 (TARGET_ROR || TARGET_RORI)
#define HAVE_andsi3 1
#define HAVE_xorsi3 1
#define HAVE_iorsi3 1
#define HAVE_movsi_high 1
#define HAVE_zero_extendqisi2 1
#define HAVE_zero_extendhisi2 1
#define HAVE_extendqisi2 (TARGET_SEXT)
#define HAVE_extendhisi2 (TARGET_SEXT)
#define HAVE_jump 1
#define HAVE_indirect_jump 1
#define HAVE_set_got_tmp 1
#define HAVE_set_got 1
#define HAVE_frame_addsi3 (reload_completed)
#define HAVE_load_locked_si 1
#define HAVE_store_conditional_si 1
#define HAVE_one_cmplsi2 1
#define HAVE_movqi 1
#define HAVE_movhi 1
#define HAVE_movsi 1
#define HAVE_movdi 1
#define HAVE_cstoresi4 1
#define HAVE_cstoresf4 (TARGET_HARD_FLOAT)
#define HAVE_cstoredf4 ((TARGET_HARD_FLOAT) && (TARGET_DOUBLE_FLOAT))
#define HAVE_sne_sr_f 1
#define HAVE_movqicc 1
#define HAVE_movhicc 1
#define HAVE_movsicc 1
#define HAVE_cbranchsi4 1
#define HAVE_cbranchsf4 (TARGET_HARD_FLOAT)
#define HAVE_cbranchdf4 ((TARGET_HARD_FLOAT) && (TARGET_DOUBLE_FLOAT))
#define HAVE_prologue 1
#define HAVE_epilogue 1
#define HAVE_sibcall_epilogue 1
#define HAVE_simple_return 1
#define HAVE_eh_return 1
#define HAVE_mem_thread_fence 1
#define HAVE_msync 1
#define HAVE_atomic_compare_and_swapsi 1
#define HAVE_atomic_compare_and_swapqi 1
#define HAVE_atomic_compare_and_swaphi 1
#define HAVE_atomic_exchangesi 1
#define HAVE_atomic_exchangeqi 1
#define HAVE_atomic_exchangehi 1
#define HAVE_atomic_addsi 1
#define HAVE_atomic_subsi 1
#define HAVE_atomic_orsi 1
#define HAVE_atomic_xorsi 1
#define HAVE_atomic_andsi 1
#define HAVE_atomic_nandsi 1
#define HAVE_atomic_addqi 1
#define HAVE_atomic_subqi 1
#define HAVE_atomic_orqi 1
#define HAVE_atomic_xorqi 1
#define HAVE_atomic_andqi 1
#define HAVE_atomic_nandqi 1
#define HAVE_atomic_addhi 1
#define HAVE_atomic_subhi 1
#define HAVE_atomic_orhi 1
#define HAVE_atomic_xorhi 1
#define HAVE_atomic_andhi 1
#define HAVE_atomic_nandhi 1
#define HAVE_atomic_fetch_addsi 1
#define HAVE_atomic_fetch_subsi 1
#define HAVE_atomic_fetch_orsi 1
#define HAVE_atomic_fetch_xorsi 1
#define HAVE_atomic_fetch_andsi 1
#define HAVE_atomic_fetch_nandsi 1
#define HAVE_atomic_fetch_addqi 1
#define HAVE_atomic_fetch_subqi 1
#define HAVE_atomic_fetch_orqi 1
#define HAVE_atomic_fetch_xorqi 1
#define HAVE_atomic_fetch_andqi 1
#define HAVE_atomic_fetch_nandqi 1
#define HAVE_atomic_fetch_addhi 1
#define HAVE_atomic_fetch_subhi 1
#define HAVE_atomic_fetch_orhi 1
#define HAVE_atomic_fetch_xorhi 1
#define HAVE_atomic_fetch_andhi 1
#define HAVE_atomic_fetch_nandhi 1
#define HAVE_atomic_add_fetchsi 1
#define HAVE_atomic_sub_fetchsi 1
#define HAVE_atomic_or_fetchsi 1
#define HAVE_atomic_xor_fetchsi 1
#define HAVE_atomic_and_fetchsi 1
#define HAVE_atomic_nand_fetchsi 1
#define HAVE_atomic_add_fetchqi 1
#define HAVE_atomic_sub_fetchqi 1
#define HAVE_atomic_or_fetchqi 1
#define HAVE_atomic_xor_fetchqi 1
#define HAVE_atomic_and_fetchqi 1
#define HAVE_atomic_nand_fetchqi 1
#define HAVE_atomic_add_fetchhi 1
#define HAVE_atomic_sub_fetchhi 1
#define HAVE_atomic_or_fetchhi 1
#define HAVE_atomic_xor_fetchhi 1
#define HAVE_atomic_and_fetchhi 1
#define HAVE_atomic_nand_fetchhi 1
#define HAVE_call 1
#define HAVE_sibcall 1
#define HAVE_call_value 1
#define HAVE_sibcall_value 1
extern rtx        gen_nop                       (void);
extern rtx        gen_addsi3                    (rtx, rtx, rtx);
extern rtx        gen_mulsi3                    (rtx, rtx, rtx);
extern rtx        gen_divsi3                    (rtx, rtx, rtx);
extern rtx        gen_udivsi3                   (rtx, rtx, rtx);
extern rtx        gen_subsi3                    (rtx, rtx, rtx);
extern rtx        gen_addsf3                    (rtx, rtx, rtx);
extern rtx        gen_subsf3                    (rtx, rtx, rtx);
extern rtx        gen_mulsf3                    (rtx, rtx, rtx);
extern rtx        gen_divsf3                    (rtx, rtx, rtx);
extern rtx        gen_adddf3                    (rtx, rtx, rtx);
extern rtx        gen_subdf3                    (rtx, rtx, rtx);
extern rtx        gen_muldf3                    (rtx, rtx, rtx);
extern rtx        gen_divdf3                    (rtx, rtx, rtx);
extern rtx        gen_floatsisf2                (rtx, rtx);
extern rtx        gen_floatdidf2                (rtx, rtx);
extern rtx        gen_fix_truncsfsi2            (rtx, rtx);
extern rtx        gen_fix_truncdfdi2            (rtx, rtx);
extern rtx        gen_ashlsi3                   (rtx, rtx, rtx);
extern rtx        gen_ashrsi3                   (rtx, rtx, rtx);
extern rtx        gen_lshrsi3                   (rtx, rtx, rtx);
extern rtx        gen_rotrsi3                   (rtx, rtx, rtx);
extern rtx        gen_andsi3                    (rtx, rtx, rtx);
extern rtx        gen_xorsi3                    (rtx, rtx, rtx);
extern rtx        gen_iorsi3                    (rtx, rtx, rtx);
extern rtx        gen_movsi_high                (rtx, rtx);
extern rtx        gen_zero_extendqisi2          (rtx, rtx);
extern rtx        gen_zero_extendhisi2          (rtx, rtx);
extern rtx        gen_extendqisi2               (rtx, rtx);
extern rtx        gen_extendhisi2               (rtx, rtx);
extern rtx        gen_jump                      (rtx);
extern rtx        gen_indirect_jump             (rtx);
extern rtx        gen_set_got_tmp               (rtx);
extern rtx        gen_set_got                   (rtx);
extern rtx        gen_frame_addsi3              (rtx, rtx, rtx);
extern rtx        gen_load_locked_si            (rtx, rtx);
extern rtx        gen_store_conditional_si      (rtx, rtx);
extern rtx        gen_one_cmplsi2               (rtx, rtx);
extern rtx        gen_movqi                     (rtx, rtx);
extern rtx        gen_movhi                     (rtx, rtx);
extern rtx        gen_movsi                     (rtx, rtx);
extern rtx        gen_movdi                     (rtx, rtx);
extern rtx        gen_cstoresi4                 (rtx, rtx, rtx, rtx);
extern rtx        gen_cstoresf4                 (rtx, rtx, rtx, rtx);
extern rtx        gen_cstoredf4                 (rtx, rtx, rtx, rtx);
extern rtx        gen_sne_sr_f                  (rtx);
extern rtx        gen_movqicc                   (rtx, rtx, rtx, rtx);
extern rtx        gen_movhicc                   (rtx, rtx, rtx, rtx);
extern rtx        gen_movsicc                   (rtx, rtx, rtx, rtx);
extern rtx        gen_cbranchsi4                (rtx, rtx, rtx, rtx);
extern rtx        gen_cbranchsf4                (rtx, rtx, rtx, rtx);
extern rtx        gen_cbranchdf4                (rtx, rtx, rtx, rtx);
extern rtx        gen_prologue                  (void);
extern rtx        gen_epilogue                  (void);
extern rtx        gen_sibcall_epilogue          (void);
extern rtx        gen_simple_return             (void);
extern rtx        gen_eh_return                 (rtx);
extern rtx        gen_mem_thread_fence          (rtx);
extern rtx        gen_msync                     (void);
extern rtx        gen_atomic_compare_and_swapsi (rtx, rtx, rtx, rtx, rtx, rtx, rtx, rtx);
extern rtx        gen_atomic_compare_and_swapqi (rtx, rtx, rtx, rtx, rtx, rtx, rtx, rtx);
extern rtx        gen_atomic_compare_and_swaphi (rtx, rtx, rtx, rtx, rtx, rtx, rtx, rtx);
extern rtx        gen_atomic_exchangesi         (rtx, rtx, rtx, rtx);
extern rtx        gen_atomic_exchangeqi         (rtx, rtx, rtx, rtx);
extern rtx        gen_atomic_exchangehi         (rtx, rtx, rtx, rtx);
extern rtx        gen_atomic_addsi              (rtx, rtx, rtx);
extern rtx        gen_atomic_subsi              (rtx, rtx, rtx);
extern rtx        gen_atomic_orsi               (rtx, rtx, rtx);
extern rtx        gen_atomic_xorsi              (rtx, rtx, rtx);
extern rtx        gen_atomic_andsi              (rtx, rtx, rtx);
extern rtx        gen_atomic_nandsi             (rtx, rtx, rtx);
extern rtx        gen_atomic_addqi              (rtx, rtx, rtx);
extern rtx        gen_atomic_subqi              (rtx, rtx, rtx);
extern rtx        gen_atomic_orqi               (rtx, rtx, rtx);
extern rtx        gen_atomic_xorqi              (rtx, rtx, rtx);
extern rtx        gen_atomic_andqi              (rtx, rtx, rtx);
extern rtx        gen_atomic_nandqi             (rtx, rtx, rtx);
extern rtx        gen_atomic_addhi              (rtx, rtx, rtx);
extern rtx        gen_atomic_subhi              (rtx, rtx, rtx);
extern rtx        gen_atomic_orhi               (rtx, rtx, rtx);
extern rtx        gen_atomic_xorhi              (rtx, rtx, rtx);
extern rtx        gen_atomic_andhi              (rtx, rtx, rtx);
extern rtx        gen_atomic_nandhi             (rtx, rtx, rtx);
extern rtx        gen_atomic_fetch_addsi        (rtx, rtx, rtx, rtx);
extern rtx        gen_atomic_fetch_subsi        (rtx, rtx, rtx, rtx);
extern rtx        gen_atomic_fetch_orsi         (rtx, rtx, rtx, rtx);
extern rtx        gen_atomic_fetch_xorsi        (rtx, rtx, rtx, rtx);
extern rtx        gen_atomic_fetch_andsi        (rtx, rtx, rtx, rtx);
extern rtx        gen_atomic_fetch_nandsi       (rtx, rtx, rtx, rtx);
extern rtx        gen_atomic_fetch_addqi        (rtx, rtx, rtx, rtx);
extern rtx        gen_atomic_fetch_subqi        (rtx, rtx, rtx, rtx);
extern rtx        gen_atomic_fetch_orqi         (rtx, rtx, rtx, rtx);
extern rtx        gen_atomic_fetch_xorqi        (rtx, rtx, rtx, rtx);
extern rtx        gen_atomic_fetch_andqi        (rtx, rtx, rtx, rtx);
extern rtx        gen_atomic_fetch_nandqi       (rtx, rtx, rtx, rtx);
extern rtx        gen_atomic_fetch_addhi        (rtx, rtx, rtx, rtx);
extern rtx        gen_atomic_fetch_subhi        (rtx, rtx, rtx, rtx);
extern rtx        gen_atomic_fetch_orhi         (rtx, rtx, rtx, rtx);
extern rtx        gen_atomic_fetch_xorhi        (rtx, rtx, rtx, rtx);
extern rtx        gen_atomic_fetch_andhi        (rtx, rtx, rtx, rtx);
extern rtx        gen_atomic_fetch_nandhi       (rtx, rtx, rtx, rtx);
extern rtx        gen_atomic_add_fetchsi        (rtx, rtx, rtx, rtx);
extern rtx        gen_atomic_sub_fetchsi        (rtx, rtx, rtx, rtx);
extern rtx        gen_atomic_or_fetchsi         (rtx, rtx, rtx, rtx);
extern rtx        gen_atomic_xor_fetchsi        (rtx, rtx, rtx, rtx);
extern rtx        gen_atomic_and_fetchsi        (rtx, rtx, rtx, rtx);
extern rtx        gen_atomic_nand_fetchsi       (rtx, rtx, rtx, rtx);
extern rtx        gen_atomic_add_fetchqi        (rtx, rtx, rtx, rtx);
extern rtx        gen_atomic_sub_fetchqi        (rtx, rtx, rtx, rtx);
extern rtx        gen_atomic_or_fetchqi         (rtx, rtx, rtx, rtx);
extern rtx        gen_atomic_xor_fetchqi        (rtx, rtx, rtx, rtx);
extern rtx        gen_atomic_and_fetchqi        (rtx, rtx, rtx, rtx);
extern rtx        gen_atomic_nand_fetchqi       (rtx, rtx, rtx, rtx);
extern rtx        gen_atomic_add_fetchhi        (rtx, rtx, rtx, rtx);
extern rtx        gen_atomic_sub_fetchhi        (rtx, rtx, rtx, rtx);
extern rtx        gen_atomic_or_fetchhi         (rtx, rtx, rtx, rtx);
extern rtx        gen_atomic_xor_fetchhi        (rtx, rtx, rtx, rtx);
extern rtx        gen_atomic_and_fetchhi        (rtx, rtx, rtx, rtx);
extern rtx        gen_atomic_nand_fetchhi       (rtx, rtx, rtx, rtx);
extern rtx        gen_call                      (rtx, rtx);
extern rtx        gen_sibcall                   (rtx, rtx);
extern rtx        gen_call_value                (rtx, rtx, rtx);
extern rtx        gen_sibcall_value             (rtx, rtx, rtx);

#endif /* GCC_INSN_FLAGS_H */
