📡 **OpenClaw 技术简报** | 2026-03-14

1. **[Bug]: 2026.3.12 内存泄漏 - 基本命令（gateway status, doctor）导致 OOM · Issue #45064 · openclaw/openclaw**
- 📅 2026-03-13
- 📝 报告 OpenClaw 2026.3.12 版本中执行基本 CLI 命令如 gateway status 或 doctor 导致应用内存泄漏和 OOM 错误。
- 🔗 https://github.com/openclaw/openclaw/issues/45064

---

2. **[Bug]: WhatsApp 外发路径中断：自动回复正常，消息工具/CLI 发送失败报“No active WhatsApp Web listener”（2026.3.12） · Issue #45171 · openclaw/openclaw**
- 📅 2026-03-13
- 📝 报告 openclaw 项目中 WhatsApp 外发消息路径回归问题，CLI 发送失败但自动回复正常。
- 🔗 https://github.com/openclaw/openclaw/issues/45171

---

3. **feat(exec): 将 NO_DNA 传播到子命令 · Pull Request #44947 · openclaw/openclaw**
- 📅 2026-03-13
- 📝 该 PR 修复子进程未继承 NO_DNA 标记的问题，用于指示非人类操作并传播到子命令。
- 🔗 https://github.com/openclaw/openclaw/pull/44947

---

4. **添加 ModelScope API 支持 · Pull Request #44871 · openclaw/openclaw**
- 📅 2026-03-13
- 📝 引入 ModelScope API 支持，允许用户通过 API 密钥访问社区模型，涉及 3 个提交和 499 行代码添加。
- 🔗 https://github.com/openclaw/openclaw/pull/44871

---

5. **[Bug]: 2026.3.12 启动崩溃：Cannot access 'ANTHROPIC_MODEL_ALIASES' before initialization · Issue #44781 · openclaw/openclaw**
- 📅 2026-03-13
- 📝 报告 2026.3.12 版本启动时崩溃，与 Anthropic 配置相关初始化问题。
- 🔗 https://github.com/openclaw/openclaw/issues/44781

---

6. **[WebUI] 为聊天控件使用响应式 CSS 工具提示 · Pull Request #44953 · openclaw/openclaw**
- 📅 2026-03-13
- 📝 更新 OpenClaw WebUI，替换聊天控件图标（如 Refresh、Thinking Mode）的原生 title 属性工具提示为响应式 CSS 版本。
- 🔗 https://github.com/openclaw/openclaw/pull/44953

---

7. **开源了一个 OpenClaw 运维工具 - V2EX**
- 📅 2026-03-12
- 📝 宣布开源“simple-openclaw”工具，一键自动化 Node.js、构建工具和 OpenClaw 的服务器部署与维护。
- 🔗 https://v2ex.com/t/1197851

---

8. **fix(wizard): 在 onboarding 期间跳过 auth 时警告用户 · Pull Request #44217 · openclaw/openclaw**
- 📅 2026-03-12
- 📝 修复 onboarding 跳过认证导致代理不可用无警告的 bug，现在添加用户警告以提升体验。
- 🔗 https://github.com/openclaw/openclaw/pull/44217

---

9. **[Bug] v2026.3.11: doctor --fix 循环报告虚假的遗留 cron payload kind 规范化问题 · Issue #43796 · openclaw/openclaw**
- 📅 2026-03-12
- 📝 报告 v2026.3.11 版本中 doctor --fix 反复标记已修复的遗留 cron payload kind 规范化问题。
- 🔗 https://github.com/openclaw/openclaw/issues/43796
