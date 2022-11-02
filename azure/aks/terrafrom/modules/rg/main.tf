resource "azurerm_resource_group" "default" {
  name     = "${var.rg-name}-rg"
  location = "${var.location}"

  tags = {
    environment = "${var.environment}"
  }
}