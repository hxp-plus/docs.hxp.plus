---
tags:
  - Linux
  - 工具
---
# r730 风扇转速

!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

原英文标题：r730-fan-speed

从 Dell 安装 ipmitool。开启手动控制的命令是：
```
ipmitool.exe -I lanplus -U root -P Hxp@123! -H 192.168.11.101 raw 0x30 0x30 0x01 0x00
```
关闭的命令是：
```
ipmitool.exe -I lanplus -H $IP -U $USER -P $PASS raw 0x30 0x30 0x01 0x01
```
可以一次性控制所有风扇：
```
ipmitool.exe -I lanplus -H $IP -U $USER -P $PASS raw 0x30 0x30 0x02 0xff 0x##
```
其中 ## 的取值范围是 00 到 64，对应 0% 到 100%。上述信息到处都能找到，但原来同样的命令也可以用于单独控制某个风扇：

```
ipmitool -I lanplus -H $IP -U $USER -P $PASS raw 0x30 0x30 0x02 0x?? 0x##
```

其中 ?? 是从零开始索引的风扇编号，## 同上。风扇 1 是 0x00，风扇 2 是 0x01，以此类推。如果使用了错误的编号，ipmitool 会报错，不会造成任何损坏。

**参考**
<https://www.reddit.com/r/homelab/comments/t9pa13/dell_poweredge_fan_control_with_ipmitool/>

<https://www.yodiw.com/adjust-fan-speed-dell-r730-poweredge/>

---

## 原文（English）

Install ipmitool from DELL. The command to turn on manual control is:
```
ipmitool.exe -I lanplus -U root -P Hxp@123! -H 192.168.11.101 raw 0x30 0x30 0x01 0x00
```
and to turn it off is:
```
ipmitool.exe -I lanplus -H $IP -U $USER -P $PASS raw 0x30 0x30 0x01 0x01
```
Controlling all fans at once can be done with:
```
ipmitool.exe -I lanplus -H $IP -U $USER -P $PASS raw 0x30 0x30 0x02 0xff 0x##
```
where ## is 00 to 64, which is mapped to 0% to 100%. All the above info is available all over the place, but it turns out the same command can be used to target individual fans too:

```
ipmitool -I lanplus -H $IP -U $USER -P $PASS raw 0x30 0x30 0x02 0x?? 0x##
```

Where ?? is a zero indexed fan number and ## is as above. Fan 1 is 0x00, fan 2 is 0x01, etc. If you use a an incorrect number it will throw an error on ipmitool and not cause any damage.

**References**
<https://www.reddit.com/r/homelab/comments/t9pa13/dell_poweredge_fan_control_with_ipmitool/>

<https://www.yodiw.com/adjust-fan-speed-dell-r730-poweredge/>
