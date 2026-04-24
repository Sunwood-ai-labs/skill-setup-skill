# Manifest Format

The export manifest uses the `codex-skill-set/v1` schema.

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

## Required Fields

Restore requires every entry to include:

- `skillName`
- `repoUrl`

When `repoFolder` is missing, restore defaults to `<skillName>-skill`.

## Optional Fields

- `branch` is used to recreate or select the branch before checkout.
- `commit` is checked out unless `-UseBranchTip` is passed.
- `dirty` is informational and warns that local uncommitted changes existed on the source PC.

## Validation

`skillName` must use lowercase letters, numbers, and dashes. `repoFolder` must be a folder name, not a path.
