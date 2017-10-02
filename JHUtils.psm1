# Generated on: 10/02/2017 11:50:18
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

# ============================================ #

# New-DynamicParameter.psm1
# NOTE: This function is bound to license here:
# https://gallery.technet.microsoft.com/scriptcenter/New-DynamicParameter-63389a46
# I have added this here for convenience
# Changes I've made to this script: https://git.io/v5hbb
<#
.SYNOPSIS
    Helper function to simplify creating dynamic parameters

.DESCRIPTION
    Helper function to simplify creating dynamic parameters.

    Example use cases:
        Include parameters only if your environment dictates it
        Include parameters depending on the value of a user-specified parameter
        Provide tab completion and intellisense for parameters, depending on the environment

    Please keep in mind that all dynamic parameters you create, will not have corresponding variables created.
        Use New-DynamicParameter with 'CreateVariables' switch in your main code block,
        ('Process' for advanced functions) to create those variables.
        Alternatively, manually reference $PSBoundParameters for the dynamic parameter value.

    This function has two operating modes:

    1. All dynamic parameters created in one pass using pipeline input to the function. This mode allows to create dynamic parameters en masse,
    with one function call. There is no need to create and maintain custom RuntimeDefinedParameterDictionary.

    2. Dynamic parameters are created by separate function calls and added to the RuntimeDefinedParameterDictionary you created beforehand.
    Then you output this RuntimeDefinedParameterDictionary to the pipeline. This allows more fine-grained control of the dynamic parameters,
    with custom conditions and so on.

.NOTES
    Credits to jrich523 and ramblingcookiemonster for their initial code and inspiration:
        https://github.com/RamblingCookieMonster/PowerShell/blob/master/New-DynamicParam.ps1
        http://ramblingcookiemonster.wordpress.com/2014/11/27/quick-hits-credentials-and-dynamic-parameters/
        http://jrich523.wordpress.com/2013/05/30/powershell-simple-way-to-add-dynamic-parameters-to-advanced-function/

    Credit to BM for alias and type parameters and their handling

.PARAMETER Name
    Name of the dynamic parameter

.PARAMETER Type
    Type for the dynamic parameter.  Default is string

.PARAMETER Alias
    If specified, one or more aliases to assign to the dynamic parameter

.PARAMETER Mandatory
    If specified, set the Mandatory attribute for this dynamic parameter

.PARAMETER Position
    If specified, set the Position attribute for this dynamic parameter

.PARAMETER HelpMessage
    If specified, set the HelpMessage for this dynamic parameter

.PARAMETER DontShow
    If specified, set the DontShow for this dynamic parameter.
    This is the new PowerShell 4.0 attribute that hides parameter from tab-completion.
    http://www.powershellmagazine.com/2013/07/29/pstip-hiding-parameters-from-tab-completion/

.PARAMETER ValueFromPipeline
    If specified, set the ValueFromPipeline attribute for this dynamic parameter

.PARAMETER ValueFromPipelineByPropertyName
    If specified, set the ValueFromPipelineByPropertyName attribute for this dynamic parameter

.PARAMETER ValueFromRemainingArguments
    If specified, set the ValueFromRemainingArguments attribute for this dynamic parameter

.PARAMETER ParameterSetName
    If specified, set the ParameterSet attribute for this dynamic parameter. By default parameter is added to all parameters sets.

.PARAMETER AllowNull
    If specified, set the AllowNull attribute of this dynamic parameter

.PARAMETER AllowEmptyString
    If specified, set the AllowEmptyString attribute of this dynamic parameter

.PARAMETER AllowEmptyCollection
    If specified, set the AllowEmptyCollection attribute of this dynamic parameter

.PARAMETER ValidateNotNull
    If specified, set the ValidateNotNull attribute of this dynamic parameter

.PARAMETER ValidateNotNullOrEmpty
    If specified, set the ValidateNotNullOrEmpty attribute of this dynamic parameter

.PARAMETER ValidateRange
    If specified, set the ValidateRange attribute of this dynamic parameter

.PARAMETER ValidateLength
    If specified, set the ValidateLength attribute of this dynamic parameter

.PARAMETER ValidatePattern
    If specified, set the ValidatePattern attribute of this dynamic parameter

.PARAMETER ValidateScript
    If specified, set the ValidateScript attribute of this dynamic parameter

.PARAMETER ValidateSet
    If specified, set the ValidateSet attribute of this dynamic parameter

.PARAMETER Dictionary
    If specified, add resulting RuntimeDefinedParameter to an existing RuntimeDefinedParameterDictionary.
    Appropriate for custom dynamic parameters creation.

    If not specified, create and return a RuntimeDefinedParameterDictionary
    Aappropriate for a simple dynamic parameter creation.

.EXAMPLE
    Create one dynamic parameter.

    This example illustrates the use of New-DynamicParameter to create a single dynamic parameter.
    The Drive's parameter ValidateSet is populated with all available volumes on the computer for handy tab completion / intellisense.

    Usage: Get-FreeSpace -Drive <tab>

    function Get-FreeSpace
    {
        [CmdletBinding()]
        Param()
        DynamicParam
        {
            # Get drive names for ValidateSet attribute
            $DriveList = ([System.IO.DriveInfo]::GetDrives()).Name

            # Create new dynamic parameter
            New-DynamicParameter -Name Drive -ValidateSet $DriveList -Type ([array]) -Position 0 -Mandatory
        }

        Process
        {
            # Dynamic parameters don't have corresponding variables created,
            # you need to call New-DynamicParameter with CreateVariables switch to fix that.
            New-DynamicParameter -CreateVariables -BoundParameters $PSBoundParameters

            $DriveInfo = [System.IO.DriveInfo]::GetDrives() | Where-Object {$Drive -contains $_.Name}
            $DriveInfo |
                ForEach-Object {
                    if(!$_.TotalFreeSpace)
                    {
                        $FreePct = 0
                    }
                    else
                    {
                        $FreePct = [System.Math]::Round(($_.TotalSize / $_.TotalFreeSpace), 2)
                    }
                    New-Object -TypeName psobject -Property @{
                        Drive = $_.Name
                        DriveType = $_.DriveType
                        'Free(%)' = $FreePct
                    }
                }
        }
    }

.EXAMPLE
    Create several dynamic parameters not using custom RuntimeDefinedParameterDictionary (requires piping).

    In this example two dynamic parameters are created. Each parameter belongs to the different parameter set, so they are mutually exclusive.

    The Drive's parameter ValidateSet is populated with all available volumes on the computer.
    The DriveType's parameter ValidateSet is populated with all available drive types.

    Usage: Get-FreeSpace -Drive <tab>
        or
    Usage: Get-FreeSpace -DriveType <tab>

    Parameters are defined in the array of hashtables, which is then piped through the New-Object to create PSObject and pass it to the New-DynamicParameter function.
    Because of piping, New-DynamicParameter function is able to create all parameters at once, thus eleminating need for you to create and pass external RuntimeDefinedParameterDictionary to it.

    function Get-FreeSpace
    {
        [CmdletBinding()]
        Param()
        DynamicParam
        {
            # Array of hasthables that hold values for dynamic parameters
            $DynamicParameters = @(
                @{
                    Name = 'Drive'
                    Type = [array]
                    Position = 0
                    Mandatory = $true
                    ValidateSet = ([System.IO.DriveInfo]::GetDrives()).Name
                    ParameterSetName = 'Drive'
                },
                @{
                    Name = 'DriveType'
                    Type = [array]
                    Position = 0
                    Mandatory = $true
                    ValidateSet = [System.Enum]::GetNames('System.IO.DriveType')
                    ParameterSetName = 'DriveType'
                }
            )

            # Convert hashtables to PSObjects and pipe them to the New-DynamicParameter,
            # to create all dynamic paramters in one function call.
            $DynamicParameters | ForEach-Object {New-Object PSObject -Property $_} | New-DynamicParameter
        }
        Process
        {
            # Dynamic parameters don't have corresponding variables created,
            # you need to call New-DynamicParameter with CreateVariables switch to fix that.
            New-DynamicParameter -CreateVariables -BoundParameters $PSBoundParameters

            if($Drive)
            {
                $Filter = {$Drive -contains $_.Name}
            }
            elseif($DriveType)
            {
                $Filter =  {$DriveType -contains  $_.DriveType}
            }

            $DriveInfo = [System.IO.DriveInfo]::GetDrives() | Where-Object $Filter
            $DriveInfo |
                ForEach-Object {
                    if(!$_.TotalFreeSpace)
                    {
                        $FreePct = 0
                    }
                    else
                    {
                        $FreePct = [System.Math]::Round(($_.TotalSize / $_.TotalFreeSpace), 2)
                    }
                    New-Object -TypeName psobject -Property @{
                        Drive = $_.Name
                        DriveType = $_.DriveType
                        'Free(%)' = $FreePct
                    }
                }
        }
    }

.EXAMPLE
    Create several dynamic parameters, with multiple Parameter Sets, not using custom RuntimeDefinedParameterDictionary (requires piping).

    In this example three dynamic parameters are created. Two of the parameters are belong to the different parameter set, so they are mutually exclusive.
    One of the parameters belongs to both parameter sets.

    The Drive's parameter ValidateSet is populated with all available volumes on the computer.
    The DriveType's parameter ValidateSet is populated with all available drive types.
    The DriveType's parameter ValidateSet is populated with all available drive types.
    The Precision's parameter controls number of digits after decimal separator for Free Space percentage.

    Usage: Get-FreeSpace -Drive <tab> -Precision 2
        or
    Usage: Get-FreeSpace -DriveType <tab> -Precision 2

    Parameters are defined in the array of hashtables, which is then piped through the New-Object to create PSObject and pass it to the New-DynamicParameter function.
    If parameter with the same name already exist in the RuntimeDefinedParameterDictionary, a new Parameter Set is added to it.
    Because of piping, New-DynamicParameter function is able to create all parameters at once, thus eleminating need for you to create and pass external RuntimeDefinedParameterDictionary to it.

    function Get-FreeSpace
    {
        [CmdletBinding()]
        Param()
        DynamicParam
        {
            # Array of hasthables that hold values for dynamic parameters
            $DynamicParameters = @(
                @{
                    Name = 'Drive'
                    Type = [array]
                    Position = 0
                    Mandatory = $true
                    ValidateSet = ([System.IO.DriveInfo]::GetDrives()).Name
                    ParameterSetName = 'Drive'
                },
                @{
                    Name = 'DriveType'
                    Type = [array]
                    Position = 0
                    Mandatory = $true
                    ValidateSet = [System.Enum]::GetNames('System.IO.DriveType')
                    ParameterSetName = 'DriveType'
                },
                @{
                    Name = 'Precision'
                    Type = [int]
                    # This will add a Drive parameter set to the parameter
                    Position = 1
                    ParameterSetName = 'Drive'
                },
                @{
                    Name = 'Precision'
                    # Because the parameter already exits in the RuntimeDefinedParameterDictionary,
                    # this will add a DriveType parameter set to the parameter.
                    Position = 1
                    ParameterSetName = 'DriveType'
                }
            )

            # Convert hashtables to PSObjects and pipe them to the New-DynamicParameter,
            # to create all dynamic paramters in one function call.
            $DynamicParameters | ForEach-Object {New-Object PSObject -Property $_} | New-DynamicParameter
        }
        Process
        {
            # Dynamic parameters don't have corresponding variables created,
            # you need to call New-DynamicParameter with CreateVariables switch to fix that.
            New-DynamicParameter -CreateVariables -BoundParameters $PSBoundParameters

            if($Drive)
            {
                $Filter = {$Drive -contains $_.Name}
            }
            elseif($DriveType)
            {
                $Filter = {$DriveType -contains  $_.DriveType}
            }

            if(!$Precision)
            {
                $Precision = 2
            }

            $DriveInfo = [System.IO.DriveInfo]::GetDrives() | Where-Object $Filter
            $DriveInfo |
                ForEach-Object {
                    if(!$_.TotalFreeSpace)
                    {
                        $FreePct = 0
                    }
                    else
                    {
                        $FreePct = [System.Math]::Round(($_.TotalSize / $_.TotalFreeSpace), $Precision)
                    }
                    New-Object -TypeName psobject -Property @{
                        Drive = $_.Name
                        DriveType = $_.DriveType
                        'Free(%)' = $FreePct
                    }
                }
        }
    }

.Example
    Create dynamic parameters using custom dictionary.

    In case you need more control, use custom dictionary to precisely choose what dynamic parameters to create and when.
    The example below will create DriveType dynamic parameter only if today is not a Friday:

    function Get-FreeSpace
    {
        [CmdletBinding()]
        Param()
        DynamicParam
        {
            $Drive = @{
                Name = 'Drive'
                Type = [array]
                Position = 0
                Mandatory = $true
                ValidateSet = ([System.IO.DriveInfo]::GetDrives()).Name
                ParameterSetName = 'Drive'
            }

            $DriveType =  @{
                Name = 'DriveType'
                Type = [array]
                Position = 0
                Mandatory = $true
                ValidateSet = [System.Enum]::GetNames('System.IO.DriveType')
                ParameterSetName = 'DriveType'
            }

            # Create dictionary
            $DynamicParameters = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

            # Add new dynamic parameter to dictionary
            New-DynamicParameter @Drive -Dictionary $DynamicParameters

            # Add another dynamic parameter to dictionary, only if today is not a Friday
            if((Get-Date).DayOfWeek -ne [DayOfWeek]::Friday)
            {
                New-DynamicParameter @DriveType -Dictionary $DynamicParameters
            }

            # Return dictionary with dynamic parameters
            $DynamicParameters
        }
        Process
        {
            # Dynamic parameters don't have corresponding variables created,
            # you need to call New-DynamicParameter with CreateVariables switch to fix that.
            New-DynamicParameter -CreateVariables -BoundParameters $PSBoundParameters

            if($Drive)
            {
                $Filter = {$Drive -contains $_.Name}
            }
            elseif($DriveType)
            {
                $Filter =  {$DriveType -contains  $_.DriveType}
            }

            $DriveInfo = [System.IO.DriveInfo]::GetDrives() | Where-Object $Filter
            $DriveInfo |
                ForEach-Object {
                    if(!$_.TotalFreeSpace)
                    {
                        $FreePct = 0
                    }
                    else
                    {
                        $FreePct = [System.Math]::Round(($_.TotalSize / $_.TotalFreeSpace), 2)
                    }
                    New-Object -TypeName psobject -Property @{
                        Drive = $_.Name
                        DriveType = $_.DriveType
                        'Free(%)' = $FreePct
                    }
                }
        }
    }
#>
Function New-DynamicParameter {
    [CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = 'DynamicParameter')]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
        [System.Type]$Type = [int],

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
        [string[]]$Alias,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
        [switch]$Mandatory,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
        [int]$Position,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
        [string]$HelpMessage,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
        [switch]$DontShow,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
        [switch]$ValueFromPipeline,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
        [switch]$ValueFromPipelineByPropertyName,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
        [switch]$ValueFromRemainingArguments,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
        [string]$ParameterSetName = '__AllParameterSets',

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
        [switch]$AllowNull,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
        [switch]$AllowEmptyString,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
        [switch]$AllowEmptyCollection,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
        [switch]$ValidateNotNull,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
        [switch]$ValidateNotNullOrEmpty,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
        [ValidateCount(2, 2)]
        [int[]]$ValidateCount,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
        [ValidateCount(2, 2)]
        [int[]]$ValidateRange,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
        [ValidateCount(2, 2)]
        [int[]]$ValidateLength,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
        [ValidateNotNullOrEmpty()]
        [string]$ValidatePattern,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
        [ValidateNotNullOrEmpty()]
        [scriptblock]$ValidateScript,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
        [ValidateNotNullOrEmpty()]
        [string[]]$ValidateSet,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DynamicParameter')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                if (!($_ -is [System.Management.Automation.RuntimeDefinedParameterDictionary])) {
                    Throw 'Dictionary must be a System.Management.Automation.RuntimeDefinedParameterDictionary object'
                }
                $true
            })]
        $Dictionary = $false,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CreateVariables')]
        [switch]$CreateVariables,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CreateVariables')]
        [ValidateScript( {
                # System.Management.Automation.PSBoundParametersDictionary is an internal sealed class,
                # so one can't use PowerShell's '-is' operator to validate type.
                if ($_ -ne $null -and $_.GetType().Name -ne 'PSBoundParametersDictionary') {
                    Throw 'BoundParameters must be a System.Management.Automation.PSBoundParametersDictionary object'
                }
                $true
            })]
        $BoundParameters
    )

    Begin {
        Write-Verbose 'Creating new dynamic parameters dictionary'
        $InternalDictionary = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary

        Write-Verbose 'Getting common parameters'
        function _temp { [CmdletBinding()] Param() }
        $CommonParameters = (Get-Command _temp).Parameters.Keys
    }

    Process {
        if ($CreateVariables) {
            # Allow it to be null for optional parameters
            if ($BoundParameters -ne $null) {
                Write-Verbose 'Creating variables from bound parameters'
                Write-Debug 'Picking out bound parameters that are not in common parameters set'
                $BoundKeys = $BoundParameters.Keys | Where-Object { $CommonParameters -notcontains $_ }
    
                foreach ($Parameter in $BoundKeys) {
                    Write-Debug "Setting existing variable for dynamic parameter '$Parameter' with value '$($BoundParameters.$Parameter)'"
                    # Scope changed from 1 to 2 because it was not visible when imported into scripts.
                    Set-Variable -Name $Parameter -Value $BoundParameters.$Parameter -Scope 2 -Force
                }
            } else {
                Write-Verbose 'Skipping creation because BoundParameters is null'
            }
        } else {
            Write-Verbose 'Looking for cached bound parameters'
            Write-Debug 'More info: https://beatcracker.wordpress.com/2014/12/18/psboundparameters-pipeline-and-the-valuefrompipelinebypropertyname-parameter-attribute'
            $StaleKeys = @()
            $StaleKeys = $PSBoundParameters.GetEnumerator() |
                ForEach-Object {
                if ($_.Value.PSobject.Methods.Name -match '^Equals$') {
                    # If object has Equals, compare bound key and variable using it
                    if (!$_.Value.Equals((Get-Variable -Name $_.Key -ValueOnly -Scope 0))) {
                        $_.Key
                    }
                } else {
                    # If object doesn't has Equals (e.g. $null), fallback to the PowerShell's -ne operator
                    if ($_.Value -ne (Get-Variable -Name $_.Key -ValueOnly -Scope 0)) {
                        $_.Key
                    }
                }
            }
            if ($StaleKeys) {
                "Found $($StaleKeys.Count) cached bound parameters:", $StaleKeys | Write-Debug
                Write-Verbose 'Removing cached bound parameters'
                $StaleKeys | ForEach-Object {[void]$PSBoundParameters.Remove($_)}
            }

            # Since we rely solely on $PSBoundParameters, we don't have access to default values for unbound parameters
            Write-Verbose 'Looking for unbound parameters with default values'

            Write-Debug 'Getting unbound parameters list'
            $UnboundParameters = (Get-Command -Name ($PSCmdlet.MyInvocation.InvocationName)).Parameters.GetEnumerator()  |
                # Find parameters that are belong to the current parameter set
            Where-Object { $_.Value.ParameterSets.Keys -contains $PsCmdlet.ParameterSetName } |
                Select-Object -ExpandProperty Key |
                # Find unbound parameters in the current parameter set
            Where-Object { $PSBoundParameters.Keys -notcontains $_ }

            # Even if parameter is not bound, corresponding variable is created with parameter's default value (if specified)
            Write-Debug 'Trying to get variables with default parameter value and create a new bound parameter''s'
            $tmp = $null
            foreach ($Parameter in $UnboundParameters) {
                $DefaultValue = Get-Variable -Name $Parameter -ValueOnly -Scope 0
                if (!$PSBoundParameters.TryGetValue($Parameter, [ref]$tmp) -and $DefaultValue) {
                    $PSBoundParameters.$Parameter = $DefaultValue
                    Write-Debug "Added new parameter '$Parameter' with value '$DefaultValue'"
                }
            }

            if ($Dictionary) {
                Write-Verbose 'Using external dynamic parameter dictionary'
                $DPDictionary = $Dictionary
            } else {
                Write-Verbose 'Using internal dynamic parameter dictionary'
                $DPDictionary = $InternalDictionary
            }

            Write-Verbose "Creating new dynamic parameter: $Name"

            # Shortcut for getting local variables
            $GetVar = {Get-Variable -Name $_ -ValueOnly -Scope 0}

            # Strings to match attributes and validation arguments
            $AttributeRegex = '^(Mandatory|Position|ParameterSetName|DontShow|ValueFromPipeline|ValueFromPipelineByPropertyName|ValueFromRemainingArguments)$'
            $ValidationRegex = '^(AllowNull|AllowEmptyString|AllowEmptyCollection|ValidateCount|ValidateLength|ValidatePattern|ValidateRange|ValidateScript|ValidateSet|ValidateNotNull|ValidateNotNullOrEmpty)$'
            $AliasRegex = '^Alias$'

            Write-Debug 'Creating new parameter''s attirubutes object'
            $ParameterAttribute = New-Object -TypeName System.Management.Automation.ParameterAttribute

            Write-Debug 'Looping through the bound parameters, setting attirubutes...'
            switch -regex ($PSBoundParameters.Keys) {
                $AttributeRegex {
                    Try {
                        $ParameterAttribute.$_ = . $GetVar
                        Write-Debug "Added new parameter attribute: $_"
                    } Catch {
                        $_
                    }
                    continue
                }
            }

            if ($DPDictionary.Keys -contains $Name) {
                Write-Verbose "Dynamic parameter '$Name' already exist, adding another parameter set to it"
                $DPDictionary.$Name.Attributes.Add($ParameterAttribute)
            } else {
                Write-Verbose "Dynamic parameter '$Name' doesn't exist, creating"

                Write-Debug 'Creating new attribute collection object'
                $AttributeCollection = New-Object -TypeName Collections.ObjectModel.Collection[System.Attribute]

                Write-Debug 'Looping through bound parameters, adding attributes'
                switch -regex ($PSBoundParameters.Keys) {
                    $ValidationRegex {
                        Try {
                            $ParameterOptions = New-Object -TypeName "System.Management.Automation.$_`Attribute" -ArgumentList (. $GetVar) -ErrorAction SilentlyContinue
                            $AttributeCollection.Add($ParameterOptions)
                            Write-Debug "Added attribute: $_"
                        } Catch {
                            $_
                        }
                        continue
                    }

                    $AliasRegex {
                        Try {
                            $ParameterAlias = New-Object -TypeName System.Management.Automation.AliasAttribute -ArgumentList (. $GetVar) -ErrorAction SilentlyContinue
                            $AttributeCollection.Add((. $GetVar))
                            Write-Debug "Added alias: $_"
                            continue
                        } Catch {
                            $_
                        }
                    }
                }

                Write-Debug 'Adding attributes to the attribute collection'
                $AttributeCollection.Add($ParameterAttribute)

                Write-Debug 'Finishing creation of the new dynamic parameter'
                $Parameter = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter -ArgumentList @($Name, $Type, $AttributeCollection)

                Write-Debug 'Adding dynamic parameter to the dynamic parameter dictionary'
                $DPDictionary.Add($Name, $Parameter)
            }
        }
    }

    End {
        if (!$CreateVariables -and !$Dictionary) {
            Write-Verbose 'Writing dynamic parameter dictionary to the pipeline'
            $DPDictionary
        }
    }
}
Function New-DPDictionary {
    <#
        .Synopsis
            Returns a DPDictionary used by DynamicParam
        #>
    Return New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
}
Export-ModuleMember -Function New-DynamicParameter, New-DPDictionary

# ============================================ #

# Test-Image.psm1
# Found this function here: https://blogs.technet.microsoft.com/heyscriptingguy/2015/03/19/psimaging-part-1-test-image/
Function Test-Image {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('PSPath')]
        [string] $Path
    )
    PROCESS {
        $knownHeaders = @{
            jpg  = @( "FF", "D8" );
            jpeg = @( "FF", "D8" );
            bmp  = @( "42", "4D" );
            gif  = @( "47", "49", "46" );
            tif  = @( "49", "49", "2A" );
            png  = @( "89", "50", "4E", "47", "0D", "0A", "1A", "0A" );
            pdf  = @( "25", "50", "44", "46" );
        }
        # coerce relative paths from the pipeline into full paths
        if ($_ -ne $null) {
            $Path = $_.FullName
        }
        # read in the first 8 bits
        $bytes = Get-Content -LiteralPath $Path -Encoding Byte -ReadCount 1 -TotalCount 8 -ErrorAction Ignore
        $retval = $false
        foreach ($key in $knownHeaders.Keys) {
            # make the file header data the same length and format as the known header
            $fileHeader = $bytes |
            Select-Object -First $knownHeaders[$key].Length |
            ForEach-Object { $_.ToString("X2") }
            if ($fileHeader.Length -eq 0) {
                continue
            }
            # compare the two headers
            $diff = Compare-Object -ReferenceObject $knownHeaders[$key] -DifferenceObject $fileHeader
            if (($diff | Measure-Object).Count -eq 0) {
                $retval = $true
            }
        }
        return $retval
    }
}
Export-ModuleMember -Function Test-Image
