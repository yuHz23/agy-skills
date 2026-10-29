$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
$message = @{
    injectSteps = @(
        @{
            ephemeralMessage = 'Iron Law: no completion claims without fresh evidence. Cite the command, exit code, and output from this session; never fabricate results.'
        }
    )
}
[Console]::Out.WriteLine(($message | ConvertTo-Json -Depth 5 -Compress))
