📡 **OpenClaw 技术简报** | 2026-03-11
---
1. **修复自动续订OAuth配置文件的过期显示** (PR #43122)
   - 📅 2026-03-11
   - 📝 该拉取请求修复了OpenClaw项目中OAuth配置文件过期显示的bug，此前系统错误显示了过期的过期信息。
   - 🔗 https://github.com/openclaw/openclaw/pull/43122
---
2. **修复Mattermost多工具调用响应中的独立流式传输** (PR #43041)
   - 📅 2026-03-11
   - 📝 该拉取请求解决了OpenClaw项目中Mattermost集成的问题，多轮响应涉及工具调用时无法独立流式传输。
   - 🔗 https://github.com/openclaw/openclaw/pull/43041
---
3. **OpenClaw模型状态探测命令在2026.3.8版本超时**
   - 📅 2026-03-10
   - 📝 该GitHub问题报告了`openclaw models status --probe`命令在2026.3.8版本上的超时问题，用户遇到约8.4秒的请求超时。
   - 🔗 https://github.com/openclaw/openclaw/issues/41874
---
4. **Cron“立即运行”按钮失效，任务虽入队但不执行**
   - 📅 2026-03-10
   - 📝 该GitHub问题报告了OpenClaw 2026.3.8版本的回归bug，点击cron作业的“Run Now”按钮（sessionTarget: isolated）后任务不执行。
   - 🔗 https://github.com/openclaw/openclaw/issues/41979
---
5. **Cron通道积压：作业因卡住运行而排队等待，导致调度器饥饿**
   - 📅 2026-03-10
   - 📝 该GitHub问题报告了OpenClaw 2026.3.8版本的回归bug，cron作业从“running”转为“idle”后导致通道积压，作业等待60分钟以上。
   - 🔗 https://github.com/openclaw/openclaw/issues/42097
---
6. **修复ACP子进程中的提供商认证环境变量泄露** (PR #42250)
   - 📅 2026-03-10
   - 📝 该拉取请求解决了安全问题，提供商认证环境变量（如OPENAI_API_KEY、GITHUB_TOKEN、HF_TOKEN）可能在ACP子进程中意外泄露。
   - 🔗 https://github.com/openclaw/openclaw/pull/42250
---
7. **OpenClaw 2026.3.8回归：本地LM Studio后端空代理负载和WebSocket 1006关闭**
   - 📅 2026-03-10
   - 📝 该GitHub问题报告了从2026.3.7升级到2026.3.8后的回归问题，导致本地LM Studio后端间歇性失败，包括空代理负载和WebSocket 1006关闭。
   - 🔗 https://github.com/openclaw/openclaw/issues/42270
---
8. **CLI：停止Windows自更新文件锁定失败** (PR #41994)
   - 📅 2026-03-10
   - 📝 该拉取请求解决了Windows特定问题，`openclaw update`命令因网关服务活跃期间的文件锁定冲突而失败。
   - 🔗 https://github.com/openclaw/openclaw/pull/41994
---
9. **CLI备份创建命令卡住，仅生成10字节临时文件**
   - 📅 2026-03-10
   - 📝 该GitHub问题描述了OpenClaw中`backup create`命令的bug，该命令卡住，仅创建10字节临时文件而无法完成备份。
   - 🔗 https://github.com/openclaw/openclaw/issues/41830
---
10. **修复sessions_spawn继承目标代理工作区而非请求者工作区** (PR #42395)
    - 📅 2026-03-10
    - 📝 该拉取请求修复了OpenClaw项目中`sessions_spawn`函数的bug，子代理错误继承了调用者工作区而非目标代理工作区。
    - 🔗 https://github.com/openclaw/openclaw/pull/42395
