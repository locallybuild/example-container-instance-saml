locals {
  # The application role values, which arrive in the assertion's roles claim.
  role_read  = "Customers.Read"
  role_write = "Customers.Write"

  # Fixed ids so an apply is deterministic and the app role assignments below
  # can name a role without depending on the ordering of the app_role blocks.
  role_read_id  = "3a5b1c9e-7d24-4f61-9b0a-2e8c6d4f1a35"
  role_write_id = "9c2f7b41-05de-4a83-8f6d-1b7e3c9a2d64"

  # The identifier the application is known by in SAML. It is set as the
  # application's identifier URI, which populates the service principal's
  # servicePrincipalNames, the field the identity provider matches the
  # SAMLRequest's issuer against to find this enterprise application.
  entity_id = "api://customer-notes-saml"

  # Whether a certificate was injected, so the container serves HTTPS itself. With
  # one, sign-in works in every browser (the SAML session cookie is
  # SameSite=None; Secure); without one the application serves plain HTTP, where
  # the cookie is SameSite=Lax and Safari will not complete the sign-in (Chrome
  # and Firefox will). Leave tls_certificate / tls_key at "" to opt out.
  #
  # nonsensitive: tls_key is a sensitive variable, so this presence check inherits
  # its taint. Whether TLS is on - the scheme in a URL we deliberately print as an
  # output - is not itself secret, so strip the mark. Without this, app_public_url
  # is sensitive and Terraform refuses to show the application_url output.
  serve_tls  = nonsensitive(var.tls_certificate != "" && var.tls_key != "")
  app_scheme = local.serve_tls ? "https" : "http"

  # The address a browser reaches the application on.
  #
  # Gondola publishes a container group at <group>-<location>.gondola.locally (the
  # group's own DNS name - not the container name; see the fqdn on the deployed
  # group). It is composed here rather than read back from
  # azurerm_container_group.example.fqdn because SAML_SP_ROOT_URL is an environment
  # variable on that same group, so reading its fqdn would be a cycle. The reply
  # URL below is composed from the same value so the two always agree. The
  # *.gondola.locally certificate covers this single-label host, so the browser
  # trusts it when TLS is on.
  app_hostname   = "${local.container_group_name}-${var.location}.gondola.locally"
  app_public_url = "${local.app_scheme}://${local.app_hostname}:${local.app_port}"

  # Where the identity provider POSTs the signed assertion back to. Registered as
  # the application's reply URL, which is where an identity-provider-initiated
  # sign-in reads the assertion consumer service URL from (there is no
  # AuthnRequest to carry it).
  acs_url = "${local.app_public_url}/saml/acs"

  # The identity-provider-initiated sign-in URL: Locally's SAML launch endpoint
  # for this application, named by its entity id. The application's sign-in page
  # links its button here (SIGN_IN_URL); the identity provider POSTs the assertion
  # back to acs_url once an identity is picked.
  sign_in_url = "${var.authority_host}/${data.azuread_client_config.current.tenant_id}/saml2/idp?sp=${urlencode(local.entity_id)}"
}
