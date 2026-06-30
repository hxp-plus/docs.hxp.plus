---
tags:
  - VPN
---

# IPSec VPN 教程

# Preamble: Why IPSec VPN?

I know that nowadays many of developers use Shadowsocks and v2ray to get in touch with Google. And VPN is sort of outdated and can be easily censored and banned in mainland China, especially before some big events.

But, having a real VPN is really convenient. You don't need to install any of the clients such as v2ray or libev-shadowsocks. It is cross-platformed, as well. Whatever system you are using, you can always connect to VPN in your system network settings.

## Main difference between VPN and v2ray or shadowsocks

- In v2ray and shadowsocks, you use the same username every device.

- In IPSec VPN, one username can only be logged in on one device.

# Server Side

For this tutorial we use [hwdsl2/setup-ipsec-vpn](https://github.com/hwdsl2/setup-ipsec-vpn) to set up IPSec VPN.

I recommend you to use the default settings, which generate random VPN credentials for you. It's safe and easy, whilst in configuring clients, you just need to copy and paste once.

In this tutorial we use Ubuntu 16.04 as our server system, and use `wget` to download.

run

```shell
wget https://git.io/vpnsetup -O vpnsetup.sh && sudo sh vpnsetup.sh
```

to install and configure IPSec VPN automatically.

After installing, the server is ready to go. Remember to copy the VPN IP, PSK, username and password and paste them locally.

# Client Side

I use Arch Linux with GNOME desktop environment. And I prefer connecting to VPN in settings rather than terminal.

At first, make sure these 2 packages are installed:

```shell
networkmanager-strongswan
networkmanager-l2tp
```

I installed them via `yay`

```shell
yay -S networkmanager-l2tp
yay -S networkmanager-strongswan
```

Then, restart `networkmanager`

```shell
sudo systemctl restart NetworkManager
```

Now you can go to settings to connect.

Do as [this doc](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients.md) say and have fun!

**If you encountered some connection problems, change `aes128-sha1-modp2048!` to `aes128-sha1-modp1024`**

**For other system, read the doc above!**
