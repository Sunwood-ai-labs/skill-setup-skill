[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ManifestPath,

    [string]$RepoRoot = 'D:\Prj',

    [string]$SkillsRoot = (Join-Path $HOME '.codex\skills'),

    [switch]$UseBranchTip
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-ExistingPath {
    param([Parameter(Mandatory = $true)][string]$Path)
    return (Resolve-Path -LiteralPath $Path -ErrorAction Stop).ProviderPath
}

function Resolve-UnresolvedPath {
    param([Parameter(Mandatory = $true)][string]$Path)
    return $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
}

function Assert-SkillName {
    param([Parameter(Mandatory = $true)][string]$SkillName)
    if ($SkillName -cnotmatch '^[a-z0-9][a-z0-9-]*[a-z0-9]$') {
        throw "Invalid skillName '$SkillName'. Use lowercase letters, numbers, and dashes."
    }
}

function Assert-RepoFolder {
    param([Parameter(Mandatory = $true)][string]$RepoFolder)
    if ([System.IO.Path]::GetFileName($RepoFolder) -ne $RepoFolder) {
        throw "Invalid repoFolder '$RepoFolder'. It must be a folder name, not a path."
    }
}

function Invoke-GitQuiet {
    param(
        [Parameter(Mandatory = $true)][string]$RepoPath,
        [Parameter(Mandatory = $true)][string[]]$Arguments
    )

    $oldErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & git -C $RepoPath @Arguments 2>$null
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $oldErrorActionPreference
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        Output = @($output)
    }
}

function Invoke-GitChecked {
    param(
        [string]$RepoPath,
        [Parameter(Mandatory = $true)][string[]]$Arguments
    )

    $commandText = "git $($Arguments -join ' ')"
    $oldErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        if ($RepoPath) {
            $output = & git -C $RepoPath @Arguments 2>&1
        } else {
            $output = & git @Arguments 2>&1
        }
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $oldErrorActionPreference
    }

    if ($exitCode -ne 0) {
        $details = (@($output) -join "`n").Trim()
        if ($details) {
            throw "$commandText failed with exit code $exitCode.`n$details"
        }
        throw "$commandText failed with exit code $exitCode."
    }

    return
}

$manifestFullPath = Resolve-ExistingPath -Path $ManifestPath
$manifestText = Get-Content -LiteralPath $manifestFullPath -Raw
$manifest = $manifestText | ConvertFrom-Json

if ($manifest.PSObject.Properties.Name -contains 'skills') {
    $skillEntries = @($manifest.skills)
} elseif ($manifest -is [System.Collections.IEnumerable]) {
    $skillEntries = @($manifest)
} else {
    throw "Manifest must be a codex-skill-set object or a JSON array."
}

$repoRootFullPath = Resolve-UnresolvedPath -Path $RepoRoot
if (-not (Test-Path -LiteralPath $repoRootFullPath -PathType Container)) {
    New-Item -ItemType Directory -Path $repoRootFullPath -Force | Out-Null
}

$skillsRootFullPath = Resolve-UnresolvedPath -Path $SkillsRoot
if (-not (Test-Path -LiteralPath $skillsRootFullPath -PathType Container)) {
    New-Item -ItemType Directory -Path $skillsRootFullPath -Force | Out-Null
}

$registerScript = Join-Path $PSScriptRoot 'Register-SkillJunction.ps1'
if (-not (Test-Path -LiteralPath $registerScript -PathType Leaf)) {
    throw "Required script not found: $registerScript"
}

$results = @()
foreach ($entry in $skillEntries) {
    if (-not $entry.skillName) {
        throw "Manifest entry is missing 'skillName'."
    }
    if (-not $entry.repoUrl) {
        throw "Manifest entry '$($entry.skillName)' is missing 'repoUrl'."
    }

    $skillName = [string]$entry.skillName
    Assert-SkillName -SkillName $skillName

    $repoFolder = if ($entry.repoFolder) { [string]$entry.repoFolder } else { "$skillName-skill" }
    Assert-RepoFolder -RepoFolder $repoFolder

    $repoPath = Join-Path $repoRootFullPath $repoFolder
    $repoUrl = [string]$entry.repoUrl
    $cloned = $false

    if (Test-Path -LiteralPath $repoPath) {
        $gitDir = Join-Path $repoPath '.git'
        if (-not (Test-Path -LiteralPath $gitDir)) {
            throw "Repo path exists but is not a git repo: $repoPath"
        }

        $existingOriginResult = Invoke-GitQuiet -RepoPath $repoPath -Arguments @('remote', 'get-url', 'origin')
        if ($existingOriginResult.ExitCode -ne 0 -or $existingOriginResult.Output.Count -eq 0) {
            throw "Existing repo has no origin remote: $repoPath"
        }
        $existingOrigin = ($existingOriginResult.Output -join "`n").Trim()
        if ($existingOrigin.Trim() -ne $repoUrl.Trim()) {
            throw "Repo origin mismatch for '$skillName'. Existing: '$existingOrigin' Manifest: '$repoUrl'"
        }
    } else {
        Invoke-GitChecked -Arguments @('clone', $repoUrl, $repoPath)
        $cloned = $true
    }

    $localChangesResult = Invoke-GitQuiet -RepoPath $repoPath -Arguments @('status', '--porcelain')
    if ($localChangesResult.ExitCode -ne 0) {
        throw "Failed to inspect repo status for '$skillName': $repoPath"
    }
    $localChanges = @($localChangesResult.Output)
    if ($localChanges.Count -gt 0) {
        throw "Repo has local changes; refusing to change checkout for '$skillName': $repoPath"
    }

    if (-not $cloned) {
        Invoke-GitChecked -RepoPath $repoPath -Arguments @('fetch', 'origin')
    }

    $branch = if ($entry.branch) { [string]$entry.branch } else { '' }
    $commit = if ($entry.commit) { [string]$entry.commit } else { '' }

    if ($branch -and $branch -ne 'HEAD') {
        $localBranchExists = Invoke-GitQuiet -RepoPath $repoPath -Arguments @('rev-parse', '--verify', '--quiet', $branch)
        if ($localBranchExists.ExitCode -eq 0) {
            Invoke-GitChecked -RepoPath $repoPath -Arguments @('checkout', $branch)
        } else {
            Invoke-GitChecked -RepoPath $repoPath -Arguments @('checkout', '-B', $branch, "origin/$branch")
        }
    }

    if ($commit -and -not $UseBranchTip) {
        Invoke-GitChecked -RepoPath $repoPath -Arguments @('checkout', $commit)
    }

    $skillFile = Join-Path $repoPath 'SKILL.md'
    if (-not (Test-Path -LiteralPath $skillFile -PathType Leaf)) {
        throw "Restored repo does not contain SKILL.md for '$skillName': $repoPath"
    }

    & $registerScript -SkillName $skillName -RepoPath $repoPath -SkillsRoot $skillsRootFullPath | Out-Host
    $currentCommitResult = Invoke-GitQuiet -RepoPath $repoPath -Arguments @('rev-parse', 'HEAD')
    $currentCommit = if ($currentCommitResult.ExitCode -eq 0) { ($currentCommitResult.Output -join "`n").Trim() } else { '' }

    $results += [pscustomobject]@{
        skillName = $skillName
        repoPath = $repoPath
        registeredPath = (Join-Path $skillsRootFullPath $skillName)
        commit = $currentCommit
    }
}

Write-Output "Restored current skill set: $($results.Count) skill(s)"
foreach ($row in $results) {
    Write-Output ("- {0}: {1}" -f $row.skillName, $row.registeredPath)
}
