# PROJECT KNOWLEDGE BASE

**Generated:** 2026-06-27
**Commit:** 7773c30
**Branch:** master
**Site:** https://docs.hxp.plus

## OVERVIEW

hxp 的中文个人文档库。MkDocs Material 主题，GitHub Actions 自动 `mkdocs gh-deploy` 到 GitHub Pages。86 篇 md，全部中文，主题为 Linux/运维/容器/虚拟化/存储笔记。

## STRUCTURE

```
.
├── mkdocs.yml              # 站点配置（nav 手动维护，必须随新文档同步）
├── Dockerfile              # 本地预览容器：squidfunk/mkdocs-material:9.5.27
├── .github/workflows/ci.yml # push master/main → mkdocs gh-deploy --force
├── README.md               # 极简（仅 build/run 说明）
├── .editorconfig           # md=2空格 / yaml=2空格 / trim_trailing_whitespace=false
└── docs/
    ├── index.md            # 站点首页（个人简介 + RHCA/CKA 等证书徽章）
    ├── tags.md             # tags 插件占位符（仅 <!-- material/tags -->）
    ├── CNAME               # docs.hxp.plus 自定义域
    ├── images/             # 仅首页证书图（9 张 PNG）
    ├── overrides/main.html # Material 主题覆盖（print 按钮已注释，dormant）
    ├── stylesheets/extra.css # 图片黑边框 + 链接/代码 word-break:break-all（适配 CJK）
    ├── 容器技术/            # Kubernetes (11) / Docker&Podman (2)
    ├── 前端开发/            # Vue3 (1)
    ├── 存储技术/            # Ceph / ZFS / TrueNAS（各 1）
    ├── 运维开发/            # AWX (8) / Keycloak (4) / 笔记及文档软件 (3) / Git使用 (6) / Python (4) / Java (2) / Shell (1) / Rust (2)
    ├── 折腾Linux/          # 通用Linux (8) / Gentoo (6) / OpenWrt (8) / Ubuntu (1) / RHEL6 (1) / 中标麒麟V7 (2) / 银河麒麟V10 (2)
    └── 虚拟化技术/          # Hyper-V (3) / QEMU (2) / 华为云 (1)
```

## WHERE TO LOOK

| 任务 | 位置 | 备注 |
|------|------|------|
| 新增文档 | `docs/<分类>/<子类>/` + `mkdocs.yml` nav | **两处都要改**，否则不显示 |
| 改首页 | `docs/index.md` | 个人简介 + 9 张证书 PNG |
| 改主题/CSS | `docs/stylesheets/extra.css` + `docs/overrides/main.html` | 主题在 `mkdocs.yml theme:` |
| 加插件 | `mkdocs.yml plugins:` + `Dockerfile` pip + `ci.yml` pip | **三处都要同步**（见 ANTI-PATTERNS）|
| 改导航分类 | `mkdocs.yml` nav: 段（28-141 行） | 手动维护，无 auto-discovery |
| 看构建产物 | `site/`（已 gitignore） | `mkdocs build` 生成 |
| 本地预览 | `docker run -p 8001:8000 ...` | 见 COMMANDS |
| 查标签云 | `docs/tags.md`（自动生成） | 由 `tags` 插件从 front-matter 聚合 |

## CONVENTIONS

### Front-matter（强制规范）

**所有内容页**必须以 YAML front-matter 开头，**只用 `tags` 字段**：

```yaml
---
tags:
  - Kubernetes
  - K3S
  - AWX
---

# H1 标题（与文件名一致）
```

- **不要**写 `title:` / `description:` / `date:` —— H1 即标题，日期由 `git-revision-date-localized` 插件自动注入
- 标签是裸字符串（中文/英文均可），无引号、无层级
- 87% 文件已遵守；**11 篇缺失** front-matter（见 ANTI-PATTERNS）

### 文件命名

- 中文标题直接做文件名（**不用** kebab-case slug）
- 可含空格、全角引号 `“”`、括号 —— mkdocs slugifier 会 URL 编码，**可接受**
- 例：`virt-manager创建虚拟机报错"Did not find any UEFI binary path for arch 'aarch64'"问题.md`

### 图片存储

- **每个主题目录**有自己的 `images/` 子目录（不是全局 `docs/images/`）
- 引用用相对路径：`![](./images/xxx.png)`
- 图片名也常为中文（如 `获取LocationPath.png`）
- 仅 `docs/images/` 是全局的，存首页证书徽章
- **唯一例外**：`折腾Linux/OpenWrt/attachments/` 存二进制固件包（`.7z`/`.bin`/`.zip`）

### 写作风格

- 全中文，技术术语保留英文（Kubernetes、helm、traefik）
- 教程式：环境画像表 → 命令块 → 故障排查
- 代码块标注语言（```bash / ```yaml / ```powershell）
- 已启用 `pymdownx.superfences` + `pymdownx.tabbed` + `pymdownx.tasklist`
- 已启用 `pymdownx.details`，但**项目内从未使用** `???` 折叠块
- Admonition 用 4 空格缩进：`!!! note`、`!!! warning`、`!!! tip`、`!!! info`

## ANTI-PATTERNS（本项目禁止）

1. **❌ CI 插件未 pin 版本** —— `.github/workflows/ci.yml` 用 `pip install mkdocs-material ...` 无版本约束；Dockerfile pin 在 `9.5.27`。CI 与本地可能漂移导致构建失败。**改插件时三处同步**：`mkdocs.yml` + `Dockerfile` pip + `ci.yml` pip。
2. **❌ 改 nav 忘记同步** —— `mkdocs.yml` 的 `nav:` 是**手动维护**的，新增 md 后必须在 nav 加条目，否则页面存在但不在侧边栏。
3. **❌ 漏写 front-matter** —— 11 篇文件缺 `tags:`，导致它们从 `docs/tags.md` 标签云消失。新增文档必须带 front-matter。
4. **❌ 删除/移动文件不改 nav** —— nav 引用的是相对路径，移动文件后路径会断。
5. **❌ 用 `index.md` 做子目录首页** —— 本项目**只有** `docs/index.md` 一个首页，24 个子目录均无 index.md。不要新增。
6. **❌ 在 `docs/` 外放内容** —— mkdocs 只读 `docs/`，根目录的 md 不会被构建（当前根目录有 2 篇待归位文档，见 NOTES）。
7. **❌ 改 `add-number` 插件配置** —— `strict_mode: False` + `order: 2` 会自动给所有 H1 编号（除 `tags.md`）；改配置会影响整站编号。
8. **❌ 改 `font: false`** —— 故意禁用 Material 的 Google Fonts，避免 CJK 字体 CDN 问题；改回 `true` 可能在国内访问变慢。
9. **❌ 用 `???` 折叠 admonition** —— 虽然插件支持，但项目内 0 处使用，保持一致用 `!!!`。
10. **❌ 启用 `edit_uri`** —— 当前未配置，无"编辑此页"按钮；如需启用要同时配置 GitHub repo 路径。

## UNIQUE STYLES

- **`docs/stylesheets/extra.css`** 三条规则：
  - `.md-content img { border: 1px solid black }` —— 所有内容图片带 1px 黑边框
  - `.md-typeset a { word-break: break-all }` —— 长链接任意位置断行（CJK 适配）
  - `.md-typeset code { word-break: break-all }` —— 内联代码同上
- **单色板** —— `palette.primary: indigo`，**无深浅色切换**（无 toggle）
- **`font: false`** —— 禁用 Google Fonts CDN，纯系统字体
- **`add-number` 插件** —— 自动给 H1 加数字前缀（如 `1. 银河麒麟V10安装Kubernetes`），`strict_mode: False` 表示遇到无 H1 的页静默跳过
- **`git-revision-date-localized`** —— 页脚自动显示创建/更新日期（中文 locale）
- **`print-site` 插件** —— 已启用，但 `overrides/main.html` 里触发按钮被注释，**功能 dormant**

## COMMANDS

```bash
# 本地预览（推荐，与 Dockerfile pin 版本一致）
docker build -t mkdocs .
docker run -p 8001:8000 -v "$PWD":/docs mkdocs
# 访问 http://localhost:8001

# 直接用系统 Python（不推荐，需自行 pip install 同版本插件）
mkdocs serve -a 0.0.0.0:8000

# 构建静态站点到 site/（CI 也跑这个再 gh-deploy）
mkdocs build

# 手动部署到 GitHub Pages（CI 已自动化，谨慎手动）
mkdocs gh-deploy --force
```

## NOTES

### 当前根目录 2 篇待归位 md（未在 docs/ 内，未在 nav 中）

1. **`ubuntu-vnc-novnc-xfce-playwright-setup.md`** (623 行)
   - 主题：Ubuntu 25.04 容器 + Xfce + TigerVNC + noVNC + Playwright MCP 全流程
   - **建议归位**：`docs/折腾Linux/Ubuntu/Ubuntu 25.04容器环境配置VNC+noVNC+Xfce+Playwright MCP全流程.md`
   - 理由：纯 Ubuntu 配置笔记，`折腾Linux/Ubuntu/` 现仅 1 篇，主题完美匹配
   - 归位前需加 front-matter：`tags: [Ubuntu, VNC, Playwright]`

2. **`windows部署vllm和qwen模型.md`** (93 行)
   - 主题：Windows WSL2/Docker + RTX 5090 + vLLM + Qwen3.6-35B 26 万上下文调优
   - **建议归位 A（推荐）**：`docs/容器技术/Docker&Podman/RTX 5090单卡极限长上下文部署调优指南.md`
     - 理由：本质是 `docker run` 工作流，`Docker&Podman` 已收纳类似深度文（如 eBPF 容器审计）
   - **建议归位 B（未来若 AI 文档增多）**：新建顶层 `docs/AI与LLM部署/`，同时改 nav
   - 归位前需加 front-matter：`tags: [Docker, vLLM, Qwen, RTX5090]`

### 已知小瑕疵（不影响构建）

- `mkdocs.yml` 第 134 行 `Hyper-V网卡直通: Hyper-V网卡直通.md` 缺路径前缀（其他条目都有 `虚拟化技术/Hyper-V/`）
- `mkdocs.yml` 第 137-138 行用 `./` 前缀，与其他条目风格不一致
- `overrides/main.html` 的 print 按钮 HTML 被注释，是 dead code
- `site/`、`.cache/`、`venv/` 已 gitignore

### 依赖矩阵（改插件时三处同步）

| 位置 | 内容 |
|------|------|
| `mkdocs.yml` `plugins:` | 启用/配置插件 |
| `Dockerfile` `pip install` 行 | 本地预览装包（pin 在 mkdocs-material 9.5.27） |
| `.github/workflows/ci.yml` `pip install` 行 | CI 装包（**未 pin 版本**，可能漂移） |

### 站点语言

全中文（`theme.language: zh`）。所有 nav 条目、tag、文件名均中文优先。技术术语保留英文原文。
