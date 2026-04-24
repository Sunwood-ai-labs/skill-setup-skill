<p align="center">
  <img src="docs/public/skill-setup-header.png" alt="2台のWindows PC間でCodexスキルを移行するSkill Setupのヘッダー画像" width="1983" height="793">
</p>

<p align="center">
  <strong>Skill Setup</strong><br>
  ある Windows PC に登録済みの Codex スキルセットを、別の Windows PC に同じ git-backed 構成で復元するためのスキルです。
</p>

<p align="center">
  <a href="README.md">English</a>
  ·
  <a href="https://sunwood-ai-labs.github.io/skill-setup-skill/ja/">ドキュメント</a>
</p>

<p align="center">
  <a href="https://github.com/Sunwood-ai-labs/skill-setup-skill/actions/workflows/ci.yml"><img alt="CI" src="https://github.com/Sunwood-ai-labs/skill-setup-skill/actions/workflows/ci.yml/badge.svg"></a>
  <a href="https://github.com/Sunwood-ai-labs/skill-setup-skill/actions/workflows/pages.yml"><img alt="Pages" src="https://github.com/Sunwood-ai-labs/skill-setup-skill/actions/workflows/pages.yml/badge.svg"></a>
  <a href="LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-green.svg"></a>
  <img alt="PowerShell" src="https://img.shields.io/badge/PowerShell-5.1%2B-2f6db3.svg">
</p>

## ✨ 概要

`skill-setup` は、Windows PC 間で Codex の登録済みスキルセットを移行するための Codex スキルです。`%USERPROFILE%\.codex\skills` 配下の junction を調べ、その参照先 git リポジトリを manifest に記録し、ターゲット PC で同じ登録状態を復元します。

対象は、実体が git リポジトリであり、`SKILL.md` を読めるスキルです。未コミット変更の有無は manifest に記録しますが、未コミット差分そのものは移行しません。

## 🧭 移行されるもの

manifest には、復元可能なスキルごとに次の情報が入ります。

| フィールド | 意味 |
| --- | --- |
| `skillName` | `%USERPROFILE%\.codex\skills` 配下の登録名 |
| `repoUrl` | clone に使う `origin` remote |
| `repoFolder` | ターゲットの repo root 配下に作るリポジトリフォルダ名 |
| `branch` | export 時点のブランチ |
| `commit` | 既定で復元する正確なコミット |
| `dirty` | export 元リポジトリに未コミット変更があったか |

含まれるのは、junction で登録され、`SKILL.md` と `origin` remote を持つ git-backed スキルだけです。

## ✅ 要件

- Windows PowerShell 5.1 または PowerShell 7+
- `git` が `PATH` から実行できること
- source PC のスキル登録が `%USERPROFILE%\.codex\skills` にあること
- 復元対象スキルが git repo への junction として登録されていること
- manifest 内の各 `repoUrl` にアクセスできること

現在のスクリプトは Python を必要としません。将来 Python ヘルパーを追加する場合、この Windows workspace では `uv` 経由で実行してください。

## 🚀 クイックスタート

source PC で export します。

```powershell
& "D:\Prj\skill-setup-skill\scripts\Export-CurrentSkillSet.ps1" `
  -OutputPath "D:\Temp\codex-skill-set.json"
```

`D:\Temp\codex-skill-set.json` を target PC に移し、restore します。

```powershell
& "D:\Prj\skill-setup-skill\scripts\Restore-CurrentSkillSet.ps1" `
  -ManifestPath "D:\Temp\codex-skill-set.json" `
  -RepoRoot "D:\Prj"
```

既定では export 時点の正確な commit を checkout します。最新 branch tip を使いたい場合だけ `-UseBranchTip` を付けます。

## 🛡️ 安全設計

- 既存の repo、skill directory、junction は上書きしません。
- 既存 repo は manifest と同じ `origin` URL でなければ停止します。
- local changes がある repo は checkout 変更前に拒否します。
- clone、fetch、checkout の失敗時は登録前に停止します。
- 既存 junction は期待する repo を指している場合だけ再利用します。
- source repo の dirty 状態は記録しますが、未コミット差分はコピーしません。

## 🧪 検証

リポジトリの smoke test を実行します。

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\Invoke-SkillSetupSmoke.ps1
```

ドキュメントを build します。

```powershell
npm --prefix docs ci
npm --prefix docs run docs:build
```

smoke test は一時ディレクトリ内に repo と junction root を作り、実際の Codex スキル登録には触れずに export、restore、registration、失敗時停止を検証します。

## 📁 リポジトリ構成

```text
.
├── agents/
│   └── openai.yaml
├── docs/
│   ├── .vitepress/
│   ├── guide/
│   └── ja/
├── scripts/
│   ├── Export-CurrentSkillSet.ps1
│   ├── Register-SkillJunction.ps1
│   └── Restore-CurrentSkillSet.ps1
├── tests/
│   └── Invoke-SkillSetupSmoke.ps1
└── SKILL.md
```

## 📚 ドキュメント

詳細ガイドは `docs/` にあります。GitHub Pages が有効な場合、workflow から公開されます。

- [English guide](docs/guide/export.md)
- [日本語ガイド](docs/ja/guide/export.md)

## 🤝 コントリビュート

[CONTRIBUTING.md](CONTRIBUTING.md) を参照してください。変更は小さく保ち、smoke test で検証し、テストで実際の Codex 登録状態に触れないでください。

## 📄 ライセンス

MIT License です。詳細は [LICENSE](LICENSE) を参照してください。
