# Kickstart 软 RAID 安装

使用以下 `kickstart` 分区配置安装 软 RAID 1 到最小的两块硬盘的分盘脚本如下：

```bash
# Partition disks
%pre --interpreter=/bin/bash
set -x
# Get the sizes of all /dev/sd[a-z] devices in bytes and sort them by size
devices=$(lsblk -dbn -o NAME,SIZE | grep '^sd[a-z]' | sort -k2 -n)
# Extract the two smallest devices
smallest_devices=$(echo "$devices" | head -n 2)
# Assign the smallest devices to variables
smallest_1=$(echo "$smallest_devices" | sed -n '1p' | awk '{print $1}')
smallest_2=$(echo "$smallest_devices" | sed -n '2p' | awk '{print $1}')
# Print the results
echo "The two block devices with the smallest size are:"
echo "/dev/$smallest_1"
echo "/dev/$smallest_2"
# 装软RAID到最小的2块盘上
cat >/tmp/part-include <<-EOF
	zerombr
	ignoredisk --only-use=$smallest_1,$smallest_2
	clearpart --all --initlabel --drives=$smallest_1,$smallest_2
	part raid.1583 --fstype="mdmember" --ondisk=$smallest_1 --size=2050
	part raid.1590 --fstype="mdmember" --ondisk=$smallest_2 --size=2050
	part raid.1254 --fstype="mdmember" --ondisk=$smallest_1 --size=2050
	part raid.1261 --fstype="mdmember" --ondisk=$smallest_2 --size=2050
	part raid.2055 --fstype="mdmember" --ondisk=$smallest_1 --size=1 --grow
	part raid.2048 --fstype="mdmember" --ondisk=$smallest_2 --size=1 --grow
	raid /boot/efi --device=boot_efi --fstype="efi" --level=RAID1 --fsoptions="umask=0077,shortname=winnt" raid.1583 raid.1590
	raid /boot --device=boot --fstype="xfs" --level=RAID1 raid.1254 raid.1261
	raid pv.789 --device=pv00 --fstype="lvmpv" --level=RAID1 raid.2055 raid.2048
	volgroup rootvg --pesize=4096 pv.789
	logvol swap --fstype="swap" --size=32768 --name=lv_swap --vgname=rootvg
	logvol /home --fstype="xfs" --size=20480 --name=lv_home --vgname=rootvg
	logvol /tmp --fstype="xfs" --size=51200 --name=lv_tmp --vgname=rootvg
	logvol /var --fstype="xfs" --size=51200 --name=lv_var --vgname=rootvg
	logvol / --fstype="xfs" --size=51200 --name=lv_root --vgname=rootvg
EOF
%end
%include /tmp/part-include
```

封装 ISO 镜像可参考以下代码：

```bash
case "${os_type}" in
*_ARM)
    sudo genisoimage -V "$label" -o "${BASEDIR}/${DISTDIR}/${os_type}.${DATE}.iso" \
        -J -rational-rock -joliet-long -cache-inodes -graft-points \
        -untranslated-filenames -translation-table -m repoview \
        -efi-boot-part -efi-boot-image -e images/efiboot.img -no-emul-boot \
        .
    ;;
*_X86)
    sudo genisoimage -V "$label" -o "${BASEDIR}/${DISTDIR}/${os_type}.${DATE}.iso" \
        -J -rational-rock -joliet-long -cache-inodes -graft-points \
        -untranslated-filenames -translation-table -m repoview \
        -eltorito-boot isolinux/isolinux.bin -eltorito-catalog isolinux/boot.cat -boot-load-size 4 -boot-info-table -no-emul-boot \
        -eltorito-alt-boot -eltorito-boot images/efiboot.img -no-emul-boot \
        .
    ;;
esac
```
