<#
.SYNOPSIS
    Installs agy-skills globally for Antigravity CLI, App, and IDE on Windows.
.DESCRIPTION
    Does not require administrator rights. Settings and hooks are merged into
    the current user's profile; existing files are backed up before updates.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
$homeDir = [Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)
if ([string]::IsNullOrWhiteSpace($homeDir)) { $homeDir = $HOME }
$homeDir = [System.IO.Path]::GetFullPath($homeDir)

$geminiDir = Join-Path $homeDir '.gemini'
$configDir = Join-Path $geminiDir 'config'
$settingsPath = Join-Path (Join-Path $geminiDir 'antigravity-cli') 'settings.json'
$hooksPath = Join-Path $configDir 'hooks.json'
$rulePath = Join-Path $geminiDir 'GEMINI.md'
$legacyRulePath = Join-Path $configDir 'GEMINI.md'
$rootRuleExists = Test-Path -LiteralPath $rulePath
$legacyRuleText = if (Test-Path -LiteralPath $legacyRulePath) { [System.IO.File]::ReadAllText($legacyRulePath) } else { '' }
if ($legacyRuleText -match '(?im)^# Anti-fake-work\b' -or (-not $rootRuleExists -and (Test-Path -LiteralPath $legacyRulePath))) {
    $rulePath = $legacyRulePath
}
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'

function Read-JsonObject {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return [PSCustomObject]@{} }
    try {
        $value = ConvertFrom-Json -InputObject ([System.IO.File]::ReadAllText($Path)) -ErrorAction Stop
    } catch {
        throw "Invalid JSON at '$Path'. The original file was left unchanged. Fix it and run this installer again. $($_.Exception.Message)"
    }
    if ($null -eq $value -or $value -isnot [PSCustomObject]) {
        throw "Expected a JSON object at '$Path'. The original file was left unchanged."
    }
    return $value
}

function Set-ObjectProperty {
    param($Target, [string]$Name, $Value)
    if ($Target.PSObject.Properties[$Name]) {
        $Target.PSObject.Properties[$Name].Value = $Value
    } else {
        $Target | Add-Member -MemberType NoteProperty -Name $Name -Value $Value
    }
}

function Backup-File {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (Test-Path -LiteralPath $Path) {
        $backupPath = "$Path.bak.$timestamp"
        Copy-Item -LiteralPath $Path -Destination $backupPath
        Write-Host "[*] Backup: $backupPath"
    }
}

function Save-JsonObject {
    param([string]$Path, $Value)
    $parent = Split-Path -Parent $Path
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
    Backup-File -Path $Path
    $tempPath = "$Path.$([guid]::NewGuid().ToString('N')).tmp"
    try {
        $json = ConvertTo-Json -InputObject $Value -Depth 100
        [System.IO.File]::WriteAllText($tempPath, $json, $utf8NoBom)
        Move-Item -LiteralPath $tempPath -Destination $Path -Force
    } finally {
        Remove-Item -LiteralPath $tempPath -Force -ErrorAction SilentlyContinue
    }
}

$skillsSource = Join-Path $PSScriptRoot 'skills'
$ruleSource = Join-Path $PSScriptRoot 'rules\anti-fake-work.md'
$hookTemplatePath = Join-Path $PSScriptRoot 'config\hooks\hooks.json'
$hookScriptsSource = Join-Path $PSScriptRoot 'config\hooks\scripts'
$settings = Read-JsonObject -Path $settingsPath
$installedHooks = Read-JsonObject -Path $hooksPath
$hookTemplate = Read-JsonObject -Path $hookTemplatePath
if (-not (Test-Path -LiteralPath $skillsSource)) { throw "Skills folder not found: $skillsSource" }
if (-not (Test-Path -LiteralPath $ruleSource)) { throw "Rule file not found: $ruleSource" }
if (-not (Test-Path -LiteralPath $hookScriptsSource)) { throw "Hook scripts not found: $hookScriptsSource" }

$skills = @(Get-ChildItem -LiteralPath $skillsSource -Directory)
if ($skills.Count -eq 0) { throw "No skill folders found in $skillsSource" }

# Merge supported CLI settings. Existing allow and deny rules are retained;
# explicit Ask rules are cleared because this installer is the auto-pass setup.
Set-ObjectProperty $settings '$schema' 'https://antigravity.google/schemas/v1/settings.json'
Set-ObjectProperty $settings 'agentMode' 'accept-edits'
Set-ObjectProperty $settings 'artifactReviewPolicy' 'always-proceed'
Set-ObjectProperty $settings 'toolPermission' 'always-proceed'
Set-ObjectProperty $settings 'enableTerminalSandbox' $true
Set-ObjectProperty $settings 'allowNonWorkspaceAccess' $false

$trusted = @()
if ($settings.PSObject.Properties['trustedWorkspaces'] -and $null -ne $settings.trustedWorkspaces) {
    $trusted = @($settings.trustedWorkspaces)
}
$homeKey = $homeDir.TrimEnd([char[]]@('\', '/'))
$alreadyTrusted = @($trusted | Where-Object {
    ([string]$_).TrimEnd([char[]]@('\', '/')) -ieq $homeKey
}).Count -gt 0
if (-not $alreadyTrusted) { $trusted += $homeDir }
Set-ObjectProperty $settings 'trustedWorkspaces' $trusted

$permissionsProperty = $settings.PSObject.Properties['permissions']
if (-not $permissionsProperty) {
    $permissions = [PSCustomObject]@{}
    Set-ObjectProperty $settings 'permissions' $permissions
} else {
    $permissions = $permissionsProperty.Value
    if ($null -eq $permissions -or $permissions -isnot [PSCustomObject]) {
        throw "Expected 'permissions' to be a JSON object in '$settingsPath'. The original file was left unchanged."
    }
}
Set-ObjectProperty $permissions 'ask' @()

# Point global hooks to bundled scripts under the user's profile.
$globalHookScripts = Join-Path $configDir 'agy-skills\hooks\scripts'
$toolHookPath = Join-Path $globalHookScripts 'pretooluse_guard.ps1'
$reminderHookPath = Join-Path $globalHookScripts 'preinv_reminder.ps1'
$quotedToolHook = '"' + $toolHookPath.Replace('"', '""') + '"'
$quotedReminderHook = '"' + $reminderHookPath.Replace('"', '""') + '"'
$safetyHook = $hookTemplate.PSObject.Properties['agy-skills-safety-gate'].Value
$reminderHook = $hookTemplate.PSObject.Properties['agy-skills-iron-law-reminder'].Value
$safetyHook.PreToolUse[0].hooks[0].command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File $quotedToolHook"
$reminderHook.PreInvocation[0].command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File $quotedReminderHook"
Set-ObjectProperty $installedHooks 'agy-skills-safety-gate' $safetyHook
Set-ObjectProperty $installedHooks 'agy-skills-iron-law-reminder' $reminderHook

# Apply all files after settings and hooks have passed JSON validation.
foreach ($destination in @(
    (Join-Path $geminiDir 'antigravity-cli\skills'),
    (Join-Path $configDir 'skills')
)) {
    New-Item -ItemType Directory -Path $destination -Force | Out-Null
    foreach ($skill in $skills) {
        $skillDestination = Join-Path $destination $skill.Name
        New-Item -ItemType Directory -Path $skillDestination -Force | Out-Null
        Copy-Item -Path (Join-Path $skill.FullName '*') -Destination $skillDestination -Recurse -Force
    }
}
Write-Host "[+] Installed $($skills.Count) skills for Antigravity CLI and IDE."

New-Item -ItemType Directory -Path $globalHookScripts -Force | Out-Null
Copy-Item -Path (Join-Path $hookScriptsSource '*') -Destination $globalHookScripts -Recurse -Force
Save-JsonObject -Path $hooksPath -Value $installedHooks
Write-Host "[+] Installed global hooks: $hooksPath"

$ruleText = [System.IO.File]::ReadAllText($ruleSource)
$ruleLines = $ruleText -split '\r?\n'
$start = -1
for ($i = 0; $i -lt $ruleLines.Length; $i++) {
    if ($ruleLines[$i] -match '^-\s+Never claim') { $start = $i; break }
}
if ($start -lt 0) { throw "Could not find the rule body in '$ruleSource'." }
$ruleBody = ($ruleLines[$start..($ruleLines.Length - 1)] -join [Environment]::NewLine)
$existingRule = if (Test-Path -LiteralPath $rulePath) { [System.IO.File]::ReadAllText($rulePath) } else { '' }
if ($existingRule -notmatch '(?im)^# Anti-fake-work\b') {
    Backup-File -Path $rulePath
    $separator = if ([string]::IsNullOrWhiteSpace($existingRule)) { '' } else { [Environment]::NewLine + [Environment]::NewLine }
    $ruleContent = $existingRule + $separator + "# Anti-fake-work (agy-skills)" + [Environment]::NewLine + [Environment]::NewLine + $ruleBody + [Environment]::NewLine
    [System.IO.File]::WriteAllText($rulePath, $ruleContent, $utf8NoBom)
    Write-Host "[+] Added the global Anti-fake-work rule: $rulePath"
} else {
    Write-Host "[*] Global Anti-fake-work rule already exists."
}

Save-JsonObject -Path $settingsPath -Value $settings
Write-Host "[+] Auto-pass settings saved: $settingsPath"
Write-Host "    agentMode=accept-edits; toolPermission=always-proceed"
Write-Host "    terminal sandbox enabled; non-workspace file access disabled"
Write-Host "    explicit Ask rules cleared; existing Allow and Deny rules retained"
Write-Host ""
Write-Host "Restart Antigravity CLI to load the global settings, skills, and hooks."
