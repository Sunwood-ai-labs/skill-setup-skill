# Safety and Failure Behavior

Skill Setup is intentionally conservative because it works with saved registrations and local repositories.

## Refused States

Restore stops when:

- a target repo path exists but is not a git repository
- a target repo has a different `origin` remote than the manifest
- a target repo has local changes
- `git clone`, `git fetch`, or `git checkout` fails
- the restored repo does not contain `SKILL.md`
- the registration path exists but is not a junction
- an existing junction points somewhere other than the expected repo

## Uncommitted Changes

The manifest records whether the source repository was dirty, but restore only clones committed repository content. Commit and push work that must appear on the target PC.

## Testing Without Touching Real Skills

Use the smoke test for isolated verification:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\Invoke-SkillSetupSmoke.ps1
```

The test uses temporary repositories and temporary skill roots, then removes them after completion.
