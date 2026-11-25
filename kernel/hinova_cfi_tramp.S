/* SPDX-License-Identifier: GPL-2.0 */
/*
 * block/mas_bkops_sysfs.S (pre-compiled) takes the address of its debugfs file_operations
 * handlers through __cfi_<fn> jump-table names that our CFI build does not emit. They are only
 * used for debugfs files (DEBUG_FS=n in stock, so never registered); give each a trampoline to
 * the real function defined in that .S.
 */
#include <linux/linkage.h>

.macro cfi_tramp fn
	.pushsection .text.__cfi_\fn, "ax"
	.globl __cfi_\fn
	.type __cfi_\fn, %function
	.balign 4
__cfi_\fn:
	b \fn
	.size __cfi_\fn, . - __cfi_\fn
	.popsection
.endm

/* block/mas_bkops_sysfs_interface.c defines these C wrappers only with CONFIG_MAS_DEBUG_FS */
#if defined(CONFIG_MAS_BKOPS) && !defined(CONFIG_MAS_DEBUG_FS)
cfi_tramp mas_bkops_force_query_open
cfi_tramp mas_bkops_force_query_read
cfi_tramp mas_bkops_force_query_release
cfi_tramp mas_bkops_stat_open
cfi_tramp mas_bkops_stat_read
cfi_tramp mas_bkops_stat_release
#endif
