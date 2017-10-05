Function Select-Duplicates {
    <#
    .SYNOPSIS
    Selects items that are duplicated
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        $Items
    )
    Begin {
        $itemsToProcess = @()
    }
    Process {
        foreach($item in $Items){
            $itemsToProcess += $item
        }
    }
    End {
        $itemsToProcess | Group-Object |
            Where-Object -FilterScript {$_.Count -gt 1}
    }
}
Export-ModuleMember -Function Select-Duplicates
