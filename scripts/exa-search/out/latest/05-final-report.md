📡 **OpenClaw 技术简报** | 2026-03-13

1. **feat(tts)：添加 CLI 提供商支持（PR #43939）**
- 📅 2026-03-12
- 📝 该拉取请求为 openclaw 项目引入文本到语音（TTS）的 CLI 提供商支持，解决了用户仅依赖云服务的限制。
- 🔗 https://github.com/openclaw/openclaw/pull/43939

---

2. **Cron 隔离会话作业在 2026.3.11 版本中仍失败（Issue #44257）**
- 📅 2026-03-12
- 📝 GitHub 问题报告 openclaw 2026.3.11 版本中引入的回归，配置为 sessionTarget: 'isolated' 的 cron 作业虽被入队但从未执行。
- 🔗 https://github.com/openclaw/openclaw/issues/44257

---

3. **编辑工具静默将文件清空为 0 字节却报告成功（Issue #43858）**
- 📅 2026-03-12
- 📝 GitHub 问题报告 openclaw 项目中 Edit 工具意外删除文件全部内容至 0 字节，尽管匹配路径正确。
- 🔗 https://github.com/openclaw/openclaw/issues/43858

---

4. **隔离 Cron 作业会话使用 kimi-coding/k2p5 模型无法使用工具（Issue #44269）**
- 📅 2026-03-12
- 📝 GitHub 问题报告 openclaw 2026.3.2 版本中引入的回归，使用 kimi-coding/k2p5 模型的隔离 cron 作业会话无法使用工具。
- 🔗 https://github.com/openclaw/openclaw/issues/44269

---

5. **运行时：默认使用 Node v24 (LTS) 并保持 Node v22.16+ 兼容（PR #44016）**
- 📅 2026-03-12
- 📝 该拉取请求更新 openclaw 仓库的默认运行时环境至 Node.js v24 (LTS)，同时确保与 Node v22.16+ 的兼容性。
- 🔗 https://github.com/openclaw/openclaw/pull/44016

---

6. **macOS 版本发布 - OpenClaw**
- 📅 2026-03-11
- 📝 网页文档介绍 OpenClaw 的 macOS 版本发布，聚焦基于 Sparkle 的自动更新系统，包括 SwiftPM 获取工具、pnpm 安装依赖和公证设置等前提条件。
- 🔗 https://docs.openclaw.ai/platforms/mac/release

---

7. **fix(auth)：清除自动续订 OAuth 配置文件中的过期显示（PR #43122）**
- 📅 2026-03-11
- 📝 该拉取请求修复 OpenClaw 项目中 OAuth 配置文件过期显示的 bug，此前系统错误显示过时过期信息。
- 🔗 https://github.com/openclaw/openclaw/pull/43122

---

8. **feat(push)：添加 iOS APNs 中继网关（PR #43369）**
- 📅 2026-03-11
- 📝 该拉取请求为 openclaw 项目添加 iOS APNs 中继网关，提升推送通知系统通过中继支持的 APNs 请求。
- 🔗 https://github.com/openclaw/openclaw/pull/43369

---

9. **企业微信 openclaw 插件版本规则发布错误 - V2EX**
- 📅 2026-03-11
- 📝 网页讨论企业微信中 openclaw 插件的版本规则问题，用户指出预发布版本（1.0.7-beta.1）因 npm 要求未默认安装。
- 🔗 https://www.v2ex.com/t/1197469
