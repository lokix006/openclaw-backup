# 告警归档 Skill

当收到 "归档告警 <alert_id>" 指令时：

1. 调用 GET http://localhost:8000/api/alerts/<alert_id> 获取告警详情
2. 提取 alertname、address、symbol、state、handler、history、starts_at、resolved_at
3. 用如下 prompt 生成总结：

```
你是一个运维经验总结助手。基于以下告警处理记录，生成一份简洁的运维归档报告（中文，200字以内）：

告警名称：{alertname}
合约地址：{address}
币种：{symbol}
告警时间：{starts_at}
处理完成：{resolved_at}
处理人：{handler}
处理过程：{history}

要求：
- 描述告警原因和影响
- 描述处理步骤和结果
- 给出预防建议
```

4. 调用 POST http://localhost:8000/api/alerts/<alert_id>/archive，body: {"summary": "<生成的总结>"}
5. 在 Lark 告警群回复：已归档告警 {alertname}，总结已保存
