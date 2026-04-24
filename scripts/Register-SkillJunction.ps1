[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({
        if ($_ -cnotmatch '^[a-z0-9][a-z0-9-]*[a-z0-9]$') {
            throw "Use lowercase letters, numbers, and dashes."
        }
        return $true
    })]
    [string]$SkillName,

    [Parameter(Mandatory = $true)]
    [string]$RepoPath,

    [string]$SkillsRoot = (Join-Path $HOME '.codex\skills')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-ExistingPath {
    param([Parameter(Mandatory = $true)][string]$Path)
    return (Resolve-Path -LiteralPath $Path -ErrorAction Stop).ProviderPath
}

function Resolve-TargetPath {
    param([Parameter(Mandatory = $true)][string]$Path)
    return $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
}

$repoFullPath = Resolve-ExistingPath -Path $RepoPath
$skillFile = Join-Path $repoFullPath 'SKILL.md'
if (-not (Test-Path -LiteralPath $skillFile -PathType Leaf)) {
    throw "Repo path does not contain SKILL.md: $skillFile"
}

if (-not (Test-Path -LiteralPath $SkillsRoot -PathType Container)) {
    New-Item -ItemType Directory -Path $SkillsRoot | Out-Null
}

$skillsRootFullPath = Resolve-ExistingPath -Path $SkillsRoot
$linkPath = Join-Path $skillsRootFullPath $SkillName

if (Test-Path -LiteralPath $linkPath) {
    $existing = Get-Item -LiteralPath $linkPath -Force
    if ($existing.LinkType -ne 'Junction') {
        throw "Registration path exists and is not a junction: $linkPath"
    }

    $targets = @($existing.Target)
    if ($targets.Count -ne 1) {
        throw "Existing junction has an unexpected target list: $linkPath"
    }

    $existingTarget = Resolve-ExistingPath -Path $targets[0]
    if ($existingTarget -ne $repoFullPath) {
        throw "Existing junction points to '$existingTarget', not '$repoFullPath'."
    }

    Write-Output "Already registered: $linkPath -> $repoFullPath"
} else {
    $unresolvedLinkPath = Resolve-TargetPath -Path $linkPath
    New-Item -ItemType Junction -Path $unresolvedLinkPath -Target $repoFullPath | Out-Null
    Write-Output "Created junction: $unresolvedLinkPath -> $repoFullPath"
}

$registered = Get-Item -LiteralPath $linkPath -Force
if ($registered.LinkType -ne 'Junction') {
    throw "Verification failed: registration path is not a junction: $linkPath"
}

$registeredSkillFile = Join-Path $linkPath 'SKILL.md'
if (-not (Test-Path -LiteralPath $registeredSkillFile -PathType Leaf)) {
    throw "Verification failed: registered SKILL.md is not readable: $registeredSkillFile"
}

Write-Output "Verified: $linkPath"
