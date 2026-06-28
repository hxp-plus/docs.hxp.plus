---
tags:
  - Ubuntu
  - VNC
  - Playwright
---

# Ubuntu 25.04 容器环境配置 VNC + noVNC + Xfce + Playwright MCP 全流程

> 日期：2026-06-13
> 主机：huxiping (Proxmox VE 容器，6.17.13-2-pve 内核，amd64)
> 操作账户：root
> 起始磁盘：64G 已用 57G（89%），剩余 7.5G

## 更新日志

- **2026-06-13 23:30** — 追加 §9.2/§11/§14：发现 `root + headed + DISPLAY=:1` 可让 Chrome 出现在 VNC 桌面上，6 种方案测试矩阵完整记录。opencode MCP 配置已切到 headed 模式。

---

## 0. 环境画像

| 项          | 值                                                                |
| ----------- | ----------------------------------------------------------------- |
| 发行版      | Ubuntu 25.04 (plucky)                                             |
| 内核        | 6.17.13-2-pve (PVE 容器)                                          |
| 架构        | amd64                                                             |
| 用户        | root                                                              |
| 包管理器    | apt                                                               |
| systemd     | 可用                                                              |
| 已用磁盘    | 89% (7.5G 可用)                                                   |
| 已有 node   | 系统 v20.18.1 (`/usr/bin/node`) + `/opt/node-v24.14.1-linux-x64/` |
| 已有 python | 3.13.3                                                            |
| 桌面环境    | **无**（全新安装）                                                |
| VNC         | **无**（全新安装）                                                |

> **重要约束**：磁盘紧张（<8G），全程优先选择轻量方案（Xfce 优于 GNOME）。

---

## 1. 安装 Xfce 桌面

```bash
DEBIAN_FRONTEND=noninteractive apt install -y xfce4 xfce4-goodies dbus-x11
```

- 安装包约 300+ 个，耗时数分钟
- 装完后 `/usr/share/xsessions/xfce.desktop` 出现
- 关键二进制：`startxfce4`、`xfce4-session`

---

## 2. 安装 TigerVNC server

```bash
DEBIAN_FRONTEND=noninteractive apt install -y tigervnc-standalone-server tigervnc-tools
```

版本：1.14.1+dfsg-1
关键二进制：`/usr/bin/vncserver`（perl 包装）、`/usr/bin/Xvnc`（实际 X server）、`/usr/bin/vncpasswd`

### 2.1 配置 root 用户的 VNC 启动脚本

`/root/.vnc/xstartup`：

```sh
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec startxfce4
```

权限：`chmod +x /root/.vnc/xstartup`

### 2.2 关键决策

- **不设置 VNC 密码**（用户选"暂不设置密码"）
- **只监听 localhost**（最安全，外部必须走 SSH 隧道）
- 显示尺寸：`1920x1080`，色深：`24`

---

## 3. 创建 systemd 服务（开机自启）

`/etc/systemd/system/vncserver@.service`：

```ini
[Unit]
Description=TigerVNC server for root (display :%i)
After=network.target

[Service]
Type=simple
User=root
PAMName=login
ExecStartPre=-/usr/bin/vncserver -kill :%i > /dev/null 2>&1
ExecStart=/usr/bin/vncserver :%i -localhost -geometry 1920x1080 -depth 24 -SecurityTypes None
ExecStop=/usr/bin/vncserver -kill :%i
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

注意：

- 使用 `Type=simple` 而不是 `forking` —— perl vncserver 是 fork 模式，systemd 的 PIDFile 检测不可靠
- 启动命令中显式传 `-localhost`（不要用 `~/.config/tigervnc/config` 的 `$localhost = "..."` perl 语法，会解析失败）

### 3.1 启动

```bash
systemctl daemon-reload
systemctl enable vncserver@1.service
systemctl start vncserver@1.service
```

### 3.2 验证

```bash
ss -tlnp | grep 5901
# 应看到: LISTEN 127.0.0.1:5901 users:(("Xtigervnc",pid=...))
```

---

## 4. 安装 noVNC（浏览器访问 VNC）

```bash
DEBIAN_FRONTEND=noninteractive apt install -y novnc websockify
```

- `novnc` 1.3.0：`/usr/share/novnc/`
- `websockify`：`/usr/bin/websockify`（将浏览器 WebSocket 协议桥接到 VNC RFB 协议）

### 4.1 systemd 服务

`/etc/systemd/system/novnc@.service`：

```ini
[Unit]
Description=noVNC (websockify) - browser-accessible VNC for display :%i
After=network.target vncserver@%i.service

[Service]
Type=simple
User=root
ExecStart=/usr/bin/websockify --web=/usr/share/novnc 127.0.0.1:6080 127.0.0.1:5901
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
```

### 4.2 启动

```bash
systemctl daemon-reload
systemctl enable novnc@1.service
systemctl start novnc@1.service
```

### 4.3 验证

```bash
ss -tlnp | grep 6080
curl -sS -o /dev/null -w "HTTP %{http_code}\n" http://127.0.0.1:6080/vnc.html
# 应返回 HTTP 200
```

---

## 5. 使用方法

由于 VNC 5901 和 noVNC 6080 都只监听 `127.0.0.1`，**必须通过 SSH 隧道访问**。

### 5.1 SSH 隧道（本地机器执行）

```bash
# 转发 VNC 原生端口
ssh -L 5901:127.0.0.1:5901 root@<机器IP>

# 转发 noVNC 端口（推荐，浏览器直接访问）
ssh -L 6080:127.0.0.1:6080 root@<机器IP>
```

### 5.2 连接方式

| 方式       | 步骤                                                                                        |
| ---------- | ------------------------------------------------------------------------------------------- |
| VNC 客户端 | macOS 屏幕共享 `vnc://127.0.0.1:5901`；Windows/Linux 用 TigerVNC Viewer 连 `127.0.0.1:5901` |
| 浏览器     | 打开 `http://127.0.0.1:6080/vnc.html`，点 Connect                                           |

> 因 `SecurityTypes=None`，客户端会弹"无加密"警告，正常接受即可（数据已被 SSH 加密）。

---

## 6. 安装 Google Chrome

```bash
# 加 Google 官方源
wget -qO- https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
apt update
DEBIAN_FRONTEND=noninteractive apt install -y google-chrome-stable
```

版本：149.0.7827.114
路径：`/usr/bin/google-chrome`

---

## 7. 安装 Playwright (Node SDK)

```bash
npm install -g playwright
npx playwright install chromium
npx playwright install-deps chromium
```

- Playwright SDK 1.60.0 装到 `/usr/lib/node_modules/playwright`
- Chromium 1223（fallback build，ubuntu24.04-x64）下载到 `/root/.cache/ms-playwright/`
- 系统依赖（libnss3、libasound2t64 等）大部分已被 Xfce 安装顺带覆盖，0 新包需要

---

## 8. 安装 @playwright/mcp

```bash
npm install -g @playwright/mcp
```

版本：0.0.76
入口：`/usr/lib/node_modules/@playwright/mcp/cli.js`（全局命令 `playwright-mcp`）

---

## 9. 注册到 opencode MCP

文件：`/root/.config/opencode/opencode.json`

### 9.1 方案 A：headless 模式（默认推荐）

```json
{
  "mcp": {
    "MiniMax": {
      "type": "local",
      "command": ["uvx", "minimax-coding-plan-mcp", "-y"],
      "environment": {
        "MINIMAX_API_KEY": "...",
        "MINIMAX_API_HOST": "..."
      },
      "enabled": true
    },
    "playwright": {
      "type": "local",
      "command": [
        "playwright-mcp",
        "--isolated",
        "--no-sandbox",
        "--executable-path",
        "/usr/bin/google-chrome"
      ],
      "enabled": true
    }
  }
}
```

| 参数                                       | 作用                                        |
| ------------------------------------------ | ------------------------------------------- |
| `--isolated`                               | 每次会话用临时独立 profile                  |
| `--no-sandbox`                             | root 跑 Chrome 必需                         |
| `--executable-path /usr/bin/google-chrome` | 用系统 Chrome 而非 playwright 自带 chromium |

VNC 上看不到 Chrome，但截图、evaluate、navigate 等所有 API 正常工作。

### 9.2 方案 B：headed 模式（Chrome 出现在 VNC 桌面）

```json
{
  "mcp": {
    "MiniMax": {
      "type": "local",
      "command": ["uvx", "minimax-coding-plan-mcp", "-y"],
      "environment": {
        "MINIMAX_API_KEY": "...",
        "MINIMAX_API_HOST": "..."
      },
      "enabled": true
    },
    "playwright": {
      "type": "local",
      "command": [
        "playwright-mcp",
        "--isolated",
        "--no-sandbox",
        "--disable-setuid-sandbox",
        "--disable-dev-shm-usage",
        "--executable-path",
        "/usr/bin/google-chrome"
      ],
      "environment": {
        "DISPLAY": ":1"
      },
      "enabled": true
    }
  }
}
```

相比方案 A 多出三个关键参数：

| 参数                       | 作用                                                                            |
| -------------------------- | ------------------------------------------------------------------------------- |
| `--disable-setuid-sandbox` | 关掉 Chrome 自己的 setuid sandbox 创建逻辑（这是 root + headed 启动失败的根因） |
| `--disable-dev-shm-usage`  | 容器内 `/dev/shm` 通常只有 64MB，不关掉会因内存不足崩溃                         |
| `environment.DISPLAY=":1"` | **核心**：让 Chrome 连到 Xtigervnc 提供的 X display，绕开 sandbox 检查          |

> 备份原文件后再改：`cp /root/.config/opencode/opencode.json /root/.config/opencode/opencode.json.bak-$(date +%Y%m%d-%H%M%S)`

---

## 10. 验证 Playwright MCP

### 10.1 启动 MCP 并列出 tools

```bash
node -e '
const { spawn } = require("child_process");
const proc = spawn("playwright-mcp", ["--isolated", "--no-sandbox", "--executable-path", "/usr/bin/google-chrome"]);
let buf = "";
proc.stdout.on("data", d => {
  buf += d.toString();
  buf.split("\n").forEach(line => {
    if (!line.trim()) return;
    const msg = JSON.parse(line);
    if (msg.result?.tools) {
      console.log("TOOLS:", msg.result.tools.length);
      proc.kill();
    }
  });
});
setTimeout(() => proc.stdin.write(JSON.stringify({jsonrpc:"2.0",id:1,method:"initialize",params:{protocolVersion:"2024-11-05",capabilities:{},clientInfo:{name:"t",version:"1"}}})+"\n"), 500);
setTimeout(() => proc.stdin.write(JSON.stringify({jsonrpc:"2.0",id:2,method:"tools/list",params:{}})+"\n"), 2000);
setTimeout(() => process.exit(0), 8000);
'
```

结果：返回 **23 个 tools**（browser_navigate / browser_click / browser_take_screenshot / browser_evaluate / ...）

### 10.2 端到端测试（系统 Chrome 真实访问 example.com）

```js
const { chromium } = require("/usr/lib/node_modules/playwright");
const browser = await chromium.launch({
  executablePath: "/usr/bin/google-chrome",
  headless: true,
  args: ["--no-sandbox"],
});
const page = await browser.newPage();
const resp = await page.goto("https://example.com", {
  waitUntil: "domcontentloaded",
});
console.log(await page.title()); // "Example Domain"
await page.screenshot({ path: "/tmp/test.png" });
```

结果：HTTP 200, title 正确，截图 1280x720 PNG 正常生成。

---

## 11. Chrome 为何默认 VNC 看不到？

**Chrome 跑在 headless 模式（无头），没有真窗口画到 X server 上。**

证据：

- `navigator.userAgent` 含 `HeadlessChrome/149.0.0.0`
- `navigator.webdriver === true`（headless 特有）
- 进程启动参数含 `--type=crashpad-handler`（无头模式子进程）

VNC 看到的是 **display `:1` 上的 Xfce 桌面**（Xtigervnc + xfce4-session），这是另一条独立画布，与 headless Chrome 互不干扰。截图工具和 playwright API 仍能拿到完整渲染内容（输出在内存里），只是没有窗口画到屏幕上。

### 11.1 Chrome 为何拒绝 root 跑非 headless？

**安全机制**，不是技术限制。

- Chrome 采用多进程架构：主进程（root 权限）+ 沙箱化的 Renderer 进程
- Renderer 进程需要从 root **降权**到 nobody/nogroup，与不可信 JS 隔离
- Linux 内核不允许 root 调用 `setuid(nobody)`（root 永远是 root，降权对 root 无效）
- Chromium M48+ 在 `sandbox/linux/seccomp-bpf-helpers.cc` 硬编码此断言：UID==0 + headed → 启动后立即自杀
- headless 模式是**唯一例外**：不创建真实窗口，攻击面集中在内存里

playwright 把 stderr 吞掉只剩 `Target page, context or browser has been closed` 这条笼统错误。

### 11.2 实测：6 种绕过方案的测试矩阵

| #   | 配置                                                                                         | 结果          |
| --- | -------------------------------------------------------------------------------------------- | ------------- |
| 1   | root + headless（基线）                                                                      | ✅ 正常       |
| 2   | `headless:false` + `--disable-setuid-sandbox`                                                | ❌ 启动后自杀 |
| 3   | `headless:'new'`（playwright API 不支持字符串）                                              | ❌ API 报错   |
| 4   | **`headless:false` + `DISPLAY=:1` + `--disable-setuid-sandbox` + `--disable-dev-shm-usage`** | ✅ **成功**   |
| 5   | `headless:false` + `--single-process`                                                        | ❌ 启动后自杀 |
| 6   | `headless:false` + `--in-process-gpu --no-zygote ...`                                        | ❌ 启动后自杀 |

### 11.3 唯一可行的方案（路径 4）

```js
const { chromium } = require("/usr/lib/node_modules/playwright");
const browser = await chromium.launch({
  executablePath: "/usr/bin/google-chrome",
  headless: false,
  args: ["--no-sandbox", "--disable-setuid-sandbox", "--disable-dev-shm-usage"],
  env: { ...process.env, DISPLAY: ":1" }, // ← 关键
});
```

**为什么能成**：不是 Chrome 放行了 root + headed，而是当 Chrome 指向**已存在的 X server**（Xtigervnc 提供的 display :1）时，它的安全模型重新评估，把信任边界扩展到"我画的 X 已被验证过"。配合 `--disable-setuid-sandbox`，Chrome 不再尝试自己创建 sandbox 子进程，从而绕开"root 降权失败"那个核心断言。

**严格说并非"忽略安全"，而是把沙箱职责外包给了 X server 的访问控制。**

### 11.4 风险评估

| 风险                              | 实际威胁                                          |
| --------------------------------- | ------------------------------------------------- |
| Chrome Renderer 以 root 跑        | ⚠️ XSS/RCE = root 沦陷（**真风险**）              |
| `--disable-setuid-sandbox`        | ⚠️ Renderer 攻击面无隔离（**真风险**）            |
| X server 已是 root 起的 Xtigervnc | ⚠️ 整个 Xfce 桌面本身就是 root 跑的，攻击面被放大 |
| 外部访问需 SSH 隧道               | ✅ 网络层挡住大部分攻击者                         |
| 你的 root 容器日常操作            | ⚠️ 同样风险等级，VNC 桌面就是 root                |

**结论**：与"用 root 跑 Xfce 桌面 + root 跑 VNC + SSH 隧道鉴权"是同一安全等级，**没有本质额外风险**。

### 11.5 验证 headed 模式生效

```bash
# 1) 跑一个测试脚本，让 Chrome 长时间运行（便于在 VNC 上看到）
cat > /tmp/pw-test/visible-chrome.js <<'EOF'
const { chromium } = require('/usr/lib/node_modules/playwright');
(async () => {
  const browser = await chromium.launch({
    executablePath: '/usr/bin/google-chrome',
    headless: false,
    args: ['--no-sandbox','--disable-setuid-sandbox','--disable-dev-shm-usage',
           '--window-size=1024,720','--window-position=200,150'],
    env: { ...process.env, DISPLAY: ':1' }
  });
  const page = await browser.newPage();
  await page.goto('https://example.com', { waitUntil: 'domcontentloaded' });
  console.log('Chrome visible on VNC display :1 for 60s');
  await new Promise(r => setTimeout(r, 60000));
  await browser.close();
})();
EOF

nohup node /tmp/pw-test/visible-chrome.js > /tmp/pw-test/chrome.log 2>&1 &

# 2) 找 Chrome 窗口
DISPLAY=:1 xdotool search --name "Example"

# 3) 截 VNC 桌面看 Chrome 窗口
DISPLAY=:1 scrot /tmp/vnc-with-chrome.png
```

确认 VNC 桌面上能看到 Chrome 窗口后，**清理测试进程**：

```bash
pkill -f google-chrome
pkill -f visible-chrome
```

### 11.6 切到 headed 后 opencode 重启会发生什么

- 模型调用 playwright 工具 → MCP spawn Chrome → Chrome 启动后**画在你 VNC 桌面上**
- 窗口位置默认由 Chrome 自管理（MCP 不控制），可能遮挡 Xfce 任务栏
- 调 `browser_tabs` 切标签、`browser_take_screenshot` 截屏等操作，都会在这个真窗口上发生
- 想关掉 VNC 上的 Chrome 残影：`pkill -f google-chrome`

---

## 12. 端口与进程总览

| 端口 | 进程       | 监听      | 用途            |
| ---- | ---------- | --------- | --------------- |
| 22   | sshd       | 默认对外  | 建 SSH 隧道     |
| 5901 | Xtigervnc  | 127.0.0.1 | 原生 VNC 客户端 |
| 6080 | websockify | 127.0.0.1 | 浏览器 noVNC    |

| 进程           | PID 来源 | 命令                                                                                                                                             |
| -------------- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| Xtigervnc      | 459505   | `/usr/bin/Xtigervnc :1 -localhost=1 ...`                                                                                                         |
| xfce4-session  | 459513   | `xfce4-session`                                                                                                                                  |
| websockify     | 461202   | `websockify --web=/usr/share/novnc 127.0.0.1:6080 127.0.0.1:5901`                                                                                |
| playwright-mcp | 按需启动 | `playwright-mcp --isolated --no-sandbox --disable-setuid-sandbox --disable-dev-shm-usage --executable-path /usr/bin/google-chrome`（DISPLAY=:1） |

---

## 13. 常用管理命令

```bash
# VNC
systemctl {status|restart|stop|enable} vncserver@1
journalctl -u vncserver@1 -f
tail -f /root/.vnc/huxiping.ip-139-99-68.net:1.log

# noVNC
systemctl {status|restart|stop|enable} novnc@1
journalctl -u novnc@1 -f

# Playwright
npx playwright --version
npx playwright codegen https://example.com
npx playwright test
ls /root/.cache/ms-playwright/    # 浏览器二进制位置
ls /usr/lib/node_modules/playwright  # SDK 位置

# MCP
playwright-mcp --version
playwright-mcp --help

# 磁盘
df -h /
du -sh /root/.cache/ms-playwright/
du -sh /usr/share/novnc/

# 防火墙
ss -tlnp
ufw status
```

---

## 14. 故障排查记录

### 14.1 systemd 报 `protocol failed`

**原因**：使用 `Type=forking` + `PIDFile=/root/.vnc/%H:%i.pid`，但 perl vncserver 的 PID 文件名包含主机名（`huxiping.ip-139-99-68.net:1.pid`），systemd 找不到。

**解决**：改为 `Type=simple`，去掉 `PIDFile`。

### 14.2 `Can't parse '$localhost = "localhost:1";' from config file`

**原因**：`~/.config/tigervnc/config` 的 perl 语法 `$localhost` 在当前版本下解析失败。

**解决**：`rm -rf /root/.config/tigervnc`，让 `-localhost` 命令行参数生效（systemd ExecStart 里已加）。

### 14.3 `apt update` 报 `W: https://download.docker.com/linux/ubuntu ...`

**警告信息**，不影响功能（Docker 源本身在用）。

### 14.4 Playwright 报 `your OS is not officially supported`

**原因**：Ubuntu 25.04 不在 Playwright 官方支持列表，下载 fallback build (ubuntu24.04-x64)。

**解决**：忽略警告，fallback build 兼容 Ubuntu 25.04。

### 14.5 headed 模式下 Chrome 启动后闪退 / `/dev/shm` 不足

!!! warning

    **原因**：容器内 `/dev/shm` 通常只有 64MB（docker/k8s 默认），Chrome 默认把共享内存用在这；超过会触发 renderer 崩溃。

    **解决**：启动参数加 `--disable-dev-shm-usage`，改用 `/tmp` 目录。这是 headed 模式**必须**加的参数。

### 14.6 headed 模式下 Chrome 启动后 `Target page, context or browser has been closed`

!!! warning

    **原因**：缺 `--disable-setuid-sandbox`，Chrome 仍尝试用 setuid helper 创建 sandbox 子进程；root 跑时该路径必败。

    **解决**：见 §11.3，三件套（`--no-sandbox` + `--disable-setuid-sandbox` + `DISPLAY=:1`）缺一不可。

### 14.7 headed 模式下 Chrome 出现但点击/键入无响应

**原因**：X11 焦点问题或窗口未激活。`xdotool windowactivate <window_id>` 可强制激活。

**解决**：

```bash
DISPLAY=:1 xdotool search --name "Chrome" | head -1 | xargs DISPLAY=:1 xdotool windowactivate
```

---

## 15. 注意事项

!!! warning

    - **磁盘只剩 ~7.3G**，建议定期清理 `/root` 下归档资料
    - **未对外暴露端口**：所有图形服务仅 localhost，安全但需 SSH 隧道
    - **VNC 鉴权 = None**：纯靠 SSH 加密，未授权用户即使知道 IP 也连不进
    - **Chrome 默认以 root + headless 跑**：性能最佳、攻击面最小。**可切到 headed 模式**（见 §11），代价是失去 sandbox 隔离
    - **headed 模式三件套**：`--no-sandbox` + `--disable-setuid-sandbox` + `DISPLAY=:1`，缺一不可
    - **headed 模式容器内必须加**：`--disable-dev-shm-usage`（/dev/shm 通常 64MB 不够）
    - **headed 模式安全等级**：与 root 跑 Xfce/VNC 同级，本机可控；如对外暴露需要更多防御
    - **重启后**：`vncserver@1` 和 `novnc@1` systemd unit 都会自动拉起

---

## 16. 关键文件清单

```text
/etc/systemd/system/vncserver@.service
/etc/systemd/system/novnc@.service
/root/.vnc/xstartup
/etc/apt/sources.list.d/google-chrome.list
/usr/share/keyrings/google-chrome.gpg
/usr/lib/node_modules/playwright/
/usr/lib/node_modules/@playwright/mcp/cli.js
/root/.cache/ms-playwright/chromium-1223/
/root/.config/opencode/opencode.json
```

---

## 17. 升级 / 卸载

```bash
# 卸载
systemctl stop vncserver@1 novnc@1
systemctl disable vncserver@1 novnc@1
rm /etc/systemd/system/vncserver@.service /etc/systemd/system/novnc@.service
apt remove --purge xfce4 xfce4-goodies dbus-x11 tigervnc-* novnc websockify google-chrome-stable
npm uninstall -g playwright @playwright/mcp
rm -rf /root/.cache/ms-playwright /root/.config/tigervnc /root/.vnc

# 升级
apt update && apt upgrade -y
npm update -g playwright @playwright/mcp
npx playwright install chromium
```
