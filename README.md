# android_kernel_huawei_tina

Linux 5.4 kernel for the Huawei nova 9 Pro (TINA-AN00, SM7325), based on Huawei's
RNA-AL00 HarmonyOS 3.0.0 open source release. Runs with the HarmonyOS 4.3 firmware.

Upstream source: [Huawei Open Source Release Center](https://consumer.huawei.com/en/opensource/detail/?siteCode=worldwide&keywords=Nova%209%20Pro&fileType=openSourceSoftware&pageSize=10&curPage=1)
([direct download](https://download-c1.huawei.com/download/downloadCenter?downloadId=4B197B63F00F498A4630A7823530B046&version=9E6B661367A9BE617C3A1F44DE46881B&siteCode=worldwide)).
The first commit is its `kernel/` directory, unmodified.

Not affiliated with Huawei. Flash at your own risk.

## Build

Linux host, tree on ext4.

```bash
sudo apt install build-essential bc bison flex libssl-dev libelf-dev cpio xz-utils curl python3 \
                 binutils-aarch64-linux-gnu
tina/get_toolchain.sh
tina/build.sh
```

Output: `out/arch/arm64/boot/Image.gz`

## Flash

```bash
python3 tina/tools/repack_boot.py stock_boot.img out/arch/arm64/boot/Image.gz new_boot.img
fastboot flash boot new_boot.img
```

`stock_boot.img` must match the firmware installed on the phone.

## License

GPL-2.0, see `COPYING`.
