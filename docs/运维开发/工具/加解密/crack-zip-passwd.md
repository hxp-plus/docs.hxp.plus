---
tags:
  - Linux
  - 工具
---

# 破解多文件大 ZIP 密码


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

原英文标题：Crack Multi-file Large Zip Password

### 步骤 0：删除压缩包中所有大文件

对于多文件 zip 压缩包，每个文件的密码通常是相同的。所以我们只需要破解其中一个文件的密码即可。

由于大文件的哈希值很长，而 hashcat 在破解 zip 密码时仅支持约 8 KB 的数据长度，因此我们无法破解大文件的密码。所以我们删除压缩包中所有大文件，只保留最小的文件。

我使用 Ark 来执行此操作。

### 步骤 1：创建哈希文件

```bash
sudo pacman -S john
zip2john file.zip | cut -d ":" -f 2 > zip.hash
```

### 步骤 2：安装并配置 Hashcat

我的笔记本没有 Nvidia 或 AMD GPU，只安装了 Intel 处理器。因此我需要安装 opencl 驱动

```bash
sudo pacman -S intel-compute-runtime
```

尝试运行 hashcat 基准测试

```bash
sudo pacman -S hashcat
hashcat --benchmark --force
```

### 步骤 3：确定哈希类型

查看哈希值

```bash
cat zip.hash
```

输出：

```
file.zip/破解必读.txt:$zip2$*0*3*0*465b166248bf0908518ab125ade7765c*638b*eb
*24dd7716b7da6a0a2b4c63ec3b59edb1627655735efac226966a4750f54065948e8a45ce
c33a55543dad2c81d70a66307ace0870e4ddb97ef28dc147f0954d83136b2e2c3cd2b920c
2b7e1f6a35c3fc7e65e1d3994508e4fcfe8e4d8d477dac181f727d111001654234450530a
8e84d588226c2e5e6a696afd617b56952f3f3e06c4fb6f64e8f365b95fbacf2aa1f4e6a1e
71a5d146ba1b0aa24c7b17890c4f8ebf6e6c48422288dbe7b4279bd1b9065c92c34fa2278
2ad7aa9bc8d666fc7f5ec801c60d979bc3a106ec5ecff82058ac46e139bd6d3e0086d581a
a32d5f98bdaa426f1c58122eaf6c3269b*c658ddbebd8d31abba1c*$/zip2$:破解必读.txt:file.zip:file.zip
```



在哈希的末尾，可以看到签名为 `zip2`，要确定使用哪个哈希代码，使用 `grep`

```bash
hashcat --help | grep zip --ignore-case
```

输出

```
  11600 | 7-Zip                                            | Archives
  17200 | PKZIP (Compressed)                               | Archives
  17220 | PKZIP (Compressed Multi-File)                    | Archives
  17225 | PKZIP (Mixed Multi-File)                         | Archives
  17230 | PKZIP (Mixed Multi-File Checksum-Only)           | Archives
  17210 | PKZIP (Uncompressed)                             | Archives
  20500 | PKZIP Master Key                                 | Archives
  20510 | PKZIP Master Key (6 byte optimization)           | Archives
  23001 | SecureZIP AES-128                                | Archives
  23002 | SecureZIP AES-192                                | Archives
  23003 | SecureZIP AES-256                                | Archives
  13600 | WinZip                                           | Archives
```

`zip` 的哈希代码是 `13600`。

然后我们开始破解。由于我已经知道密码由 4 位小写字母和数字组成。

```bash
hashcat -a 3 -m 13600 --force file.hash -1 '?d?l' '?1?1?1?1'
```

---

## 原文（English）

### Step 0: Delete all large file in the archive

For multi-file zip archives, the password for each file are usually the same. So we just need to crack one of the file's password.

Since the hash of large file is long, and hashcat only supports a data length of about 8 KB when cracking zip passwords, it is impossible for us to crack large file password. So we delete all large  file in an archive, just keep the smallest file.

I used Ark to perform this action.

### Step 1: Create hash file

```bash
sudo pacman -S john
zip2john file.zip | cut -d ":" -f 2 > zip.hash
```

### Step 2: Install and Configure Hashcat

My laptop do not have Nvidia or AMD GPU, only Intel processer is installed. So I need to install opencl driver by

```bash
sudo pacman -S intel-compute-runtime
```

Try hashcat benchmark

```bash
sudo pacman -S hashcat
hashcat --benchmark --force
```

### Step 3: Determine the hash type

Observe the hash

```bash
cat zip.hash
```

Output:

```
file.zip/破解必读.txt:$zip2$*0*3*0*465b166248bf0908518ab125ade7765c*638b*eb
*24dd7716b7da6a0a2b4c63ec3b59edb1627655735efac226966a4750f54065948e8a45ce
c33a55543dad2c81d70a66307ace0870e4ddb97ef28dc147f0954d83136b2e2c3cd2b920c
2b7e1f6a35c3fc7e65e1d3994508e4fcfe8e4d8d477dac181f727d111001654234450530a
8e84d588226c2e5e6a696afd617b56952f3f3e06c4fb6f64e8f365b95fbacf2aa1f4e6a1e
71a5d146ba1b0aa24c7b17890c4f8ebf6e6c48422288dbe7b4279bd1b9065c92c34fa2278
2ad7aa9bc8d666fc7f5ec801c60d979bc3a106ec5ecff82058ac46e139bd6d3e0086d581a
a32d5f98bdaa426f1c58122eaf6c3269b*c658ddbebd8d31abba1c*$/zip2$:破解必读.txt:file.zip:file.zip
```



at the end of the hash, which indicates that the signature is `zip2`, to determine which hash code to use, use `grep`

```bash
hashcat --help | grep zip --ignore-case
```

Output

```
  11600 | 7-Zip                                            | Archives
  17200 | PKZIP (Compressed)                               | Archives
  17220 | PKZIP (Compressed Multi-File)                    | Archives
  17225 | PKZIP (Mixed Multi-File)                         | Archives
  17230 | PKZIP (Mixed Multi-File Checksum-Only)           | Archives
  17210 | PKZIP (Uncompressed)                             | Archives
  20500 | PKZIP Master Key                                 | Archives
  20510 | PKZIP Master Key (6 byte optimization)           | Archives
  23001 | SecureZIP AES-128                                | Archives
  23002 | SecureZIP AES-192                                | Archives
  23003 | SecureZIP AES-256                                | Archives
  13600 | WinZip                                           | Archives
```

The hash code for `zip` is `13600`.

Then we start cracking. Since I have known that the password contains 4 digits consists of lower-case letters and numbers.

```bash
hashcat -a 3 -m 13600 --force file.hash -1 '?d?l' '?1?1?1?1'
```
