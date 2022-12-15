

$subs = (az account list | ConvertFrom-Json) | Select-Object name, tenantId, isDefault, state, homeTenantId | Where-Object tenantId -eq $ctcId | Where-Object homeTenantId -eq $ctcId
foreach ($s in $subs.name) {
	Write-Host $s
    $asp = (az appservice plan list  --subscription $s |ConvertFrom-Json)
    foreach ($plan in $asp) {Write-Host `t`t$($plan.name) }
}