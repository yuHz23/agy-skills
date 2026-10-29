<#
.SYNOPSIS
    Script tu dong cai dat agy-skills va thiet lap Auto-Pass cho Antigravity CLI / IDE.
.DESCRIPTION
    Tu dong:
    1. Nhan dien thu muc Home cua moi truong hien tai ($HOME).
    2. Cai dat toan bo skills vao ~/.gemini/config/skills/.
    3. Cai dat rule Anti-fake-work vao ~/.gemini/config/GEMINI.md.
    4. Tu dong cau hinh ~/.gemini/antigravity-cli/settings.json:
       - trustedWorkspaces tro chinh xac vao thu muc Home cua user hien tai.
       - agentMode: "accept-edits"
       - artifactReviewPolicy: "always-proceed"
       - toolPermission: "always-proceed"
       - permissions.allow bao gom danh sach lenh chuan + "command(regex:.*)"
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "   AGY-SKILLS AUTO INSTALLER & AUTO-PASS  " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

$homeDir = [System.IO.Path]::GetFullPath($HOME)
Write-Host "[+] Thu muc Home hien tai: $homeDir" -ForegroundColor Green

# 1. Cai dat Skills
$skillsSrc = Join-Path $PSScriptRoot "skills"
$skillsDest = Join-Path $homeDir ".gemini\config\skills"
if (Test-Path $skillsSrc) {
    if (-not (Test-Path $skillsDest)) {
        New-Item -ItemType Directory -Path $skillsDest -Force | Out-Null
    }
    Copy-Item -Path "$skillsSrc\*" -Destination $skillsDest -Recurse -Force
    Write-Host "[+] Da copy toan bo skills vao: $skillsDest" -ForegroundColor Green
} else {
    Write-Host "[!] Khong tim thay thu muc skills trong $skillsSrc" -ForegroundColor Yellow
}

# 2. Cai dat Rule Anti-fake-work vao GEMINI.md
$rulesSrc = Join-Path $PSScriptRoot "rules\anti-fake-work.md"
$configDir = Join-Path $homeDir ".gemini\config"
$geminiMd = Join-Path $configDir "GEMINI.md"

if (Test-Path $rulesSrc) {
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }
    $ruleLines = Get-Content -Encoding utf8 $rulesSrc
    $ruleBody = @()
    $record = $false
    foreach ($line in $ruleLines) {
        if ($line -match "^-\s+Never claim") {
            $record = $true
        }
        if ($record) {
            $ruleBody += $line
        }
    }

    $existing = ""
    if (Test-Path $geminiMd) {
        $existing = Get-Content -Raw -Encoding utf8 $geminiMd
    }
    if ($existing -notmatch "Anti-fake-work") {
        $header = "`r`n`r`n# Anti-fake-work (luat luon bat - tu bo skill agy-skills)`r`n`r`n"
        $ruleText = $ruleBody -join "`r`n"
        Add-Content -Path $geminiMd -Value ($header + $ruleText) -Encoding utf8
        Write-Host "[+] Da them Anti-fake-work rule vao: $geminiMd" -ForegroundColor Green
    } else {
        Write-Host "[*] Rule Anti-fake-work da co trong $geminiMd (bo qua)" -ForegroundColor DarkGray
    }
}

# 3. Cau hinh tu dong settings.json (Auto-Pass)
$agyCliDir = Join-Path $homeDir ".gemini\antigravity-cli"
$settingsPath = Join-Path $agyCliDir "settings.json"

if (-not (Test-Path $agyCliDir)) {
    New-Item -ItemType Directory -Path $agyCliDir -Force | Out-Null
}

function Set-ObjectProperty {
    param($Target, [string]$Name, $Value)
    if ($Target.PSObject.Properties[$Name]) {
        $Target.$Name = $Value
    } else {
        $Target | Add-Member -MemberType NoteProperty -Name $Name -Value $Value
    }
}

$defaultAllows = @(
    "command(git)", "command(python)", "command(npm)", "command(npx)", "command(node)",
    "command(dotnet)", "command(cargo)", "command(make)", "command(cmake)", "command(docker)",
    "command(podman)", "command(ls)", "command(cat)", "command(grep)", "command(find)",
    "command(curl)", "command(wget)", "command(pip)", "command(pipx)", "command(go)",
    "command(rustc)", "command(flutter)", "command(dart)", "command(adb)", "command(ffmpeg)",
    "command(7z)", "command(tar)", "command(mkdir)", "command(cp)", "command(mv)",
    "command(chmod)", "command(echo)", "command(pwd)", "command(which)", "command(env)",
    "command(whoami)", "command(date)", "command(dir)", "command(type)", "command(cd)",
    "command(tmux)", "command(ssh)", "command(scp)", "command(rsync)", "command(ping)",
    "command(netstat)", "command(ss)", "command(jq)", "command(yq)", "command(regex:.*)"
)

$settings = [PSCustomObject]@{}
if (Test-Path $settingsPath) {
    try {
        $jsonRaw = Get-Content -Raw -Encoding utf8 $settingsPath
        $parsed = $jsonRaw | ConvertFrom-Json
        if ($parsed) {
            $settings = $parsed
            Copy-Item -Path $settingsPath -Destination "$settingsPath.bak" -Force
            Write-Host "[*] Da backup settings cu sang: $settingsPath.bak" -ForegroundColor DarkGray
        }
    } catch {
        Write-Host "[!] Khong the parse settings.json cu, se tao moi." -ForegroundColor Yellow
        $settings = [PSCustomObject]@{}
    }
}

Set-ObjectProperty $settings "agentMode" "accept-edits"
Set-ObjectProperty $settings "artifactReviewPolicy" "always-proceed"
Set-ObjectProperty $settings "toolPermission" "always-proceed"

# trustedWorkspaces
$trusted = @()
if ($settings.PSObject.Properties["trustedWorkspaces"] -and $settings.trustedWorkspaces) {
    $trusted = @($settings.trustedWorkspaces)
}
if ($trusted -notcontains $homeDir) {
    $trusted += $homeDir
}
Set-ObjectProperty $settings "trustedWorkspaces" $trusted

# permissions.allow
if (-not $settings.PSObject.Properties["permissions"] -or -not $settings.permissions) {
    Set-ObjectProperty $settings "permissions" ([PSCustomObject]@{})
}
$allow = @()
if ($settings.permissions.PSObject.Properties["allow"] -and $settings.permissions.allow) {
    $allow = @($settings.permissions.allow)
}
foreach ($cmd in $defaultAllows) {
    if ($allow -notcontains $cmd) {
        $allow += $cmd
    }
}
Set-ObjectProperty $settings.permissions "allow" $allow

$jsonOutput = $settings | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($settingsPath, $jsonOutput, [System.Text.Encoding]::UTF8)

Write-Host "[+] Cau hinh settings.json Auto-pass thanh cong tai: $settingsPath" -ForegroundColor Green
Write-Host "    - trustedWorkspaces: $homeDir" -ForegroundColor Cyan
Write-Host "    - toolPermission: always-proceed" -ForegroundColor Cyan
Write-Host "    - agentMode: accept-edits" -ForegroundColor Cyan
Write-Host "    - permissions.allow: da them command(regex:.*)" -ForegroundColor Cyan
Write-Host ""
Write-Host "===> HOAN TAT CAI DAT! Khoi dong lai Antigravity CLI de ap dung." -ForegroundColor Green
