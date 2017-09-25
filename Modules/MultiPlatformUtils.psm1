Function Set-PlatformVariables {
    <#
    .SYNOPSIS
    Sets platform variables like on PS Core
    
    .DESCRIPTION
    Sets platform variables like on PS Core.
    Vars are $IsLinux, $IsWindows
    $IsMacOS is not set because I'm unsure how to test for that.
    Unsure if
    #>
    if ($PSVersionTable.PSEdition -ne 'Core') {
        $platform = [System.Environment]::OSVersion.Platform
        if ($platform -ieq 'Unix') {
            if ($IsLinux -eq $null) {
                Set-Variable -Name IsLinux -Value $true -Scope Global -Option Constant
            }
            if ($IsWindows -eq $null) {
                Set-Variable -Name IsWindows -Value $false -Scope Global -Option Constant
            }
        } elseif ($platform -ieq 'Win32NT') {
            if ($IsLinux -eq $null) {
                Set-Variable -Name IsLinux -Value $false -Scope Global -Option Constant
            }
            if ($IsWindows -eq $null) {
                Set-Variable -Name IsWindows -Value $true -Scope Global -Option Constant
            }
        }
    }
}
# Go ahead and set platform variables
Set-PlatformVariables
Function Get-Platform {
    <#
    .SYNOPSIS
    Gets platform name
    #>
    [Obsolete('Checking value of global variables IsLinux and IsWindows should be used instead.')]
    Param ()
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
    [Obsolete('Checking value of global variables IsLinux and IsWindows should be used instead.')]
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
Function Set-AllowedHosts {
    <#
        .SYNOPSIS
        Checks to see if something is allowed to run on the current PC.
        
        .DESCRIPTION
        Checks to see if something is allowed to run on the current PC.
        If not, the script is stopped with -ErrorAction:Stop
        
        .PARAMETER Computers
        List of computer names allowed.

        .PARAMETER Windows
        Only allow script on Windows

        .PARAMETER Unix
        Only allow script on Unix
        Obsolete, use -Linux instead.

        .PARAMETER Linux
        Only allow script on Linux.
        
        .EXAMPLE
        Set-AllowedHosts ENVY10
        
        .NOTES
        General notes
    #>
    Param (
        [string[]]$Computers,
        [switch]$Windows,
        [Obsolete('This has been replaced by -Linux to match PS Core platform naming.')]
        [switch]$Unix,
        [switch]$Linux
    )
    if ($Computers -ne $null -and -not $Computers.Contains($env:COMPUTERNAME)) {
        Write-Error "Computer: $($env:COMPUTERNAME) is not on list of valid computers: $($Computers -join ', ')" -ErrorAction:Stop
    }
    # Check if platform is specified
    if($Windows -or $Unix -or $Linux){
        if ($IsLinux -and -not ($Linux -or $Unix)) {
            Write-Error 'This command cannot be run on Linux!' -ErrorAction:Stop
        } elseif ($IsWindows -and -not $Windows) {
            Write-Error 'This command cannot be run on Windows!' -ErrorAction:Stop
        }
    }
}

Export-ModuleMember -Function Get-Platform, Test-Platform, Set-AllowedHosts, Set-PlatformVariables
