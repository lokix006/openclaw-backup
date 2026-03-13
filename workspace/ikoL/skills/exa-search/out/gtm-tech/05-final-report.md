📡 **OpenClaw 技术简报** | 2026-03-12

1. **修复(auth)：清除自动续订OAuth配置文件的过期显示 · Pull Request #43122**
- 📅 2026-03-11
- 📝 该拉取请求解决了OpenClaw项目中自动续订OAuth配置文件显示过期信息的错误问题。
- 🔗 https://github.com/openclaw/openclaw/pull/43122

---

2. **修复(mattermost)：多工具调用响应中独立流式传输每个回合 · Pull Request #43041**
- 📅 2026-03-11
- 📝 该拉取请求修复了OpenClaw项目中Mattermost集成下多回合工具调用响应无法独立流式传输的问题。
- 🔗 https://github.com/openclaw/openclaw/pull/43041

---

3. **feat(memory)：添加gemini-embedding-2-preview支持 · Pull Request #42501**
- 📅 2026-03-10
- 📝 该拉取请求在OpenClaw仓库中引入了对gemini-embedding-2-preview模型的支持，扩展了嵌入选项。
- 🔗 https://github.com/openclaw/openclaw/pull/42501

---

4. **修复：启动时容忍未知配置键 · Pull Request #42201**
- 📅 2026-03-10
- 📝 该拉取请求解决了OpenClaw项目中openclaw.json中未知配置键导致应用以INVALID_CONFIG错误中止的问题。
- 🔗 https://github.com/openclaw/openclaw/pull/42201

---

5. **修复(acp)：为子ACP进程剥离提供商认证环境变量 · Pull Request #42250**
- 📅 2026-03-10
- 📝 该拉取请求修复了提供商认证环境变量（如OPENAI_API_KEY）在子ACP进程中意外泄露的安全问题。
- 🔗 https://github.com/openclaw/openclaw/pull/42250

---

6. **CLI：停止Windows自更新文件锁定失败 · Pull Request #41994**
- 📅 2026-03-10
- 📝 该拉取请求解决了OpenClaw CLI在Windows上因文件锁定冲突导致自更新失败的问题，特别是网关服务激活时。
- 🔗 https://github.com/openclaw/openclaw/pull/41994

---

7. **原始工具负载泄露到聊天；提供商错误后回退不可靠 · Issue #42469**
- 📅 2026-03-10
- 📝 该GitHub问题报告了OpenClaw项目中的回归问题，其中内部工具负载泄露到Control UI的用户可见聊天消息中。
- 🔗 https://github.com/openclaw/openclaw/issues/42469

---

8. **[BUG 2026.3.8] Cron通道积压：作业在卡住运行后排队（queueAhead=5，等待60m+）导致调度器饥饿 · Issue #42097**
- 📅 2026-03-10
- 📝 该GitHub问题报告了OpenClaw 2026.3.8版本中的回归bug，其中cron作业从运行状态过渡后导致通道积压和调度器饥饿。
- 🔗 https://github.com/openclaw/openclaw/issues/42097

---

9. **[Bug]：Cron 'Run Now' 按钮无效 - 尽管enqueued: true，任务从未执行 · Issue #41979**
- 📅 2026-03-10
- 📝 该GitHub问题详细描述了OpenClaw 2026.3.8版本中Cron作业（sessionTarget: isolated）的'Run Now'按钮回归bug。
- 🔗 https://github.com/openclaw/openclaw/issues/41979

---

10. **openclaw models status --probe 在2026.3.8上返回LLM请求超时 · Issue #41874**
- 📅 2026-03-10
- 📝 该GitHub问题报告了版本2026.3.8中openclaw models status --probe命令的超时问题，用户遇到约8.4秒的请求超时。
- 🔗 https://github.com/openclaw/openclaw/issues/41874
