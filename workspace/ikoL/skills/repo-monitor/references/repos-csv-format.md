# repos.csv Format Reference

## Schema

```
platform,repo,branch,notify_user_ids
```

| Field | Values | Notes |
|-------|--------|-------|
| platform | `github` or `gitlab` | lowercase |
| repo | `owner/repo-name` | e.g. `moss-site/moss_agent_trade` |
| branch | branch name | e.g. `main`, `test`, `develop` |
| notify_user_ids | Feishu open_id(s) | semicolon-separated for multiple users |

## Examples

Single recipient:
```
github,myorg/myrepo,main,ou_570aeb8842a1cbbc0313861d2b5c128f
```

Multiple recipients:
```
github,myorg/myrepo,main,ou_570aeb8842a1cbbc0313861d2b5c128f;ou_4da47605a07e3c09bb41b6177b2d35ea
```

GitLab with custom instance:
```
gitlab,mygroup/myproject,develop,ou_570aeb8842a1cbbc0313861d2b5c128f
```

## Notes

- Each row = one repo:branch combination to monitor
- Same repo can appear multiple times for different branches
- GITLAB_BASE_URL in .env controls GitLab instance (default: https://gitlab.com)
- Feishu user IDs start with `ou_`
