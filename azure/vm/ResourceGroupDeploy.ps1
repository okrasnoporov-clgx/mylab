#UCreateing VM sing AZ CLI command

#az version
az login --use-device-code
az group create --name GreenStar-RG --location westeurope --tags server-labels=greenstar
#az group update --resource-group GreenStar-RG --set tags.CostCenter='{"Dept":"IT","Environment":"Test"}'

az network public-ip create --sku Basic --name vm1-nozonal-pip --resource-group GreenStar-RG --location westeurope --version IPv4
#az network public-ip prefix create --length 28 --name vm1-nozonal-pip --resource-group GreenStar-RG --location westeurope --version IPv4

az network vnet create --name gsVNet --resource-group GreenStar-RG --subnet-name gs-subnet

az network nsg create --location westeurope --name NSG-ubuntu-servers --resource-group GreenStar-RG

az network nsg rule create -g GreenStar-RG --nsg-name NSG-ubuntu-servers -n SSHRule --priority 200 --source-address-prefixes '*' --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges 22 --access Allow  --protocol Tcp --description "Allow SSH port"

az vm create --resource-group GreenStar-RG --name ubuntu-2204-vm --admin-username azureuser --generate-ssh-keys --image Canonical:0001-com-ubuntu-server-jammy:22_04-lts-ARM:latest 
#--plan-name rabbitmq --plan-product rabbitmq --plan-publisher bitnami