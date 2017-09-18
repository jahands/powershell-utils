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
