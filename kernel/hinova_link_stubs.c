// SPDX-License-Identifier: GPL-2.0
/*
 * Link stubs for building the RNA-AL00 HarmonyOS 3.0 open-source kernel with the phone's
 * stock config (5.4.86-perf).
 *
 * Several Huawei sources ship only as pre-compiled .S (block/mas_bkops_*.S, mas_blk_*.S,
 * drivers/scsi/ufs/mas_ufs.S, mas-ufs-bkops.S) generated from a DEBUG config (DEBUG_FS,
 * QCOM_RTB, MAS_DEBUG_FS on). Under the stock config those symbols don't exist, so provide the
 * same behaviour the kernel's own !CONFIG inline stubs would give. Nothing here is exported, so
 * no KMI/CRC impact on vendor modules.
 */
#include <linux/compiler.h>
#include <linux/err.h>
#include <linux/types.h>

struct dentry;
struct file_operations;

#ifndef CONFIG_DEBUG_FS
/* mirrors include/linux/debugfs.h !CONFIG_DEBUG_FS inlines */
__used struct dentry *debugfs_create_dir(const char *name, struct dentry *parent)
{ return ERR_PTR(-ENODEV); }
__used struct dentry *debugfs_create_file(const char *name, umode_t mode, struct dentry *parent,
					  void *data, const struct file_operations *fops)
{ return ERR_PTR(-ENODEV); }
__used struct dentry *debugfs_create_bool(const char *name, umode_t mode, struct dentry *parent,
					  bool *value)
{ return ERR_PTR(-ENODEV); }
__used void debugfs_create_u32(const char *name, umode_t mode, struct dentry *parent, u32 *value)
{ }
__used struct dentry *debugfs_create_ulong(const char *name, umode_t mode, struct dentry *parent,
					   unsigned long *value)
{ return ERR_PTR(-ENODEV); }
__used void debugfs_remove_recursive(struct dentry *dentry)
{ }
#endif

#ifndef CONFIG_QCOM_RTB
/* mirrors include/linux/msm_rtb.h !CONFIG_QCOM_RTB inline */
__used int uncached_logk(int log_type, void *data)
{ return 0; }
#endif

#if !defined(CONFIG_MAS_DEBUG_FS) && !defined(CONFIG_MAS_BLK_DEBUG)
/* block/mas_blk_unistore_sysfs.c only defines these with MAS debug on; debug off => 0 */
__used int mas_blk_unistore_debug_en(void) { return 0; }
__used int mas_blk_recovery_debug_on(void) { return 0; }
__used void mas_blk_recovery_debug_off(void) { }
#endif

#if defined(CONFIG_ANA_HS_CORE) && !defined(CONFIG_ANA_HS_EXTERN_OPS_KIT)
/* implemented only by ana_hs_extern_ops.c (ANA_HS_EXTERN_OPS_KIT, absent from stock config);
 * the phone's DT has no fsa4480 extern-ops device, so these are no-ops. */
__used void ana_hs_fsa4480_start_res_detect(bool new_state) { }
__used void ana_hs_fsa4480_stop_res_detect(bool new_state) { }
__used void ana_hs_fsa4480_start_ovp_detect(bool new_state) { }
__used void ana_hs_fsa4480_stop_ovp_detect(bool new_state) { }
#endif
