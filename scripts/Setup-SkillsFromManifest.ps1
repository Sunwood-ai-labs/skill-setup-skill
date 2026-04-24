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

& (Join-Path $PSScriptRoot 'Restore-CurrentSkillSet.ps1') `
    -ManifestPath $ManifestPath `
    -RepoRoot $RepoRoot `
    -SkillsRoot $SkillsRoot `
    -UseBranchTip:$UseBranchTip
