---
tags:
  - Python
---

# Python 升级所有依赖

## 使用 pip 列出所有不是最新的依赖

```
pip list --outdated
```

输出示例如下：

```
Package                                   Version   Latest    Type
----------------------------------------- --------- --------- -----
Babel                                     2.14.0    2.15.0    wheel
certifi                                   2024.2.2  2024.6.2  wheel
Jinja2                                    3.1.3     3.1.4     wheel
mkdocs-git-revision-date-localized-plugin 1.2.4     1.2.6     wheel
mkdocs-print-site-plugin                  2.4.1     2.5.0     wheel
packaging                                 24.0      24.1      wheel
platformdirs                              4.2.1     4.2.2     wheel
Pygments                                  2.17.2    2.18.0    wheel
pymdown-extensions                        10.8      10.8.1    wheel
regex                                     2024.4.16 2024.5.15 wheel
requests                                  2.31.0    2.32.3    wheel
watchdog                                  4.0.0     4.0.1     wheel
```

## 升级所有依赖

确认无误后，一键升级：

```
pip install -U `pip list --outdated | awk 'NR>2 {print $1}'`
```

之后验证通过后，更新 `requirements.txt` ：

```
pip freeze > requirements.txt
```

# 参考资料

https://stackoverflow.com/questions/2720014/how-to-upgrade-all-python-packages-with-pip
