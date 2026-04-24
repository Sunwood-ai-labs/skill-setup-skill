# Source PC から Export

export は、別の Windows PC で復元できる Codex skill 登録を manifest に保存します。

## 前提条件

- source PC の Codex skill が `%USERPROFILE%\.codex\skills` に登録されていること。
- 復元対象の skill が git repo への junction であること。
- 各 source repo が `SKILL.md` と `origin` remote を持っていること。

## コマンド

PowerShell で実行します。

```powershell
& "D:\Prj\skill-setup-skill\scripts\Export-CurrentSkillSet.ps1" `
  -OutputPath "D:\Temp\codex-skill-set.json"
```

source 登録 root が `%USERPROFILE%\.codex\skills` ではない場合だけ `-SkillsRoot` を指定します。

```powershell
& "D:\Prj\skill-setup-skill\scripts\Export-CurrentSkillSet.ps1" `
  -OutputPath "D:\Temp\codex-skill-set.json" `
  -SkillsRoot "C:\Users\Aslan\.codex\skills"
```

## Skip されるもの

junction ではない entry、git repo を指していない entry、`SKILL.md` がない repo、`origin` remote がない repo は skip されます。理由は warning に出ます。

## Dirty Repo

source repo に未コミット変更がある場合、manifest には `"dirty": true` が記録されます。その差分自体は target PC にコピーされません。必要な変更は restore 前に commit / push してください。

## 次のステップ

生成された JSON manifest を target PC に移し、[Target PC で Restore](./restore.md) に進みます。
