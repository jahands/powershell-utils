Function Invoke-Bash {
    <#
    .SYNOPSIS
    Runs a bash command
    
    .DESCRIPTION
    Runs a bash command in /bin/bash on Unix and
    bash.exe on Windows.
    
    .PARAMETER Command
    Bash expression to run
    
    .EXAMPLE
    Invoke-Bash "find /"
    
    .NOTES
    Only works on Windows if WSL (Bash on Windows) is installed.
    #>
    Param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Command
    )
    $platform = [System.Environment]::OSVersion.Platform
    if ($platform -ieq 'Unix') {
        $bashCmd = '/bin/bash'
        if (-not (Test-Path $bashCmd)) {
            Write-Error "/bin/bash doesn't exist! Is it installed?"
        } else {
            Invoke-Expression "$bashCmd -c '$Command'"
        }
    } elseif ($platform -ieq 'Win32NT') {
        $bashCmd = 'C:\WINDOWS\system32\bash.exe'
        if (-not (Test-Path $bashCmd)) {
            Write-Error "C:\WINDOWS\system32\bash.exe doesn't exist! Is it installed?"
        } else {
            Invoke-Expression "$bashCmd -c '$Command'"
        }
    } else {
        Write-Error "Unknown Platform: $platform"
    }
}
Export-ModuleMember -Function Invoke-Bash
