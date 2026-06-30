---
tags:
  - VMware
---

# Arch Linux 安装 VMware Workstation Pro

To install WMware Workstation Pro on Arch Linux, DO NOT download the bundle file on the official website. I tired, but I suspect the installer is incompatible with Arch Linux.

use AUR instead

```shell
yay -S --noconfirm --needed ncurses5-compat-libs
sudo pacman -S fuse2 gtkmm linux-headers pcsclite libcanberra
yay -S --noconfirm --needed  vmware-workstation
modprobe -a vmw_vmci vmmon
sudo modprobe vmnet
sudo systemctl enable vmware-networks.service
sudo systemctl start vmware-networks.service
```
