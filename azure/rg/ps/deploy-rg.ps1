#Run Connect-AzAccount to login

$rgName = "GreenStar-RG"
$rgLocation = "westeurope"
$tags = @{label="GreenStar"}

New-AzResourceGroup -Name $rgName -Location $rgLocation -Tag $tags


