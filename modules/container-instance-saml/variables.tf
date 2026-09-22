variable "name_prefix" {
  description = "The prefix used for all resources in this example."
  type        = string
}

variable "location" {
  description = "The region where these resources should be deployed."
  type        = string
}

variable "tags" {
  description = "A mapping of tags which should be applied to each of the resources."
  type        = map(string)
  default     = {}
}

# The identities assigned an application role. Users are given by user principal
# name and service principals by display name; each is looked up in the directory
# rather than created (see the for_each blocks in 3-entra-permissions.tf). Anyone
# not listed holds no role, and the identity provider refuses them, which is how
# the "access denied" case is reached without naming it explicitly.
variable "write_users" {
  description = "User principal names to assign the Customers.Write application role."
  type        = list(string)
  default     = []
}

variable "read_users" {
  description = "User principal names to assign the Customers.Read application role."
  type        = list(string)
  default     = []
}

variable "write_service_principals" {
  description = "Service principal display names to assign the Customers.Write application role."
  type        = list(string)
  default     = []
}

variable "read_service_principals" {
  description = "Service principal display names to assign the Customers.Read application role."
  type        = list(string)
  default     = []
}

variable "container_image" {
  description = <<-EOT
    The application image the container group runs, pulled from Docker Hub - no
    registry credentials and no import step.

    The default is the published v1.0.0, a multi-arch build carrying both
    linux/amd64 (Azure Container Instances) and linux/arm64 (Apple Silicon), so it
    runs on either. To run unpublished local source instead, build and point this
    at the tag: `docker build -t customer-notes-crm-saml:local .` in the
    application repository, then set container_image = "customer-notes-crm-saml:local".
  EOT
  type        = string
  default     = "docker.io/tombuildsstuff/customer-notes-crm-saml:latest"
}

variable "app_public_url" {
  description = <<-EOT
    The public base URL the application is reached on. The SAML reply URL and the
    application's own entity metadata hang off this.

    Leave it unset on Locally: the default is composed from the container name, the
    container group name, the location and the port, as
    https://<container>-<group>-<location>.gondola.locally:<port>. Gondola registers that
    name in Locally's DNS pointing at the loopback address, where it listens and routes to
    the container by hostname, so that name reaches it.

    On Azure, set it to https://<dns label>.<region>.azurecontainer.io:<port>.

    It is a variable rather than being read from the container group because the
    application registration's reply URL is needed before the container group exists,
    and because the two platforms compose the address differently.
  EOT
  type        = string
  default     = null
}

variable "app_port" {
  description = "The port the application listens on inside the container, which is also the port Locally makes it reachable on."
  type        = number
  default     = 8080
}

variable "tls_certificate" {
  description = <<-EOT
    PEM certificate the application serves HTTPS with, or "" to serve plain HTTP.

    Injected as a value rather than read from a path, so it can come from wherever
    the caller sources it - a file() in the environment, a Key Vault data source
    on Azure, a CI secret.

    HTTPS is optional but it decides one thing: whether sign-in works in Safari.
    Over HTTPS the SAML session cookie is SameSite=None; Secure, which Safari
    keeps across the identity provider's cross-site assertion POST; over plain
    HTTP it is SameSite=Lax, which Chrome and Firefox accept there but Safari does
    not.
  EOT
  type        = string
  default     = ""
}

variable "tls_key" {
  description = "PEM private key for tls_certificate, injected the same way. \"\" (with tls_certificate) serves plain HTTP."
  type        = string
  default     = ""
  sensitive   = true
}

variable "authority_host" {
  description = <<-EOT
    The identity provider's base URL, used to build the SAML federation metadata
    URL the container fetches and the sign-in URL the browser is sent to.

    On Locally this must be the authority's *.locally name (auth.locally), not the
    127.0.0.1 loopback that ARM_ACTIVE_DIRECTORY_AUTHORITY_HOST carries: the
    container fetches the metadata itself, and 127.0.0.1 inside a container is the
    container. auth.locally resolves from both the container (via Locally's
    container DNS) and the host browser, and the Locally certificate covers it.

    Against Azure, set it to https://login.microsoftonline.com.
  EOT
  type        = string
  default     = "https://auth.locally:5677"
}
