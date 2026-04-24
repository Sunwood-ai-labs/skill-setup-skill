# Safety and Failure Behavior

Skill Setup は保存済み registration と local repo を扱うため、意図的に保守的に動きます。

## 拒否される状態

restore は次の場合に停止します。

- target repo path が存在するが git repo ではない
- target repo の `origin` remote が manifest と違う
- target repo に local changes がある
- `git clone`、`git fetch`、`git checkout` が失敗した
- restored repo に `SKILL.md` がない
- registration path が存在するが junction ではない
- 既存 junction が期待する repo 以外を指している

## 未コミット変更

manifest は source repo の dirty 状態を記録しますが、restore が clone するのは committed repository content だけです。target PC に必要な作業は commit / push してください。

## 実登録に触れない Test

isolated な確認には smoke test を使います。

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\Invoke-SkillSetupSmoke.ps1
```

test は一時 repo と一時 skill root を使い、完了後に削除します。
