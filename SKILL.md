---
name: skill-setup
description: Export the currently registered Codex skill set from one Windows PC and restore the same public git-backed skills on another PC by cloning repos and re-creating %USERPROFILE%\.codex\skills junctions.
---

# Skill Setup

Use this skill when the user wants to move the skill set currently registered on this PC to another Windows PC.

The unit of migration is the registered skill set in `%USERPROFILE%\.codex\skills`. For each registered junction, the export records the skill name, git origin URL, repo folder name, branch, commit, and whether the source repo has uncommitted changes.

## Core Rules

- Read the workspace `README*`, `AGENTS.md`, and any user-provided spec before creating or changing a skill.
- Fix the source skill root, target repo root, and target skill root up front. Defaults are `%USERPROFILE%\.codex\skills`, `D:\Prj`, and `%USERPROFILE%\.codex\skills`.
- Do not overwrite an existing repo, skill directory, junction, or saved config unless the user explicitly asks for replacement.
- Use `uv` for Python commands in Windows workspaces that require it.
- Restore only git-backed skills with an `origin` remote and a readable `SKILL.md`.
- Do not claim uncommitted local changes are migrated. The manifest records dirty state, but only committed repository content is restored.
- Do not store dummy values, placeholder API keys, or test-only settings in persistent files.

## Workflow

1. On the current/source PC, export the registered skill set:
   - Inspect `%USERPROFILE%\.codex\skills`.
   - Include only junctions pointing to git repos that have `SKILL.md` and an `origin` remote.
   - Run `scripts/Export-CurrentSkillSet.ps1`.
2. Move the manifest to the target PC:
   - Treat the manifest as the list of skills to restore.
   - Each entry must have `skillName` and `repoUrl`.
3. On the target PC, restore the same skill set:
   - Run `scripts/Restore-CurrentSkillSet.ps1`.
   - Clone missing repos under `D:\Prj` by default.
   - Check out the exported commit by default, so the target matches the source repo state.
   - Re-create `%USERPROFILE%\.codex\skills\<skill-name>` junctions with `scripts/Register-SkillJunction.ps1`.
4. Validate the restored set:
   - Confirm each registered path is a junction.
   - Confirm each registered path can read `SKILL.md`.
   - Confirm each local repo has the manifest `origin` URL.
   - Confirm failed clone, fetch, or checkout operations stop before junction registration.

## Source PC: Export Current Skill Set

Run from PowerShell:

```powershell
& "<this-skill-repo>\scripts\Export-CurrentSkillSet.ps1" `
  -OutputPath "D:\Temp\codex-skill-set.json"
```

## Target PC: Restore Current Skill Set

Run from PowerShell:

```powershell
& "<this-skill-repo>\scripts\Restore-CurrentSkillSet.ps1" `
  -ManifestPath "D:\Temp\codex-skill-set.json" `
  -RepoRoot "D:\Prj"
```

The restore script clones missing repositories, checks out the exported commit by default, and registers `%USERPROFILE%\.codex\skills\<skill-name>` junctions. Use `-UseBranchTip` only when the target PC should use the latest branch tip instead of the exported commit.

## Final Report

Report only what was actually checked:

- `confirmed prerequisites`: files and constraints read.
- `changes`: files created or edited, repos cloned, commits checked out, junctions created or reused.
- `verification`: commands run and their result.
- `unverified`: anything not checked and why.
- `dangerous changes`: persistent config or registration paths touched, including recovery notes.

## Repository Verification

When maintaining this skill repository, use the isolated smoke test before reporting script behavior as verified:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\Invoke-SkillSetupSmoke.ps1
```

The test uses temporary repositories and temporary skill roots. It must not touch the real `%USERPROFILE%\.codex\skills` registration root.
