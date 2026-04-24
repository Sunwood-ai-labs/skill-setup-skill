# Restore on the Target PC

Restore clones missing skill repositories, checks out the exported revision, and registers junctions under the target user's Codex skills directory.

## Command

Run from PowerShell:

```powershell
& "D:\Prj\skill-setup-skill\scripts\Restore-CurrentSkillSet.ps1" `
  -ManifestPath "D:\Temp\codex-skill-set.json" `
  -RepoRoot "D:\Prj"
```

Use `-SkillsRoot` only when registering skills somewhere other than `%USERPROFILE%\.codex\skills`.

```powershell
& "D:\Prj\skill-setup-skill\scripts\Restore-CurrentSkillSet.ps1" `
  -ManifestPath "D:\Temp\codex-skill-set.json" `
  -RepoRoot "D:\Prj" `
  -SkillsRoot "C:\Users\Aslan\.codex\skills"
```

## Commit vs Branch Tip

By default, restore checks out the exact exported `commit`. This gives the target PC the same committed source state as the source PC.

Use `-UseBranchTip` only when the target PC should stay on the exported branch tip:

```powershell
& "D:\Prj\skill-setup-skill\scripts\Restore-CurrentSkillSet.ps1" `
  -ManifestPath "D:\Temp\codex-skill-set.json" `
  -RepoRoot "D:\Prj" `
  -UseBranchTip
```

## Existing Repositories

If the target repo folder already exists, restore verifies that it is a git repository and that its `origin` remote matches the manifest. It refuses to change checkout when local changes are present.

## Registration

Each skill is registered by calling `Register-SkillJunction.ps1`. Existing junctions are reused only when they already point at the expected repository.
