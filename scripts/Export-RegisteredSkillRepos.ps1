[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$OutputPath,

    [string]$SkillsRoot = (Join-Path $HOME '.codex\skills')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

& (Join-Path $PSScriptRoot 'Export-CurrentSkillSet.ps1') `
    -OutputPath $OutputPath `
    -SkillsRoot $SkillsRoot
