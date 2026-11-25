# hinova: force the stock CRCs of exports whose ABI was verified identical to stock but whose
# genksyms type text could not be reproduced (stock source not available).
#
# fsa4480_*: stock machine_dlkm.ko / mbhc_dlkm.ko call them exactly like this tree's prototypes
#   (disassembly: reg/unreg(x0=struct notifier_block *, x1=struct device_node *) -> int,
#    switch_event(x0=struct device_node *, w1=enum fsa_function) -> int; enum identical in the
#    stock kheaders). All types in their genksyms closure already match stock (_dev_err matches).
s/^__crc_fsa4480_reg_notifier = 0x[0-9a-f]*;/__crc_fsa4480_reg_notifier = 0x3ac0e18f;/
s/^__crc_fsa4480_unreg_notifier = 0x[0-9a-f]*;/__crc_fsa4480_unreg_notifier = 0xe6d11bf4;/
s/^__crc_fsa4480_switch_event = 0x[0-9a-f]*;/__crc_fsa4480_switch_event = 0xc4dc51f7;/
