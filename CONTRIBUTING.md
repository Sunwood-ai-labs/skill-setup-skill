# Contributing

Thanks for helping improve Skill Setup.

## Development Rules

- Keep changes scoped to the export, restore, registration, documentation, or repository maintenance surface.
- Do not write dummy API keys, fake saved config, or test-only settings into persistent user paths.
- Do not use the real `%USERPROFILE%\.codex\skills` directory for tests unless a task explicitly requires it.
- Prefer isolated temporary directories for smoke tests.
- If Python is introduced later, run Python commands through `uv` in this Windows workspace.

## Local Checks

Run the PowerShell smoke test:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\Invoke-SkillSetupSmoke.ps1
```

Build the documentation:

```powershell
npm --prefix docs ci
npm --prefix docs run docs:build
```

## Pull Requests

Before opening a pull request:

- Confirm `git status --short` contains only intentional changes.
- Include the smoke-test result in the pull request body.
- Call out any restore behavior changes, especially checkout or junction-registration behavior.
- Keep generated build output and dependency directories out of the commit.
