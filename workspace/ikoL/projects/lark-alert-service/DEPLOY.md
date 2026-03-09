# 部署指南

## 1. 准备环境配置

```bash
cp .env.example .env
```

编辑 `.env`，填入以下值（已预填）：

```
LARK_APP_ID=cli_a90a158106f8deef
LARK_APP_SECRET=RZqdgczHanckP9MARZwhZbPhWeRqjD3x
ALERT_GROUP_ID=oc_7389004c552f107cad37e64eb15bccb2
LARK_VERIFICATION_TOKEN=   # 从 Lark 开放平台 → 事件订阅 → 验证 token 复制
```

## 2. 配置 Lark 开放平台

登录 https://open.larksuite.com/app ，找到应用 `cli_a90a158106f8deef`：

### 开通能力
- 「消息与群组」→ 开启「发送消息」「更新消息」权限
- 「事件订阅」→ 启用，设置 Request URL 为：`https://<你的服务器IP>:8000/lark-callback`
- 订阅事件：`card.action.trigger`（卡片按钮点击）

### 将 Bot 拉入告警群
在 Lark 中，将应用 Bot 添加到告警群 `oc_7389004c552f107cad37e64eb15bccb2`

## 3. 配置 Grafana

Grafana → Alerting → Contact Points → 编辑现有 Webhook 或新建：

- URL：`https://<你的服务器IP>:8000/grafana-webhook`
- Method: POST
- 无需额外 Header

## 4. 启动服务

```bash
docker-compose up -d
```

验证：
```bash
curl http://localhost:8000/health
# → {"status":"ok"}
```

## 5. 测试 Webhook

```bash
curl -X POST http://localhost:8000/grafana-webhook \
  -H "Content-Type: application/json" \
  -d @test_alert.json
```

test_alert.json 使用真实 Grafana JSON 样本即可。

## 6. OpenClaw 归档集成

当告警状态变为 `resolved` 或 `ignored` 时，在 Lark 群 @Bot：

```
@ikoL 归档告警 <alert_id>
```

Bot 会自动：
1. 拉取处理历史
2. LLM 生成总结
3. 写入数据库
4. 在群内回复归档结果

## API 接口

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /grafana-webhook | Grafana 推送入口 |
| POST | /lark-callback | Lark 事件回调 |
| GET  | /api/alerts | 查询所有告警 |
| GET  | /api/alerts/{id} | 查询单条告警 |
| POST | /api/alerts/{id}/archive | 写入归档总结 |
| GET  | /health | 健康检查 |
