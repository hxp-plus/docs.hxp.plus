---
tags:
  - Linux
  - 工具
---

# Crack Multi-file large rar password


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

## 步骤 0：前置条件

### 编译 John the ripper

从 <https://github.com/openwall/john> 下载源码，解压并编译：

```bash
# Assume that the zip file is located in the current working directory
unzip john-bleeding-jumbo.zip
cd john-bleeding-jumbo
cd src
./configure
make -j${nproc}
```

所有二进制可执行文件（包括 `rar2john`）都会在 `../run` 下生成。

## 编译 Hashcat

从 <https://github.com/hashcat/hashcat> 下载源码 zip，解压并编译：

```bash
# Assume that the zip file is located in the current directory
unzip hashcat-master.zip
make -j${nproc}
```

可执行文件 `hashcat` 会在当前目录生成。

## 安装 rar

需要 `rar` 命令来创建用于测试的 rar 压缩包。但 rar 已从 yum 仓库中移除。

从 <http://rpmfind.net/linux/rpm2html/search.php?query=rar> 下载 rar 包

```bash
wget http://rpmfind.net/linux/atrpms/f20-x86_64/atrpms/stable/rar-4.2.0-4.fc20.i686.rpm
```

然后通过 yum 本地安装

```bash
sudo yum localinstall rar-4.2.0-4.fc20.i686.rpm
```

## 安装 unrar

可以通过 yum 仓库安装 `unrar` 命令

```bash
sudo yum install unrar
```

## 准备一个加密的 rar 压缩包

```bash
echo "This is an Encrypted file" > encrypted.txt
# Create an rar archive whose password is "pwd1"
rar a -p"pwd1" encrypted.rar encrypted.txt
rm encrypted.txt
# Verify the password we created
unrar e encrypted.rar
```

## 步骤 1：从 rar 中提取哈希

从 rar 文件中提取哈希：

```bash
/path/to/rar2john encrypted.rar | tail -n1 | cut -d : -f2 > encrypted.rar.hash
```

对哈希做一些小的编辑：使其看起来像 <https://hashcat.net/wiki/doku.php?id=example_hashes> 中的示例哈希。

## 步骤 2：暴力破解哈希

查询 rar 的哈希代码

```bash
/path/to/hashcat --help | grep -i rar
```

输出结果为：

```
  12500 | RAR3-hp                                          | Archives
  23800 | RAR3-p (Compressed)                              | Archives
  23700 | RAR3-p (Uncompressed)                            | Archives
  13000 | RAR5                                             | Archives
```

这表明 rar 有 2 种加密方式：rar3 和 rar5。

查看提取的哈希

```bash
cat encrypted.rar.hash
```

输出：

```
encrypted.rar:$RAR3$*1*50d054eef44984dc*4a6fff1f*48*26*1*db17e71ed5e0d46832ce34939fa9ae4862b897d72a09f089abfc850e75f8d894d9d42c5e4bb2df24b90d036c4cd96df8*33:1::encrypted.txt 
```

表明该哈希是 rar3 加密的。因此我运行了

```bash
## Assume password contains 3 to 5 lowercase letters or numbers.
/path/to/hashcat -a 3 -m 23800 --force encrypted.rar.hash -1 '?d?l' '?1?1?1?1?1' -i --increment-min 3
```

过了一会儿，hashcat 完成了破解并退出。

运行

```bash
/path/to/hashcat -a 3 -m 23800 --show encrypted.rar.hash
```

查看破解出的密码。

要删除已破解的结果，运行：

```bash
rm /path/to/hashcat/hashcat.potfile
```

---

## 原文（English）

## Step 0: Prerequisites

### Compile John the ripper

Download source code from <https://github.com/openwall/john>, unzip and compile:

```bash
# Assume that the zip file is located in the current working directory
unzip john-bleeding-jumbo.zip
cd john-bleeding-jumbo
cd src
./configure
make -j${nproc}
```

all the binary executable, including `rar2john`, will be created under `../run`

## Compile Hashcat

Download source zip from <https://github.com/hashcat/hashcat>, unzip and complie:

```bash
# Assume that the zip file is located in the current directory
unzip hashcat-master.zip
make -j${nproc}
```

the executable `hashcat` will be created in current directory

## Install rar

The rar command is needed to create an rar archive for testing. But rar has been removed from yum repos

Download rar package from <http://rpmfind.net/linux/rpm2html/search.php?query=rar>

```bash
wget http://rpmfind.net/linux/atrpms/f20-x86_64/atrpms/stable/rar-4.2.0-4.fc20.i686.rpm
```

And install via yum locally

```bash
sudo yum localinstall rar-4.2.0-4.fc20.i686.rpm
```

## Install unrar

The unrar command can be installed via yum repositories

```bash
sudo yum install unrar
```

## Prepare an encrypted rar archive

```bash
echo "This is an Encrypted file" > encrypted.txt
# Create an rar archive whose password is "pwd1"
rar a -p"pwd1" encrypted.rar encrypted.txt
rm encrypted.txt
# Verify the password we created
unrar e encrypted.rar
```

## Step 1: Extract hash from rar

Extract hash from rar file:

```bash
/path/to/rar2john encrypted.rar | tail -n1 | cut -d : -f2 > encrypted.rar.hash
```

Do some small edit to the hash: make the hash looks like the example hashes in <https://hashcat.net/wiki/doku.php?id=example_hashes>

## Step 2: Brute-force hash

Query the hash code for rar

```bash
/path/to/hashcat --help | grep -i rar
```

the output result was:

```
  12500 | RAR3-hp                                          | Archives
  23800 | RAR3-p (Compressed)                              | Archives
  23700 | RAR3-p (Uncompressed)                            | Archives
  13000 | RAR5                                             | Archives
```

which indicated that there are 2 types of rar encrypting method: rar3 and rar5

took a look at the hash extracted

```bash
cat encrypted.rar.hash
```

output:

```
encrypted.rar:$RAR3$*1*50d054eef44984dc*4a6fff1f*48*26*1*db17e71ed5e0d46832ce34939fa9ae4862b897d72a09f089abfc850e75f8d894d9d42c5e4bb2df24b90d036c4cd96df8*33:1::encrypted.txt 
```

indicated that the hash is rar3 encrypted. So I ran

```bash
## Assume password contains 3 to 5 lowercase letters or numbers.
/path/to/hashcat -a 3 -m 23800 --force encrypted.rar.hash -1 '?d?l' '?1?1?1?1?1' -i --increment-min 3
```

After a while, hashcat finished cracking and quited.

Run

```bash
/path/to/hashcat -a 3 -m 23800 --show encrypted.rar.hash
```

to view the cracked password. 

To delete cracked results, run:

```bash
rm /path/to/hashcat/hashcat.potfile
```
