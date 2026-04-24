# Target PC で Restore

restore は、足りない skill repo を clone し、export 時点の revision を checkout して、target user の Codex skills directory に junction を登録します。

## コマンド

PowerShell で実行します。

```powershell
& "D:\Prj\skill-setup-skill\scripts\Restore-CurrentSkillSet.ps1" `
  -ManifestPath "D:\Temp\codex-skill-set.json" `
  -RepoRoot "D:\Prj"
```

`%USERPROFILE%\.codex\skills` 以外へ登録する場合だけ `-SkillsRoot` を指定します。

```powershell
& "D:\Prj\skill-setup-skill\scripts\Restore-CurrentSkillSet.ps1" `
  -ManifestPath "D:\Temp\codex-skill-set.json" `
  -RepoRoot "D:\Prj" `
  -SkillsRoot "C:\Users\Aslan\.codex\skills"
```

## Commit と Branch Tip

既定では、export された正確な `commit` を checkout します。これにより target PC は source PC と同じ committed state になります。

target PC で export branch の最新 tip を使いたい場合だけ `-UseBranchTip` を指定します。

```powershell
& "D:\Prj\skill-setup-skill\scripts\Restore-CurrentSkillSet.ps1" `
  -ManifestPath "D:\Temp\codex-skill-set.json" `
  -RepoRoot "D:\Prj" `
  -UseBranchTip
```

## 既存 Repo

target repo folder がすでに存在する場合、restore は git repo であることと `origin` remote が manifest と一致することを確認します。local changes がある repo は checkout 変更前に拒否されます。

## Registration

各 skill は `Register-SkillJunction.ps1` で登録されます。既存 junction は、期待する repo を指している場合だけ再利用されます。
