---
tags:
  - Gentoo
  - Linux
---

# Ways to convert these notes to batch file, and then execute the commands line by line


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

autoinstall.sh

```bash
#!/bin/bash
input="$1"
echo $input
while IFS= read -r line
do
    eval $line
    if [[ $? != 0 ]]
    then
        echo "Command $line failed. Abroted."
        exit
    fi
done < "$input"
```

genbatch.sh

```bash
#!/bin/bash
input="$1"
if [[ -n $input ]]; then
    grep -v "^#.*$" "$input" | grep -v "^\`\`\`.*$" | grep -v "^$"
else
    echo "Usage: ./genbatch <note.md> > batch.bat"
fi
```

