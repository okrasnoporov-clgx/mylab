$subs = (az account list | ConvertFrom-Json) | Select-Object name, tenantId, isDefault, state, homeTenantId | Where-Object tenantId -eq $ctcId | Where-Object homeTenantId -eq $ctcId
foreach ($s in $subs.name) {
	Write-Host $s
    $vms = (az vm list --subscription $s |ConvertFrom-Json)
    foreach ($vm in $vms) {Write-Host `t`t$($vm.name) `t$($vm.hardwareProfile.vmSize) `t$($vm.storageProfile.osDisk.osType) }
}