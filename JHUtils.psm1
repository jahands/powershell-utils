# Generated on: 09/18/2017 14:17:59
# Description: Helpful PowerShell Modules
# Author: Jacob Hands <jacob@gogit.io>

# ============================================ #

# BashUtils.psm1
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

# ============================================ #

# MultiPlatformUtils.psm1
Function Get-Platform {
    <#
    .SYNOPSIS
    Gets platform name
    #>
    Return [System.Environment]::OSVersion.Platform
}
Function Test-Platform {
    <#
    .SYNOPSIS
    Tests if PS is running on specified platform

    .DESCRIPTION
    Tests if PS is running on Windows or Unix

    This is a simple wrapper around checking if 
    [System.Environment]::OSVersion.Platform is equal to
    'Unix' or 'Win32NT'
    
    .PARAMETER Unix
    Checks if running on Unix

    .PARAMETER Windows
    Checks if running on Windows

    .EXAMPLE
    Test-Platform -Unix

    Returns TRUE if the OS is Unix

    .EXAMPLE
    Test-Platform -Windows

    Returns TRUE if the OS is Windows (Win32NT)

    .NOTES
    #>
    Param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Unix')]
        [switch]$Unix,
        [Parameter(Mandatory = $true, ParameterSetName = 'Windows')]
        [switch]$Windows
    )
    $platform = [System.Environment]::OSVersion.Platform
    if ($Unix) {
        if ($platform -ieq 'Unix') {
            Return $true
        } else {
            Return $false
        }
    } elseif ($Windows) {
        if ($platform -ieq 'Win32NT') {
            Return $true
        } else {
            Return $false
        }
    }
}

Export-ModuleMember -Function Get-Platform,Test-Platform
