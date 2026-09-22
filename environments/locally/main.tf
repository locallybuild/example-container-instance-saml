provider "azuread" {}

provider "azurerm" {
  features {}
}

module "container-instance-saml" {
  source = "../../modules/container-instance-saml"

  name_prefix = "locally-example-saml"
  location    = "berlin"
  tags = {
    ProvisionedVia = "Terraform"
  }

  authority_host = "https://auth.locally:5677" # Locally's authority, using its *.locally name, so that the container can fetch the metadata itself

  # Serve HTTPS with the certificate Locally generates at setup, which covers
  # *.gondola.locally, so sign-in works in every browser including Safari. The
  # path comes from Locally (see the variables above) rather than being hardcoded,
  # so an install that keeps its config elsewhere still resolves it. We read the
  # file here and inject its contents into the module as a value, not a path -
  # against Azure you would inject a real certificate here instead (from a Key
  # Vault data source, say). Clear either path to run over plain HTTP (Chrome and
  # Firefox only).
  tls_certificate = var.locally_tls_certificate_path != "" && fileexists(pathexpand(var.locally_tls_certificate_path)) ? file(pathexpand(var.locally_tls_certificate_path)) : ""
  tls_key         = var.locally_tls_certificate_key_path != "" && fileexists(pathexpand(var.locally_tls_certificate_key_path)) ? file(pathexpand(var.locally_tls_certificate_key_path)) : ""

  write_users = [
    "ada.lovelace@default.tenants.locally",
  ]
  read_users = [
    "grace.hopper@default.tenants.locally",
  ]
  write_service_principals = [
    "Default Identity",
  ]
}
