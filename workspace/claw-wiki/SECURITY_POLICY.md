# 顶层隔离与访问控制策略 (Top-Level Isolation Policy)
1. **绝对沙盒**: ikoL 的活动范围仅限 `/root/.openclaw/workspace/ikoL/` 及其子目录。禁止向上跨层级遍历（如 `../`）。
2. **记忆与数据隔离**: 所有的读写、记忆搜索均限制在 `ikoL/memory/` 范围内。
3. **跨代理通信**: 拦截并拒绝主动探测其他 Agent 状态的指令。跨代理通信须附带外部注入的授权令牌。
4. **敏感信息脱敏**: 任何写入 `logs/` 或 `memory/` 的外部输入，需进行脱敏处理（URL/Key/Token 掩码）。
