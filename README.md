<p align="center">
  <img src="docs/public/skill-setup-header.png" alt="Skill Setup banner showing Codex skills moving between two Windows PCs">
</p>

<p align="center">
  <strong>Skill Setup</strong><br>
  Export the Codex skills registered on one Windows PC and restore the same git-backed skills on another Windows PC.
</p>

<p align="center">
  <a href="README.ja.md">日本語</a>
  ·
  <a href="https://sunwood-ai-labs.github.io/skill-setup-skill/">Documentation</a>
</p>

<p align="center">
  <a href="https://github.com/Sunwood-ai-labs/skill-setup-skill/actions/workflows/ci.yml"><img alt="CI" src="https://github.com/Sunwood-ai-labs/skill-setup-skill/actions/workflows/ci.yml/badge.svg"></a>
  <a href="https://github.com/Sunwood-ai-labs/skill-setup-skill/actions/workflows/pages.yml"><img alt="Pages" src="https://github.com/Sunwood-ai-labs/skill-setup-skill/actions/workflows/pages.yml/badge.svg"></a>
  <a href="LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-green.svg"></a>
  <img alt="PowerShell" src="https://img.shields.io/badge/PowerShell-5.1%2B-2f6db3.svg">
</p>

## ✨ Overview

`skill-setup` is a Codex skill for moving a registered skill set from one Windows PC to another. It exports the junctions under `%USERPROFILE%\.codex\skills`, records the git-backed source repositories behind them, and restores the same registrations on a target PC.

It is designed for skill directories that are junctions to real git repositories. Uncommitted local edits are detected and recorded, but they are not migrated.

## 🧭 What It Migrates

The exported manifest records one entry per restorable skill:

| Field | Meaning |
| --- | --- |
| `skillName` | Registered name under `%USERPROFILE%\.codex\skills` |
| `repoUrl` | `origin` remote used to clone the skill repository |
| `repoFolder` | Repository folder name under the target repo root |
| `branch` | Source branch at export time |
| `commit` | Exact source commit to restore by default |
| `dirty` | Whether the source repo had uncommitted changes |

Only git-backed skills with a readable `SKILL.md` and an `origin` remote are included.

## ✅ Requirements

- Windows PowerShell 5.1 or PowerShell 7+
- `git` available on `PATH`
- Source skill registrations stored under `%USERPROFILE%\.codex\skills`
- Each restorable skill registered as a junction to a git repo
- Network or filesystem access to every manifest `repoUrl`

No Python runtime is required by the current scripts. If Python helpers are added later, run them through `uv` in this Windows workspace.

## 🚀 Quick Start

Export on the source PC:

```powershell
& "D:\Prj\skill-setup-skill\scripts\Export-CurrentSkillSet.ps1" `
  -OutputPath "D:\Temp\codex-skill-set.json"
```

Move `D:\Temp\codex-skill-set.json` to the target PC, then restore:

```powershell
& "D:\Prj\skill-setup-skill\scripts\Restore-CurrentSkillSet.ps1" `
  -ManifestPath "D:\Temp\codex-skill-set.json" `
  -RepoRoot "D:\Prj"
```

By default, restore checks out the exact exported commit. Add `-UseBranchTip` only when the target PC should use the latest branch tip instead.

## 🛡️ Safety Model

- Existing repositories, skill directories, and junctions are not overwritten.
- Existing repositories must have the same `origin` URL as the manifest.
- Repositories with local changes are refused before checkout changes.
- Checkout, fetch, and clone failures stop the restore before registration.
- Existing junctions are accepted only when they already point at the expected repository.
- Dirty source repos are reported in the manifest, but uncommitted changes are not copied.

## 🧪 Verification

Run the repository smoke test:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\Invoke-SkillSetupSmoke.ps1
```

Build the documentation:

```powershell
npm --prefix docs ci
npm --prefix docs run docs:build
```

The smoke test creates isolated temporary repositories and junction roots, then verifies export, restore, registration, and failure handling without touching your real Codex skill directory.

## 📁 Repository Layout

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

## 📚 Documentation

The full guide is available in `docs/` and is published through GitHub Pages when the workflow is enabled for this repository:

- [English guide](docs/guide/export.md)
- [Japanese guide](docs/ja/guide/export.md)

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Keep changes small, verify with the smoke test, and avoid touching real saved Codex registrations in tests.

## 📄 License

MIT License. See [LICENSE](LICENSE).
