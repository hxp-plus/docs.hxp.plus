---
tags:
  - Linux
  - 工具
---

# 安装 hxp-dvorak 键盘布局


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

原英文标题：Install hxp-dvorak keyboard layout

## 步骤 0：在 GNOME 中更改键盘布局

进入 `GNOME Settings -> Region & Language -> Add an Input Source -> English(United States) -> English(programmer Dvorak)`
进入 `gnome tweak tools -> Keyboard & Mouse -> Additional Layout Options -> Layout of numernic keyboard -> Phone and ATM Style`

## 步骤 1：备份键位映射

```bash
xmodmap -pm | tail -n 9 | grep -v '^$' | sed 's/  */ = /' | sed 's/^/clear /' | sed 's/ = [[:print:]]*//' > .Xmodmap_origin
xmodmap -pke >> .Xmodmap_origin
xmodmap -pm | tail -n 9 | grep -v '^$' | sed 's/  */ = /' | sed 's/^/add /' | sed 's/([[:alnum:]]*)//g' | sed 's/ , / /g' >> .Xmodmap_origin
```

## 步骤 2：生成你自己的 Xmodmap

```bash
xmodmap -pm | tail -n 9 | grep -v '^$' | sed 's/  */ = /' | sed 's/^/clear /' | sed 's/ = [[:print:]]*//' > .Xmodmap
```

## 步骤 3：检测键码

```bash
xev
```

例如，当我按下 `CapsLock` 时，它打印：

```
KeyRelease event, serial 37, synthetic NO, window 0x2200001,
    root 0x969, subw 0x0, time 1201498, (90,63), root:(140,177),
    state 0x2, keycode 66 (keysym 0xffe5, Caps_Lock), same_screen YES,
    XLookupString gives 0 bytes: 
    XFilterEvent returns: False
```

当我按下 `space` 时，它打印：

```
KeyPress event, serial 37, synthetic NO, window 0x2200001,
    root 0x969, subw 0x0, time 1322983, (162,-19), root:(212,95),
    state 0x0, keycode 65 (keysym 0x20, space), same_screen YES,
    XLookupString gives 1 bytes: (20) " "
    XmbLookupString gives 1 bytes: (20) " "
    XFilterEvent returns: False
```

我运行了

```bash
grep 'space' .Xmodmap_origin
```

它打印了

```bash
keycode  65 = space NoSymbol space
```

然后我写入了

```
keycode 66 = space NoSymbol space
```

以将 `CapsLock` 改为 `space`

## 步骤 4：修改修饰键

```bash
tail -n8 .Xmodmap_origin  >> .Xmodmap
```

删除

```
add mod3 =
```

然后通过以下命令应用更改

```bash
xmodmap .Xmodmap
```

---

## 原文（English）

## Step 0: Change keyboard layout in GNOME

Go to `GNOME Settings -> Region & Language -> Add an Input Source -> English(United States) -> English(programmer Dvorak)`
Go to `gnome tweak tools -> Keyboard & Mouse -> Additional Layout Options -> Layout of numernic keyboard -> Phone and ATM Style`

## Step 1: Backup keymap

```bash
xmodmap -pm | tail -n 9 | grep -v '^$' | sed 's/  */ = /' | sed 's/^/clear /' | sed 's/ = [[:print:]]*//' > .Xmodmap_origin
xmodmap -pke >> .Xmodmap_origin
xmodmap -pm | tail -n 9 | grep -v '^$' | sed 's/  */ = /' | sed 's/^/add /' | sed 's/([[:alnum:]]*)//g' | sed 's/ , / /g' >> .Xmodmap_origin
```

## Step 2: Generate your own Xmodmap

```bash
xmodmap -pm | tail -n 9 | grep -v '^$' | sed 's/  */ = /' | sed 's/^/clear /' | sed 's/ = [[:print:]]*//' > .Xmodmap
```

## Step 3: Detecting keycode

```bash
xev
```

For example, when I pressed `CapsLock` , it prints

```
KeyRelease event, serial 37, synthetic NO, window 0x2200001,
    root 0x969, subw 0x0, time 1201498, (90,63), root:(140,177),
    state 0x2, keycode 66 (keysym 0xffe5, Caps_Lock), same_screen YES,
    XLookupString gives 0 bytes: 
    XFilterEvent returns: False
```

when I pressed `space`, it prints

```
KeyPress event, serial 37, synthetic NO, window 0x2200001,
    root 0x969, subw 0x0, time 1322983, (162,-19), root:(212,95),
    state 0x0, keycode 65 (keysym 0x20, space), same_screen YES,
    XLookupString gives 1 bytes: (20) " "
    XmbLookupString gives 1 bytes: (20) " "
    XFilterEvent returns: False
```

I ran

```bash
grep 'space' .Xmodmap_origin
```

It printed

```bash
keycode  65 = space NoSymbol space
```

And I wrote

```
keycode 66 = space NoSymbol space
```

To change `CapsLock` to `space`

## Step 4: Modify modifiers

```bash
tail -n8 .Xmodmap_origin  >> .Xmodmap
```

delete

```
add mod3 =
```

and apply changes by

```bash
xmodmap .Xmodmap
```
