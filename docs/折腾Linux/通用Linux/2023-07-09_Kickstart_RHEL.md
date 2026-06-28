---
tags:
  - Linux
---

# RHEL 和 CentOS 的 Kickstart 安装


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

原英文标题：Kickstart Installation for RHEL and CentOS

## 挂载并复制内容

```bash
cd /tmp/
mkdir isomake
sudo mount /var/lib/libvirt/images/iso/rhel-server-7.6-x86_64-dvd.iso /mnt/
rsync -aAHXv --info=progress2 --no-i-r /mnt/ /tmp/isomake/
cd isomake/
```

## 将 Kickstart 文件放在 CDROM 根目录下

从已安装的系统中将 `/root/anaconda-ks.cfg` 复制到 CDROM 目录的根目录下，并将其命名为 `ks.cfg`：

```bash
scp 192.168.122.9:anaconda-ks.cfg ks.cfg
```

并相应地修改一些行。我修改了以下行：

```
firstboot --disable
eula --agreed
reboot
# Add SSH key
%post
mkdir /root/.ssh
chmod 700 /root/.ssh
touch /root/.ssh/authorized_keys
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDxg2t22ss6ObrXfOoKGbKhQ+7JEgf1/fhGuEnRKkX5byY2Ao/chD4v1awd6RHOrntd4vKv9fUBTYSQbnlCZpCHUhv3fD98+lppmI2FpGrKF54FAs1xXDudn8vR7rffBg/n4mRsNciSzI1AihoFNdc/sVUplvv8rwX+1h6at1/tI8udDJ1JJw9D0uUdhITFmK8Y5osP5ZrqjSUq0THreZM+7/Me7dekJh83ndp+2cld1TUPLA2QPjicTKomuhu+pkKYVInBFQ5mi4ozWUXP7jVv5szARZlRLGmZDz67a4leRotsGU55y6spC4+pvgXrboZjMV/6nupSvzdvJIVj+1I7nPE+t/K55YNJ0r47sr4XsUtsI+PYaMoXGAfHzr6gXdCHjuiKfhU+ZtlkFPVSTdlt4FePkdhVDwhFKxMsK+1sIWNOCCP4OFDrPSEHh6ut1v4UZ84TXycbIWAQCbEMwXUIHtF1xF3bPiFZvNrpJFt8ObOcTNUvh1XOh/Ek2wsNnrU= hxp@rhel9.hxp.plus' >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
cat > /etc/yum.repos.d/dvd.repo <<EOF
[dvd]
name=dvd
baseurl=file:///mnt/
gpgcheck=0
enabled=1
EOF
%end
```

CentOS 7 的 Kickstart 参考文档：<https://docs.centos.org/en-US/centos/install-guide/Kickstart2/>

## 添加引导项

对于 BIOS 引导，修改 `isolinux/isolinux.cfg`：

```
label autoinstall
  menu label ^Auto install Red Hat Enterprise Linux 7.6
  menu default
  kernel vmlinuz
  append initrd=initrd.img inst.stage2=hd:LABEL=RHEL-7.6\x20Server.x86_64 ks=cdrom:/ks.cfg

label linux
  menu label ^Install Red Hat Enterprise Linux 7.6
  kernel vmlinuz
  append initrd=initrd.img inst.stage2=hd:LABEL=RHEL-7.6\x20Server.x86_64 quiet

label check
  menu label Test this ^media & install Red Hat Enterprise Linux 7.6
  kernel vmlinuz
  append initrd=initrd.img inst.stage2=hd:LABEL=RHEL-7.6\x20Server.x86_64 rd.live.check quiet
```

我从 check 标签中移除了 `menu default`，并将其添加到了 autoinstall 标签中，以使 autoinstall 标签成为默认的引导选项。

对于 UEFI 引导，编辑 `EFI/BOOT/grub.cfg`：

```
menuentry 'Auto install Red Hat Enterprise Linux 7.6' --class fedora --class gnu-linux --class gnu --class os {
        linuxefi /images/pxeboot/vmlinuz inst.stage2=hd:LABEL=RHEL-7.6\x20Server.x86_64 ks=cdrom:/ks.cfg
        initrdefi /images/pxeboot/initrd.img
}
menuentry 'Install Red Hat Enterprise Linux 7.6' --class fedora --class gnu-linux --class gnu --class os {
        linuxefi /images/pxeboot/vmlinuz inst.stage2=hd:LABEL=RHEL-7.6\x20Server.x86_64 quiet
        initrdefi /images/pxeboot/initrd.img
}
menuentry 'Test this media & install Red Hat Enterprise Linux 7.6' --class fedora --class gnu-linux --class gnu --class os {
        linuxefi /images/pxeboot/vmlinuz inst.stage2=hd:LABEL=RHEL-7.6\x20Server.x86_64 rd.live.check quiet
        initrdefi /images/pxeboot/initrd.img
}
```

我自动修改了 `set default="0"`，以将默认引导选项设置为第一项。

## 生成 ISO 镜像

```bash
mkisofs -o /tmp/rhel76-ks.iso -b isolinux/isolinux.bin -J -R -l -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -e images/efiboot.img -no-emul-boot -graft-points -V "RHEL-7.6 Server.x86_64" .
```

注意：`RHEL-7.6 Server.x86_64` 是 ISO 镜像的标签。请将其改为 `isolinux/isolinux.cfg` 中 `inst.stage2=hd:LABEL=` 之后的标签。

---

## 原文（English）

```
---
tags:
  - Linux
---

# Kickstart Installation for RHEL and CentOS


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## Mount and copy contents

```bash
cd /tmp/
mkdir isomake
sudo mount /var/lib/libvirt/images/iso/rhel-server-7.6-x86_64-dvd.iso /mnt/
rsync -aAHXv --info=progress2 --no-i-r /mnt/ /tmp/isomake/
cd isomake/
```

## Put a kickstart file under root directory of cdrom

Copy "/root/anaconda-ks.cfg" from an installed system to the root of cdrom directory, and name it "ks.cfg":

```bash
scp 192.168.122.9:anaconda-ks.cfg ks.cfg
```

and modify some lines accordingly. I modified these lines:

```
firstboot --disable
eula --agreed
reboot
# Add SSH key
%post
mkdir /root/.ssh
chmod 700 /root/.ssh
touch /root/.ssh/authorized_keys
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDxg2t22ss6ObrXfOoKGbKhQ+7JEgf1/fhGuEnRKkX5byY2Ao/chD4v1awd6RHOrntd4vKv9fUBTYSQbnlCZpCHUhv3fD98+lppmI2FpGrKF54FAs1xXDudn8vR7rffBg/n4mRsNciSzI1AihoFNdc/sVUplvv8rwX+1h6at1/tI8udDJ1JJw9D0uUdhITFmK8Y5osP5ZrqjSUq0THreZM+7/Me7dekJh83ndp+2cld1TUPLA2QPjicTKomuhu+pkKYVInBFQ5mi4ozWUXP7jVv5szARZlRLGmZDz67a4leRotsGU55y6spC4+pvgXrboZjMV/6nupSvzdvJIVj+1I7nPE+t/K55YNJ0r47sr4XsUtsI+PYaMoXGAfHzr6gXdCHjuiKfhU+ZtlkFPVSTdlt4FePkdhVDwhFKxMsK+1sIWNOCCP4OFDrPSEHh6ut1v4UZ84TXycbIWAQCbEMwXUIHtF1xF3bPiFZvNrpJFt8ObOcTNUvh1XOh/Ek2wsNnrU= hxp@rhel9.hxp.plus' >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
cat > /etc/yum.repos.d/dvd.repo <<EOF
[dvd]
name=dvd
baseurl=file:///mnt/
gpgcheck=0
enabled=1
EOF
%end
```

Kickstart references for CentOS 7: <https://docs.centos.org/en-US/centos/install-guide/Kickstart2/>

## Add boot entry

For BIOS boot, modify "isolinux/isolinux.cfg":

```
label autoinstall
  menu label ^Auto install Red Hat Enterprise Linux 7.6
  menu default
  kernel vmlinuz
  append initrd=initrd.img inst.stage2=hd:LABEL=RHEL-7.6\x20Server.x86_64 ks=cdrom:/ks.cfg

label Linux
  menu label ^Install Red Hat Enterprise Linux 7.6
  kernel vmlinuz
  append initrd=initrd.img inst.stage2=hd:LABEL=RHEL-7.6\x20Server.x86_64 quiet

label check
  menu label Test this ^media & install Red Hat Enterprise Linux 7.6
  kernel vmlinuz
  append initrd=initrd.img inst.stage2=hd:LABEL=RHEL-7.6\x20Server.x86_64 rd.live.check quiet
```

I removed "menu default" from the check label and added in the autoinstall label to make autoinstall label the default boot option.

For UEFI boot, edit "EFI/BOOT/grub.cfg":

```
menuentry 'Auto install Red Hat Enterprise Linux 7.6' --class Fedora --class gnu-Linux --class gnu --class os {
        linuxefi /images/pxeboot/vmlinuz inst.stage2=hd:LABEL=RHEL-7.6\x20Server.x86_64 ks=cdrom:/ks.cfg
        initrdefi /images/pxeboot/initrd.img
}
menuentry 'Install Red Hat Enterprise Linux 7.6' --class Fedora --class gnu-Linux --class gnu --class os {
        linuxefi /images/pxeboot/vmlinuz inst.stage2=hd:LABEL=RHEL-7.6\x20Server.x86_64 quiet
        initrdefi /images/pxeboot/initrd.img
}
menuentry 'Test this media & install Red Hat Enterprise Linux 7.6' --class Fedora --class gnu-Linux --class gnu --class os {
        linuxefi /images/pxeboot/vmlinuz inst.stage2=hd:LABEL=RHEL-7.6\x20Server.x86_64 rd.live.check quiet
        initrdefi /images/pxeboot/initrd.img
}
```

I auto modified `set default="0"` to set the default boot option to the first entry.

## Generate ISO media

```bash
mkisofs -o /tmp/rhel76-ks.iso -b isolinux/isolinux.bin -J -R -l -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -e images/efiboot.img -no-emul-boot -graft-points -V "RHEL-7.6 Server.x86_64" .
```

Note: "RHEL-7.6 Server.x86_64" is the label of the ISO image. Please change it to the label after "inst.stage2=hd:LABEL=" in "isolinux/isolinux.cfg".
```
