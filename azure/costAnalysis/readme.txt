#Current PS version:
$PSVersionTable.PSVersion


Get-Module -ListAvailable Az* | Select-Object Name, Version, ModuleBase

#Uninstall
Get-InstalledModule Az* | Uninstall-Module -AllVersions -Force
