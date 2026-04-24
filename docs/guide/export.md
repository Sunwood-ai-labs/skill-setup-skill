# Export From the Source PC

Export captures the Codex skill registrations that can be restored on another Windows PC.

## Prerequisites

- The source PC has Codex skills registered under `%USERPROFILE%\.codex\skills`.
- Restorable skills are junctions to git repositories.
- Each source repository has a readable `SKILL.md` and an `origin` remote.

## Command

Run from PowerShell:

```powershell
& "D:\Prj\skill-setup-skill\scripts\Export-CurrentSkillSet.ps1" `
  -OutputPath "D:\Temp\codex-skill-set.json"
```

Use `-SkillsRoot` only when the source registration root is not `%USERPROFILE%\.codex\skills`.

```powershell
& "D:\Prj\skill-setup-skill\scripts\Export-CurrentSkillSet.ps1" `
  -OutputPath "D:\Temp\codex-skill-set.json" `
  -SkillsRoot "C:\Users\Aslan\.codex\skills"
```

## What Gets Skipped

The exporter skips entries that are not junctions, do not point to a git repository, do not contain `SKILL.md`, or do not have an `origin` remote. Warnings explain each skipped item.

## Dirty Repositories

If a source repository has uncommitted changes, the manifest records `"dirty": true`. Those changes are not copied to the target PC. Commit or push important local edits before relying on the restore.

## Next Step

Move the generated JSON manifest to the target PC, then follow [Restore on the Target PC](./restore.md).
