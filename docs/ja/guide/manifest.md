# Manifest Format

export manifest は `codex-skill-set/v1` schema を使います。

```json
{
  "schema": "codex-skill-set/v1",
  "exportedAt": "2026-04-24T00:00:00.0000000Z",
  "sourceComputer": "SOURCE-PC",
  "skillsRoot": "C:\\Users\\Aslan\\.codex\\skills",
  "skills": [
    {
      "skillName": "skill-setup",
      "repoUrl": "https://github.com/Sunwood-ai-labs/skill-setup-skill.git",
      "branch": "main",
      "commit": "0123456789abcdef0123456789abcdef01234567",
      "repoFolder": "skill-setup-skill",
      "dirty": false
    }
  ]
}
```

## 必須フィールド

restore は各 entry に次の field を要求します。

- `skillName`
- `repoUrl`

`repoFolder` がない場合、restore は `<skillName>-skill` を既定値として使います。

## 任意フィールド

- `branch` は checkout 前に branch を選択または作成するために使われます。
- `commit` は `-UseBranchTip` が指定されない限り checkout されます。
- `dirty` は source PC に未コミット変更があったことを示す情報です。

## Validation

`skillName` は lowercase letters、numbers、dashes のみです。`repoFolder` は path ではなく folder name である必要があります。
