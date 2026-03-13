📡 **OpenClaw 技术简报** | 2026-03-12

1. **修复自动续订OAuth配置文件的过期显示 · Pull Request #43122**
- 📅 2026-03-11
- 📝 该拉取请求解决了OpenClaw项目中OAuth配置文件过期显示的bug，避免系统错误展示过时信息。
- 🔗 https://github.com/openclaw/openclaw/pull/43122

---

2. **Cron作业在更新至2026.3.8后失效 · Issue #42883**
- 📅 2026-03-11
- 📝 GitHub问题报告了OpenClaw项目中更新至2026.3.8版本后Cron作业停止运行的回归bug，此前正常工作。
- 🔗 https://github.com/openclaw/openclaw/issues/42883

---

3. **Cron：允许主和工作系统事件作业的模型覆盖 · Pull Request #42708**
- 📅 2026-03-11
- 📝 该拉取请求引入功能，允许特定会话和负载类型的Cron作业覆盖默认模型设置。
- 🔗 https://github.com/openclaw/openclaw/pull/42708

---

4. **修复Mattermost多工具调用响应的独立流式传输 · Pull Request #43041**
- 📅 2026-03-11
- 📝 该拉取请求解决了OpenClaw项目中Mattermost集成多轮工具调用响应未正确流式的bug。
- 🔗 https://github.com/openclaw/openclaw/pull/43041

---

5. **openclaw models status --probe在2026.3.8上返回LLM请求超时 · Issue #41874**
- 📅 2026-03-10
- 📝 GitHub问题报告了2026.3.8版本中命令执行约8.4秒后请求超时的bug。
- 🔗 https://github.com/openclaw/openclaw/issues/41874

---

6. **修复代理流式服务器错误的故障转移 · Pull Request #42562**
- 📅 2026-03-10
- 📝 该拉取请求修复了OpenClaw项目中上游服务器瞬时故障导致流式错误的bug，实现故障转移。
- 🔗 https://github.com/openclaw/openclaw/pull/42562

---

7. **OpenClaw 2026.3.8回归：本地LM Studio后端空代理负载和WebSocket 1006关闭 · Issue #42270**
- 📅 2026-03-10
- 📝 GitHub问题报告了从2026.3.7升级后出现的回归，涉及集成中断和连接关闭。
- 🔗 https://github.com/openclaw/openclaw/issues/42270

---

8. **修复ACP子进程的提供商认证环境变量泄露 · Pull Request #42250**
- 📅 2026-03-10
- 📝 该拉取请求解决了OpenClaw项目中认证环境变量如OPENAI_API_KEY意外泄露到子进程的安全问题。
- 🔗 https://github.com/openclaw/openclaw/pull/42250

---

9. **CLI：停止Windows自更新文件锁定失败 · Pull Request #41994**
- 📅 2026-03-10
- 📝 该拉取请求修复了OpenClaw CLI在Windows上自更新因网关服务文件锁定而失败的特定问题。
- 🔗 https://github.com/openclaw/openclaw/pull/41994

---

10. **修复启动时容忍未知配置键 · Pull Request #42201**
- 📅 2026-03-10
- 📝 该拉取请求解决了OpenClaw项目中openclaw.json未知配置键导致INVALID_CONFIG错误而中止启动的bug。
- 🔗 https://github.com/openclaw/openclaw/pull/42201
