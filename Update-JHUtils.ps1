$modules = Get-ChildItem $PSScriptRoot/Modules/*.psm1
$combinedModules = "$PSScriptRoot/JHUtils.psm1"
Set-Content $combinedModules "# Generated on: $(Get-Date)"
Add-Content $combinedModules "# Description: Helpful PowerShell Modules"
Add-Content $combinedModules "# Author: Jacob Hands <jacob@gogit.io>"
foreach ($m in $modules) {
    $(
        "`n# ============================================ #"
        "`n# $($m.Name)"
        (Get-Content $m.FullName)
    ) | ForEach-Object {Add-Content $combinedModules $_}
}
