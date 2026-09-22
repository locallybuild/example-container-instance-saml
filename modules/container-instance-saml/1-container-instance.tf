resource "azurerm_resource_group" "example" {
  name     = "${var.name_prefix}-resources"
  location = var.location
  tags     = var.tags
}

locals {
  container_group_name = "${var.name_prefix}-group"
  app_port             = 8080
}

resource "azurerm_container_group" "example" {
  name                = local.container_group_name
  resource_group_name = azurerm_resource_group.example.name
  location            = var.location
  os_type             = "Linux"
  ip_address_type     = "Public"

  # The address is known before the container group exists, which lets the reply
  # URL on the application registration be configured in the same apply. On Locally
  # that address is Gondola's (see local.app_hostname); the DNS name label is what
  # Azure builds its own FQDN from.
  dns_name_label = local.container_group_name
  tags           = var.tags

  container {
    name   = "crm"
    image  = var.container_image
    cpu    = 1.0
    memory = 1.5

    ports {
      port     = 8080
      protocol = "TCP"
    }

    environment_variables = merge({
      SAML_SP_ENTITY_ID = "api://customer-notes-saml"
      SAML_SP_ROOT_URL  = local.app_public_url
      LISTEN_ADDR       = ":${local.app_port}"

      # The identity provider's SAML metadata URL. The container fetches this
      # itself at startup, the same as it would against Azure. On Locally that
      # works because the container resolves the authority's *.locally name
      # (Locally points every container it launches at its DNS) and trusts
      # Locally's certificate authority (mounted into the container), so
      # authority_host must be a .locally name rather than a loopback address -
      # 127.0.0.1 inside the container is the container itself.
      SAML_IDP_METADATA_URL = "${var.authority_host}/${data.azuread_client_config.current.tenant_id}/federationmetadata/2007-06/federationmetadata.xml"

      # Where the application's sign-in page sends the user to begin sign-in.
      # Sign-in is identity-provider-initiated: the app never redirects to the
      # IdP, so an unauthenticated visitor is shown a sign-in page whose button
      # points here, at Locally's SAML launch endpoint for this application. The
      # IdP then POSTs the assertion back to the reply URL registered in
      # 2-entra-application.tf.
      SIGN_IN_URL = local.sign_in_url
      }, local.serve_tls ? {
      # The certificate and key the application serves HTTPS with, base64-encoded
      # as the container reads them from the environment. Present only when a cert
      # was injected; without them the application serves plain HTTP. Serving HTTPS
      # is what makes the session cookie Secure, which Safari needs.
      TLS_CERTIFICATE = base64encode(var.tls_certificate)
      TLS_KEY         = base64encode(var.tls_key)
    } : {})
  }
}
