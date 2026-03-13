📡 **OpenClaw 技术简报** | 2026-03-12

1. **修复OAuth自动续订配置文件的过期显示问题 · PR #43122**
- 📅 2026-03-11
- 📝 该拉取请求修复了openclaw项目中OAuth配置文件过期显示的bug，之前系统错误显示了过期的过期信息。
- 🔗 https://github.com/openclaw/openclaw/pull/43122

---

2. **更新至2026.3.8后Cron作业中断 · Issue #42883**
- 📅 2026-03-11
- 📝 openclaw仓库报告2026.3.8更新引入的回归bug，导致Cron作业无法按预期执行，用户升级后未修改配置即出现问题。
- 🔗 https://github.com/openclaw/openclaw/issues/42883

---

3. **修复Mattermost多工具调用响应的独立流式传输 · PR #43041**
- 📅 2026-03-11
- 📝 该拉取请求解决了openclaw项目中Mattermost集成的问题，多轮响应涉及工具调用时无法独立流式传输。
- 🔗 https://github.com/openclaw/openclaw/pull/43041

---

4. **OpenClaw 2026.3.8回归：本地LM Studio后端空代理负载与WebSocket 1006关闭 · Issue #42270**
- 📅 2026-03-10
- 📝 GitHub问题报告OpenClaw 2026.3.8版本从2026.3.7升级后的回归，涉及与本地LM Studio后端的交互问题，包括空代理负载和WebSocket异常关闭。
- 🔗 https://github.com/openclaw/openclaw/issues/42270

---

5. **CLI：停止Windows自更新文件锁定失败 · PR #41994**
- 📅 2026-03-10
- 📝 该拉取请求修复了openclaw CLI在Windows上的特定问题，自更新因文件锁定冲突失败，尤其在全局安装期间openclaw.exe被锁定。
- 🔗 https://github.com/openclaw/openclaw/pull/41994

---

6. **Bug：`openclaw backup create` 命令卡住，仅生成10字节.tmp文件未完成 · Issue #41830**
- 📅 2026-03-10
- 📝 GitHub问题报告openclaw中backup create命令卡住，仅创建10字节临时文件而无法完成备份过程。
- 🔗 https://github.com/openclaw/openclaw/issues/41830

---

7. **修复sessions_spawn：继承目标代理工作区而非请求者工作区 · PR #42395**
- 📅 2026-03-10
- 📝 该拉取请求修复了openclaw项目中sessions_spawn函数的bug，子代理错误继承了调用者工作区而非目标代理工作区。
- 🔗 https://github.com/openclaw/openclaw/pull/42395

---

8. **修复：启动时容忍未知配置键 · PR #42201**
- 📅 2026-03-10
- 📝 该拉取请求解决了openclaw项目启动问题，openclaw.json中未知配置键会导致应用以INVALID_CONFIG错误中止，现在已添加容忍机制。
- 🔗 https://github.com/openclaw/openclaw/pull/42201
