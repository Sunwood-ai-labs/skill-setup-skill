[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$OutputPath,

    [string]$SkillsRoot = (Join-Path $HOME '.codex\skills')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-ExistingPath {
    param([Parameter(Mandatory = $true)][string]$Path)
    return (Resolve-Path -LiteralPath $Path -ErrorAction Stop).ProviderPath
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

if (-not (Test-Path -LiteralPath $SkillsRoot -PathType Container)) {
    throw "Skills root does not exist: $SkillsRoot"
}

$skillsRootFullPath = Resolve-ExistingPath -Path $SkillsRoot
$skills = Get-ChildItem -LiteralPath $skillsRootFullPath -Force
[object[]]$exportItems = @()

foreach ($skill in $skills) {
    if ($skill.LinkType -ne 'Junction') {
        continue
    }

    $targets = @($skill.Target)
    if ($targets.Count -ne 1) {
        Write-Warning "Skipped '$($skill.Name)': unexpected junction target list."
        continue
    }

    try {
        $repoPath = Resolve-ExistingPath -Path $targets[0]
    } catch {
        Write-Warning "Skipped '$($skill.Name)': failed to resolve target '$($targets[0])'."
        continue
    }

    $skillFile = Join-Path $repoPath 'SKILL.md'
    if (-not (Test-Path -LiteralPath $skillFile -PathType Leaf)) {
        Write-Warning "Skipped '$($skill.Name)': SKILL.md not found in '$repoPath'."
        continue
    }

    $gitDir = Join-Path $repoPath '.git'
    if (-not (Test-Path -LiteralPath $gitDir)) {
        Write-Warning "Skipped '$($skill.Name)': target is not a git repository ('$repoPath')."
        continue
    }

    $repoUrlResult = Invoke-GitQuiet -RepoPath $repoPath -Arguments @('remote', 'get-url', 'origin')
    if ($repoUrlResult.ExitCode -ne 0 -or $repoUrlResult.Output.Count -eq 0) {
        Write-Warning "Skipped '$($skill.Name)': origin remote not found."
        continue
    }

    $branchResult = Invoke-GitQuiet -RepoPath $repoPath -Arguments @('rev-parse', '--abbrev-ref', 'HEAD')
    $commitResult = Invoke-GitQuiet -RepoPath $repoPath -Arguments @('rev-parse', 'HEAD')
    $statusResult = Invoke-GitQuiet -RepoPath $repoPath -Arguments @('status', '--porcelain')
    $repoUrl = ($repoUrlResult.Output -join "`n").Trim()
    $branch = if ($branchResult.ExitCode -eq 0) { ($branchResult.Output -join "`n").Trim() } else { '' }
    $commit = if ($commitResult.ExitCode -eq 0) { ($commitResult.Output -join "`n").Trim() } else { '' }
    $statusLines = @($statusResult.Output)

    $exportItems += [pscustomobject]@{
        skillName = $skill.Name
        repoUrl = $repoUrl
        branch = $branch
        commit = $commit
        repoFolder = [System.IO.Path]::GetFileName($repoPath)
        dirty = ($statusLines.Count -gt 0)
    }
}

$manifest = [ordered]@{
    schema = 'codex-skill-set/v1'
    exportedAt = (Get-Date).ToUniversalTime().ToString('o')
    sourceComputer = $env:COMPUTERNAME
    skillsRoot = $skillsRootFullPath
    skills = [object[]]$exportItems
}

$json = $manifest | ConvertTo-Json -Depth 8
$outputFullPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)
$outputDir = Split-Path -Parent $outputFullPath
if ($outputDir -and -not (Test-Path -LiteralPath $outputDir -PathType Container)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

Set-Content -LiteralPath $outputFullPath -Value $json -Encoding utf8
Write-Output "Exported current skill set: $($exportItems.Count) skill(s) to: $outputFullPath"

$dirtyItems = @($exportItems | Where-Object { $_.dirty })
if ($dirtyItems.Count -gt 0) {
    Write-Warning "Manifest records dirty repo state, but uncommitted changes are not migrated: $($dirtyItems.skillName -join ', ')"
}
