#UCreateing VM sing AZ CLI command

#az version
az login --use-device-code
az group create --name GreenStar-RG --location westeurope --tags server-labels=greenstar
#az group update --resource-group GreenStar-RG --set tags.CostCenter='{"Dept":"IT","Environment":"Test"}'

az network public-ip create --sku Basic --name vm1-nozonal-pip --resource-group GreenStar-RG --location westeurope --version IPv4 --tags server-labels=greenstar
#az network public-ip prefix create --length 28 --name vm1-nozonal-pip --resource-group GreenStar-RG --location westeurope --version IPv4

az network vnet create --name gsVNet --resource-group GreenStar-RG --subnet-name gs-subnet 

az network nsg create --location westeurope --name NSG-ubuntu-servers --resource-group GreenStar-RG --tags server-labels=greenstar

az network nsg rule create -g GreenStar-RG --nsg-name NSG-ubuntu-servers -n SSHRule --priority 200 --source-address-prefixes '*' --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges 22 --access Allow  --protocol Tcp --description "Allow SSH port"

#az vm create --resource-group GreenStar-RG --name ubuntu-2204-vm --admin-username azureuser --generate-ssh-keys --image Canonical:0001-com-ubuntu-server-jammy:22_04-lts-ARM:latest 
#--plan-name rabbitmq --plan-product rabbitmq --plan-publisher bitnami
az vm create --resource-group GreenStar-RG `
             --name ubuntu-2204-vm `
             --size "Standard_B1s" `
             --vnet-name "gsVNet" `
             --subnet "gs-subnet" `
             --nsg "NSG-ubuntu-servers" `
             --nsg-rule SSH `
             --image UbuntuLTS `
             --os-disk-delete-option Delete `
             --admin-username azureuser `
             --generate-ssh-keys `
             --public-ip-address "vm1-nozonal-pip"