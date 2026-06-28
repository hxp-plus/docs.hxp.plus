---
tags:
  - Linux
  - 工具
---

Install [aria-ng-GUI](https://github.com/Xmader/aria-ng-gui)

And use [Bilibili-Evolved](https://github.com/the1812/Bilibili-Evolved) to save videos from bilibili

You need a Firefox Browser and [enable mixed content](https://docs.adobe.com/content/help/en/target/using/experiences/vec/troubleshoot-composer/mixed-content.html)

# 在 Mozilla Firefox 中启用混合内容


!!! warning "文档时效性说明"
    本文为早期笔记，可能存在版本过时、命令失效、链接失效、最佳实践变化等问题。请以官方最新文档为准。

原英文标题：Enabling mixed content in Mozilla Firefox #

By default, Firebox blocks pages that mix secure and insecure content. It is recommended that you permanently change this setting to use Target.

In Firefox, enter about:config in the address bar.

Acknowledge the warning message displayed by Firefox.

In the search bar, type block_active .

Double-click **[security.mixed_content.block_active_content]** .

The value changes from "True" to "False." When the value shows "False," you are finished. It is recommended that you restart your computer after changing this setting.
