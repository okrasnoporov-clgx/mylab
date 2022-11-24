<#PSScriptInfo
.VERSION 0.0.1
.TAGS Azure DevOps Pipelines Folders
#>

<#
.DESCRIPTION
Purpose:
Get ADO pipelines and folders report

authorization:
az login --use-device-code --allow-no-subscriptions
#>

$projects = ((az devops project list | ConvertFrom-Json).value)| Select-Object name | Sort-Object name
foreach ($p in $projects.name) {
    az devops configure --defaults organization=https://dev.azure.com/acn-ctc project=$p
    Write-Host "`nPROJECT: $p`n" 
    $pipelines = (az pipelines list | ConvertFrom-Json) |Select-Object name, path
    $folders = $pipelines.path | Select-Object -Unique | Sort-Object
    foreach ($f in $folders) {
        Write-Host `n`t$f`n`t`t
        
        $pipe = $pipelines | Where-Object path -eq $f |Sort-Object name
        foreach ($pl in $pipe) {
            Write-Host `t`t$($pl.name)
        } 
    }
}