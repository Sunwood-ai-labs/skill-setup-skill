[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$scriptsRoot = Join-Path $repoRoot 'scripts'

function Invoke-Checked {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string[]]$ArgumentList,
        [string]$WorkingDirectory,
        [switch]$PassThru
    )

    if ($WorkingDirectory) {
        Push-Location -LiteralPath $WorkingDirectory
    }
    $oldErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & $FilePath @ArgumentList 2>&1
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $oldErrorActionPreference
        if ($WorkingDirectory) {
            Pop-Location
        }
    }

    if ($exitCode -ne 0) {
        $details = (@($output) -join "`n").Trim()
        throw "$FilePath $($ArgumentList -join ' ') failed with exit code $exitCode.`n$details"
    }

    if ($PassThru) {
        return @($output | ForEach-Object { $_.ToString() })
    }
}

function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Test-PowerShellSyntax {
    $parseErrors = @()
    Get-ChildItem -LiteralPath $scriptsRoot -Filter '*.ps1' -File | ForEach-Object {
        $tokens = $null
        $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$tokens, [ref]$errors) | Out-Null
        if ($errors.Count -gt 0) {
            $parseErrors += $errors | ForEach-Object { "$($_.Extent.File):$($_.Extent.StartLineNumber): $($_.Message)" }
        }
    }

    Assert-True -Condition ($parseErrors.Count -eq 0) -Message ("PowerShell parse errors:`n{0}" -f ($parseErrors -join "`n"))
    Write-Output 'PASS syntax: scripts/*.ps1'
}

function New-TestSkillRepository {
    param(
        [Parameter(Mandatory = $true)][string]$SourceRepo,
        [Parameter(Mandatory = $true)][string]$RemoteRepo
    )

    New-Item -ItemType Directory -Path $SourceRepo -Force | Out-Null
    New-Item -ItemType Directory -Path (Split-Path -Parent $RemoteRepo) -Force | Out-Null

    Invoke-Checked -FilePath 'git' -ArgumentList @('init', '--bare', $RemoteRepo)
    Invoke-Checked -FilePath 'git' -ArgumentList @('init') -WorkingDirectory $SourceRepo
    Set-Content -LiteralPath (Join-Path $SourceRepo 'SKILL.md') -Value @'
---
name: alpha-skill
description: Test skill used by the Skill Setup smoke test.
---

# Alpha Skill
'@ -Encoding utf8
    Invoke-Checked -FilePath 'git' -ArgumentList @('add', 'SKILL.md') -WorkingDirectory $SourceRepo
    Invoke-Checked -FilePath 'git' -ArgumentList @('-c', 'user.name=Skill Setup Test', '-c', 'user.email=skill-setup@example.invalid', 'commit', '-m', 'Initial test skill') -WorkingDirectory $SourceRepo
    Invoke-Checked -FilePath 'git' -ArgumentList @('branch', '-M', 'main') -WorkingDirectory $SourceRepo
    Invoke-Checked -FilePath 'git' -ArgumentList @('remote', 'add', 'origin', $RemoteRepo) -WorkingDirectory $SourceRepo
    Invoke-Checked -FilePath 'git' -ArgumentList @('push', '-u', 'origin', 'main') -WorkingDirectory $SourceRepo
}

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("skill-setup-smoke-{0}" -f ([guid]::NewGuid().ToString('N')))

try {
    Test-PowerShellSyntax

    $sourceRepo = Join-Path $tempRoot 'source\alpha-skill'
    $remoteRepo = Join-Path $tempRoot 'remote\alpha-skill.git'
    $sourceSkillsRoot = Join-Path $tempRoot 'source-skills'
    $targetRepoRoot = Join-Path $tempRoot 'target-repos'
    $targetSkillsRoot = Join-Path $tempRoot 'target-skills'
    $badRepoRoot = Join-Path $tempRoot 'bad-target-repos'
    $badSkillsRoot = Join-Path $tempRoot 'bad-target-skills'
    $manifestPath = Join-Path $tempRoot 'codex-skill-set.json'
    $badManifestPath = Join-Path $tempRoot 'bad-codex-skill-set.json'

    New-TestSkillRepository -SourceRepo $sourceRepo -RemoteRepo $remoteRepo
    New-Item -ItemType Directory -Path $sourceSkillsRoot, $targetRepoRoot, $targetSkillsRoot, $badRepoRoot, $badSkillsRoot -Force | Out-Null

    & (Join-Path $scriptsRoot 'Register-SkillJunction.ps1') `
        -SkillName 'alpha-skill' `
        -RepoPath $sourceRepo `
        -SkillsRoot $sourceSkillsRoot | Out-Host

    & (Join-Path $scriptsRoot 'Export-CurrentSkillSet.ps1') `
        -OutputPath $manifestPath `
        -SkillsRoot $sourceSkillsRoot | Out-Host

    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    $skills = @($manifest.skills)
    Assert-True -Condition ($skills.Count -eq 1) -Message 'Expected exactly one exported skill.'
    Assert-True -Condition ($skills[0].skillName -eq 'alpha-skill') -Message 'Exported skillName did not match.'
    Assert-True -Condition ($skills[0].repoUrl -eq $remoteRepo) -Message 'Exported repoUrl did not match the test remote.'

    & (Join-Path $scriptsRoot 'Restore-CurrentSkillSet.ps1') `
        -ManifestPath $manifestPath `
        -RepoRoot $targetRepoRoot `
        -SkillsRoot $targetSkillsRoot | Out-Host

    $registeredPath = Join-Path $targetSkillsRoot 'alpha-skill'
    $registeredItem = Get-Item -LiteralPath $registeredPath -Force
    Assert-True -Condition ($registeredItem.LinkType -eq 'Junction') -Message 'Restored skill path is not a junction.'
    Assert-True -Condition (Test-Path -LiteralPath (Join-Path $registeredPath 'SKILL.md') -PathType Leaf) -Message 'Registered SKILL.md is not readable.'

    $restoredRepo = Join-Path $targetRepoRoot 'alpha-skill'
    $restoredOrigin = (Invoke-Checked -FilePath 'git' -ArgumentList @('remote', 'get-url', 'origin') -WorkingDirectory $restoredRepo -PassThru | Select-Object -First 1).Trim()
    Assert-True -Condition ($restoredOrigin -eq $remoteRepo) -Message 'Restored repo origin did not match manifest repoUrl.'
    Write-Output 'PASS flow: export -> restore -> register'

    $badManifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    $badSkills = @($badManifest.skills)
    $badSkills[0].branch = 'missing-branch'
    $badSkills[0].commit = ''
    $badManifest.skills = $badSkills
    $badManifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $badManifestPath -Encoding utf8

    $failedAsExpected = $false
    try {
        & (Join-Path $scriptsRoot 'Restore-CurrentSkillSet.ps1') `
            -ManifestPath $badManifestPath `
            -RepoRoot $badRepoRoot `
            -SkillsRoot $badSkillsRoot | Out-Host
    } catch {
        $failedAsExpected = $true
        Write-Output "PASS failure handling: $($_.Exception.Message.Split("`n")[0])"
    }

    Assert-True -Condition $failedAsExpected -Message 'Restore succeeded unexpectedly for a missing branch.'
    Assert-True -Condition (-not (Test-Path -LiteralPath (Join-Path $badSkillsRoot 'alpha-skill'))) -Message 'Failed restore should not register a junction.'
} finally {
    if (Test-Path -LiteralPath $tempRoot) {
        $resolvedTempRoot = (Resolve-Path -LiteralPath $tempRoot).ProviderPath
        $systemTempRoot = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
        if ($resolvedTempRoot.StartsWith($systemTempRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            Remove-Item -LiteralPath $resolvedTempRoot -Recurse -Force
        } else {
            Write-Warning "Skipped cleanup because temp root resolved outside the system temp directory: $resolvedTempRoot"
        }
    }
}
