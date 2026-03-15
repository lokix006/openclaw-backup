📡 **OpenClaw 技术简报** | 2026-03-14

1. **国内厂商云部署 OpenClaw 活动讨论 - V2EX**
- 📅 2026-03-13
- 📝 社区讨论中国科技公司推广 OpenClaw 云部署平台的动机，担忧数据收集或云服务销售目的。
- 🔗 https://v2ex.com/t/1197921

---

2. **feat(exec)：将 NO_DNA 传播到子命令 · Pull Request #44947 · openclaw/openclaw**
- 📅 2026-03-13
- 📝 该拉取请求修复 OpenClaw 中子进程未继承 NO_DNA 标记的问题，确保下游工具正确识别非人类执行。
- 🔗 https://github.com/openclaw/openclaw/pull/44947

---

3. **[Bug]：2026.3.12 版本基本命令内存泄漏 - OOM（gateway status, doctor） · Issue #45064 · openclaw/openclaw**
- 📅 2026-03-13
- 📝 GitHub 问题报告 OpenClaw 2026.3.12 版本执行基本 CLI 命令如 gateway status 或 doctor 时导致 JavaScript 堆内存耗尽。
- 🔗 https://github.com/openclaw/openclaw/issues/45064

---

4. **[Bug]：WhatsApp 外发路径中断：自动回复正常，消息工具/CLI 发送失败（2026.3.12） · Issue #45171 · openclaw/openclaw**
- 📅 2026-03-13
- 📝 GitHub 问题报告 OpenClaw 项目中 WhatsApp 外发消息回归问题，CLI 发送失败显示无活跃 WhatsApp Web 监听器。
- 🔗 https://github.com/openclaw/openclaw/issues/45171

---

5. **添加 ModelScope API 支持 · Pull Request #44871 · openclaw/openclaw**
- 📅 2026-03-13
- 📝 该拉取请求为 OpenClaw 项目引入 ModelScope API 支持，用户可通过 API 密钥访问社区模型，涉及 3 个提交和 499 行代码添加。
- 🔗 https://github.com/openclaw/openclaw/pull/44871

---

6. **[Bug]：OpenClaw 2026.3.11 破坏 moonshotai/kimi-k2.5 模型工具执行 · Issue #44549 · openclaw/openclaw**
- 📅 2026-03-13
- 📝 GitHub 问题报告 OpenClaw 2026.3.11 版本通过 openai-completions 使用 moonshotai/kimi-k2.5 模型时所有工具执行失效。
- 🔗 https://github.com/openclaw/openclaw/issues/44549

---

7. **[WebUI]：为聊天控件使用响应式 CSS 工具提示 · Pull Request #44953 · openclaw/openclaw**
- 📅 2026-03-13
- 📝 该拉取请求更新 OpenClaw WebUI，将聊天控件图标的原生 title 属性工具提示替换为自定义 CSS 工具提示，提升响应式设计。
- 🔗 https://github.com/openclaw/openclaw/pull/44953

---

8. **fix(wizard)：引导过程中跳过认证时警告用户 · Pull Request #44217 · openclaw/openclaw**
- 📅 2026-03-12
- 📝 该拉取请求修复 OpenClaw 项目中引导过程跳过认证导致代理不可用且无明确反馈的用户体验问题。
- 🔗 https://github.com/openclaw/openclaw/pull/44217

---

9. **[Bug] v2026.3.11：doctor --fix 循环报告遗留 cron 负载规范化问题 · Issue #43796 · openclaw/openclaw**
- 📅 2026-03-12
- 📝 GitHub 问题报告 OpenClaw v2026.3.11 版本运行 doctor --fix 时反复标记遗留 cron 负载规范化问题，即使所有作业已修复。
- 🔗 https://github.com/openclaw/openclaw/issues/43796
