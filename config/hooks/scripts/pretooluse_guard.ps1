$ErrorActionPreference = 'Stop'
[Console]::InputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

function Write-Decision {
    param([string]$Decision, [string]$Reason = '')
    $result = @{ decision = $Decision }
    if ($Reason) { $result.reason = $Reason }
    [Console]::Out.WriteLine(($result | ConvertTo-Json -Compress))
}

try {
    $payload = [Console]::In.ReadToEnd() | ConvertFrom-Json -ErrorAction Stop
} catch {
    Write-Decision 'ask' 'safety-gate could not parse hook input'
    exit 0
}

$toolCall = $payload.toolCall
$tool = [string]$toolCall.name
$argsObject = $toolCall.args
$commandLine = [string]$argsObject.CommandLine
if (-not $commandLine) { $commandLine = [string]$argsObject.command }
if ($tool -ne 'run_command' -or -not $commandLine) {
    Write-Decision 'auto_approve'
    exit 0
}

$denylist = @(
    @{ Pattern = '\bmkfs(\.\w+)?\b'; Reason = 'filesystem formatting' },
    @{ Pattern = '\bdd\b[^|]*\bof=/dev/(sd|nvme|vd|disk)'; Reason = 'raw write to a disk device' },
    @{ Pattern = '(?i)\bformat\s+[a-z]:'; Reason = 'drive formatting' },
    @{ Pattern = '(?i)\b(rm\s+-[a-zA-Z]*r[a-zA-Z]*f|Remove-Item\b.*-Recurse.*-Force)\s+([/]|~|\$HOME|/home|/etc|/usr|/var|\*|C:\\?\s*$)'; Reason = 'recursive deletion of a system or home root' },
    @{ Pattern = '(?i)\b(shutdown|reboot|halt|poweroff)\b'; Reason = 'system shutdown or reboot' },
    @{ Pattern = '(?i)(curl|wget)[^|;]*\|\s*(ba)?sh(\s|$)'; Reason = 'piping a download directly into a shell' },
    @{ Pattern = '(?i)\biex\s*\(\s*(New-Object\s+System\.Net\.WebClient|Invoke-WebRequest)'; Reason = 'PowerShell download-and-execute' },
    @{ Pattern = ':\(\)\s*\{\s*:\|:&\s*\}\s*;:'; Reason = 'fork bomb' },
    @{ Pattern = '(?i)\bgit\s+push\b.*(?:--force|-f)(?:\s|=).*\b(main|master)\b'; Reason = 'force-push to main or master' },
    @{ Pattern = '>\s*/dev/sd[a-z]'; Reason = 'redirecting output to a raw disk device' }
)

foreach ($entry in $denylist) {
    if ($commandLine -match $entry.Pattern) {
        Write-Decision 'deny' "safety-gate blocked $($entry.Reason)"
        exit 0
    }
}

Write-Decision 'auto_approve'
